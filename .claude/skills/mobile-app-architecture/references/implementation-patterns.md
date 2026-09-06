# 구현 패턴

검증된 코드 뼈대를 Android/iOS 짝으로 담았다. 프로젝트에 맞게 조정해서 쓴다.

주석은 "왜 이렇게 하는지"를 적었다. 그대로 옮겨도 좋고, 팀 상황에 맞게 고쳐도 된다.

---

## 목차

1. 화면 상태 모델링
2. Repository + 로컬 우선 읽기
3. 네트워크 계층 + 토큰 갱신 single-flight
4. 재시도 정책
5. 쓰기 큐 (Outbox) + 멱등성
6. 커서 기반 동기화
7. 연결 상태 관리
8. 이벤트 수신 단일 진입점
9. 프레임 단위 배칭
10. 민감 값 보안 버퍼
11. 메모리 구역 (반복 할당 줄이기)

---

## 1. 화면 상태 모델링

정의되지 않은 상태 조합이 만들어지지 않게 한다.

**Android**
```kotlin
// 값을 따로 두면 조합이 8가지가 되고 그중 절반이 정의되지 않은 상태다.
// 봉인된 타입으로 묶으면 표현 가능한 상태가 정상 상태와 같아진다.
sealed interface FeedUiState {
    data object Loading : FeedUiState
    data class Success(val posts: List<Post>) : FeedUiState
    data class Error(val message: String) : FeedUiState   // 실패도 상태의 한 종류
    data object Empty : FeedUiState
}

class FeedViewModel(repo: FeedRepository) : ViewModel() {
    val state: StateFlow<FeedUiState> =
        repo.observeFeed()                                  // 로컬 DB를 관찰한다
            .map<List<Post>, FeedUiState> {
                if (it.isEmpty()) FeedUiState.Empty else FeedUiState.Success(it)
            }
            .catch { emit(FeedUiState.Error(it.message ?: "불러오기 실패")) }
            .stateIn(
                viewModelScope,
                SharingStarted.WhileSubscribed(5_000),      // 구독자가 없으면 5초 뒤 중단
                FeedUiState.Loading                          // 첫 값 도착 전 표시
            )
}
```

**iOS**
```swift
enum FeedUiState {
    case loading
    case success([Post])
    case error(String)
    case empty
}

@MainActor
final class FeedViewModel: ObservableObject {
    // private(set): 읽기는 열고 쓰기는 이 클래스 안으로 제한한다.
    // View가 상태를 직접 못 바꾸는 규칙을 컴파일러가 지켜 준다
    @Published private(set) var state: FeedUiState = .loading
}
```

화면에서는 `when`/`switch`로 모든 경우를 처리한다. 새 상태를 추가하면 처리 누락이 컴파일 오류로 드러난다.

---

## 2. Repository + 로컬 우선 읽기

화면이 서버가 아니라 로컬을 관찰하게 만든다. 네트워크 실패가 화면 실패로 이어지지 않는다.

**Android**
```kotlin
// domain 계층: 안드로이드도 Retrofit도 모른다
interface FeedRepository {
    fun observeFeed(): Flow<List<Post>>     // 로컬 관찰
    suspend fun refresh()                    // 서버에서 갱신
}

// data 계층: 어떻게 가져오는지를 담당한다
class FeedRepositoryImpl(
    private val api: FeedApi,
    private val dao: PostDao
) : FeedRepository {

    // 화면은 항상 로컬을 읽는다 → 네트워크가 없어도 값이 나온다
    override fun observeFeed(): Flow<List<Post>> =
        dao.observeAll().map { entities -> entities.map { it.toPost() } }

    override suspend fun refresh() {
        val response = api.getFeed()
        // 서버 응답을 앱 모델로 변환하는 지점이 여기 하나뿐이다.
        // 서버 필드명이 바뀌어도 고칠 곳이 이 한 줄이다
        dao.upsertAll(response.items.map { it.toEntity() })
        // DB가 바뀌면 observeFeed 구독자가 자동으로 갱신된다
    }
}
```

**iOS**
```swift
protocol FeedRepository {
    func observeFeed() -> AnyPublisher<[Post], Never>
    func refresh() async throws
}

final class FeedRepositoryImpl: FeedRepository {
    func observeFeed() -> AnyPublisher<[Post], Never> {
        store.publisher()                          // 로컬 저장소 변경 스트림
            .map { $0.map(Post.init(entity:)) }    // 저장소 모델 → 앱 모델
            .eraseToAnyPublisher()
    }
}
```

---

## 3. 네트워크 계층 + 토큰 갱신 single-flight

병렬 요청이 동시에 401을 받아도 갱신은 한 번만 일어나게 한다.

**Android**
```kotlin
class TokenStore(private val api: AuthApi, private val storage: SecureStorage) {

    private val mutex = Mutex()                        // 동시에 하나만 통과
    private var refreshJob: Deferred<String?>? = null  // 진행 중인 갱신

    suspend fun refreshOnce(): String? {
        // 확인과 시작을 한 덩어리로 처리한다.
        // 두 요청이 동시에 "갱신 중 아니네"라고 판단하는 상황을 막는다
        val job = mutex.withLock {
            val running = refreshJob
            if (running != null && running.isActive) {
                running                                 // 이미 진행 중 → 그 결과를 공유
            } else {
                CoroutineScope(Dispatchers.IO).async {
                    val result = runCatching { api.refresh(storage.refreshToken()) }.getOrNull()
                    result?.also { storage.save(it.accessToken, it.refreshToken) }?.accessToken
                }.also { refreshJob = it }
            }
        }
        return job.await()   // 시작한 쪽도 기다리는 쪽도 같은 결과를 받는다
    }
}

class AuthInterceptor(private val tokenStore: TokenStore) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()

        // 갱신 요청 자체에는 인증 처리를 적용하지 않는다.
        // 이게 없으면 리프레시 토큰 만료 시 갱신이 무한 반복된다
        if (request.url.encodedPath.endsWith("/auth/refresh")) {
            return chain.proceed(request)
        }

        val token = runBlocking { tokenStore.currentAccessToken() }
        return chain.proceed(
            request.newBuilder().header("Authorization", "Bearer $token").build()
        )
    }
}
```

**iOS**
```swift
// actor는 내부 상태에 한 번에 하나의 작업만 접근하게 보장한다.
// Android의 Mutex 역할을 언어가 대신해 준다
actor TokenProvider {
    private var refreshTask: Task<String, Error>?

    func refreshOnce() async throws -> String {
        if let task = refreshTask { return try await task.value }

        let task = Task<String, Error> {
            let result = try await api.refresh(refreshToken: storage.refreshToken())
            try storage.save(access: result.accessToken, refresh: result.refreshToken)
            return result.accessToken
        }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }
}
```

**함께 넣을 것:** 공통 헤더 인터셉터에 앱 버전을 싣는다. 나중에 필드 제거 시점을 판단할 유일한 근거가 된다.

---

## 4. 재시도 정책

요청 종류별로 정책을 나눈다. 기본값은 재시도 없음이다.

**Android**
```kotlin
data class RetryPolicy(
    val maxAttempts: Int,
    val baseDelayMs: Long,
    val maxDelayMs: Long,
    val totalBudgetMs: Long
) {
    companion object {
        // 사용자가 화면에서 기다리는 요청: 빨리 포기하고 다시 시도 버튼을 준다
        val Interactive = RetryPolicy(2, 500, 1_000, 5_000)
        // 백그라운드: 사용자가 보고 있지 않으므로 끈질기게
        val Background = RetryPolicy(6, 1_000, 60_000, 600_000)
        // 멱등성 키 없는 변경 요청의 기본값
        val None = RetryPolicy(1, 0, 0, 10_000)
    }
}

private fun computeDelay(policy: RetryPolicy, attempt: Int): Long {
    val exponential = policy.baseDelayMs * (1L shl (attempt - 1))
    val capped = minOf(exponential, policy.maxDelayMs)
    // 계산값의 50~100% 범위에서 무작위로 정한다.
    // 여러 기기의 재시도 시점이 겹치면 서버가 복구되지 못한다
    return (capped * (0.5 + Random.nextDouble() * 0.5)).toLong()
}

private fun isRetryable(code: Int) = when (code) {
    408, 429 -> true
    in 500..599 -> true
    else -> false      // 4xx는 다시 보내도 결과가 같다
}
```

**재시도 예산** — 평상시에는 걸리지 않고 장애 때만 발동한다.
```kotlin
class RetryBudget(private val ratio: Double = 0.1) {
    private var total = 0
    private var retried = 0

    @Synchronized fun tryConsume(): Boolean {
        if (retried >= total * ratio) return false   // 상한 초과 → 재시도 포기
        retried++
        return true
    }
}
```

---

## 5. 쓰기 큐 (Outbox) + 멱등성

사용자 입력이 사라지지 않게 하고, 재시도해도 중복이 생기지 않게 한다.

**Android**
```kotlin
@Entity(tableName = "outbox")
data class OutboxEntry(
    // 이 값이 멱등성 키이자 로컬 식별자다. 만들 때 한 번 정하고 절대 바꾸지 않는다.
    // 재시도할 때 새로 만들면 서버가 중복을 걸러낼 수 없다
    @PrimaryKey val id: String,
    val type: String,
    val payload: String,
    val status: String,        // PENDING / IN_FLIGHT / FAILED
    val retryCount: Int,
    val nextAttemptAt: Long,   // 이 시각 전에는 꺼내지 않는다
    val createdAt: Long
)

@Dao
interface MessageDao {
    // 데이터 저장과 전송 기록을 하나로 묶는다.
    // 따로 하면 중간에 앱이 죽었을 때 "화면에는 있는데 영영 안 보내지는" 항목이 생긴다
    @Transaction
    suspend fun sendAtomically(message: MessageEntity, outbox: OutboxEntry) {
        insertMessage(message)
        insertOutbox(outbox)
    }
}
```

```kotlin
class OutboxWorker(/* ... */) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val items = dao.findReady(System.currentTimeMillis())

        for (item in items) {
            // 다른 작업이 같은 항목을 꺼내 가지 않게 표시한다
            dao.updateStatus(item.id, "IN_FLIGHT")

            try {
                // 멱등성 키를 헤더에 넣는다. 재시도해도 이 값은 바뀌지 않으므로
                // 서버가 같은 키를 두 번 받으면 처음 결과를 그대로 돌려준다
                val response = api.execute(item.type, item.payload, idempotencyKey = item.id)
                dao.markSynced(item.id, response.id)
                dao.deleteOutbox(item.id)

            } catch (e: IOException) {
                scheduleRetry(item)
                return Result.retry()   // 네트워크 문제면 남은 항목도 어차피 실패한다
            } catch (e: HttpException) {
                when (e.code()) {
                    429, in 500..599 -> { scheduleRetry(item); return Result.retry() }
                    else -> dao.updateStatus(item.id, "FAILED")   // 4xx는 재시도 무의미
                }
            }
        }
        return Result.success()
    }
}

// 앱 시작 시 호출: 전송 중인 채로 멈춘 항목을 되살린다.
// 멱등성 키가 있으므로 이미 서버에 도달했더라도 중복이 생기지 않는다
suspend fun recoverStuckItems() {
    dao.resetInFlightOlderThan(System.currentTimeMillis() - 5 * 60 * 1000)
}
```

**화면 표시** — 대기·완료·실패 3상태를 보여주고 실패에는 다시 시도 수단을 준다. 즉시 보여주되 정직하게 표시하는 것이 핵심이다.

---

## 6. 커서 기반 동기화

끊긴 동안 놓친 것을 따라잡는다.

**Android**
```kotlin
@Entity(tableName = "sync_cursor")
data class SyncCursor(
    @PrimaryKey val conversationId: String,
    // "받은" 순번이 아니라 "저장을 마친" 순번이다. 이름에 의미를 담아 실수를 줄인다
    val lastAppliedSeq: Long,
    val updatedAt: Long
)

@Dao
interface SyncDao {
    // 저장과 커서 갱신을 하나로 묶는다.
    // 커서를 먼저 올리고 저장하다 앱이 죽으면 그 구간이 영영 유실되고,
    // 반대 순서면 최악의 경우 중복을 받을 뿐이라 중복 제거가 걸러 준다
    @Transaction
    suspend fun applyBatch(messages: List<MessageEntity>, cursor: SyncCursor) {
        insertAllIfNew(messages)
        upsertCursor(cursor)
    }
}
```

```kotlin
suspend fun sync() {
    // 대화방마다 따로 요청하면 왕복이 대화방 수만큼 늘어난다.
    // 커서를 묶어 보내는 비용은 항목당 30바이트 정도로 훨씬 싸다
    val cursors = dao.allCursors()
        .sortedByDescending { it.updatedAt }
        .take(100)                                  // 활성 대화방만
        .associate { it.conversationId to it.lastAppliedSeq }

    var request = SyncRequest(cursors, limit = 200)

    while (true) {
        val response = api.sync(request)

        response.messagesByConversation.forEach { (cid, messages) ->
            if (messages.isEmpty()) return@forEach
            dao.applyBatch(
                messages.map { it.toEntity() },
                SyncCursor(cid, messages.maxOf { it.seq }, System.currentTimeMillis())
            )
        }

        if (!response.hasMore) break

        // 서버가 준 다음 커서를 그대로 쓰지 않고 DB에서 다시 읽는다.
        // 저장에 실패한 대화방이 있으면 그 방은 이전 지점부터 다시 받아야 한다
        request = request.copy(cursors = dao.allCursors()
            .associate { it.conversationId to it.lastAppliedSeq })
    }
}
```

**트리거 세 곳:** 연결 복구 직후, 앱이 화면으로 복귀, 순번 건너뜀 감지. **전부 같은 함수를 부르고, 중복 실행을 막는다.**

---

## 7. 연결 상태 관리

**Android**
```kotlin
sealed interface ConnectionState {
    data object Disconnected : ConnectionState
    data object Connecting : ConnectionState
    data object Connected : ConnectionState
    data class Reconnecting(val attempt: Int) : ConnectionState
}

class RealtimeConnection(/* ... */) {
    // 앱 전체가 이 하나를 구독한다.
    // 화면 상단 표시, 전송 버튼 동작, 재연결 로직이 같은 값을 본다
    private val _state = MutableStateFlow<ConnectionState>(ConnectionState.Disconnected)
    val state: StateFlow<ConnectionState> = _state

    private fun heartbeatInterval(): Long =
        // 와이파이는 라디오 tail time 문제가 없어 짧게 잡아 감지를 앞당긴다.
        // 셀룰러는 배터리를 위해 넉넉히 (하한 20초, 상한 60초 사이)
        if (isOnWifi()) 20_000L else 45_000L

    private fun onMessageReceived() {
        // 어떤 메시지든 받았다면 연결이 살아 있다는 증거다.
        // 응답 시한을 취소해 불필요한 ping을 줄인다
        pongDeadlineJob?.cancel()
    }

    private fun handleDisconnect() {
        attempt++
        _state.value = ConnectionState.Reconnecting(attempt)
        scope.launch {
            val base = minOf(1000L * (1L shl minOf(attempt, 6)), 60_000L)
            delay((base * (0.5 + Random.nextDouble() * 0.5)).toLong())
            connect()
        }
    }
}
```

**대량 절단 대비** — 서버 재배포 등으로 모두가 같은 순간에 끊기면 첫 시도부터 흩뜨려야 한다.
```kotlin
private fun scheduleFirstReconnect() {
    scope.launch {
        delay(Random.nextLong(0, 5_000))   // 0~5초 무작위
        connect()
    }
}
```

**iOS 주의:** `URLSessionWebSocketTask.receive`는 한 번에 메시지 하나만 받는다. 받은 뒤 다시 호출하지 않으면 첫 메시지만 오고 조용히 멈춘다.

```swift
private func receiveLoop() {
    task?.receive { [weak self] result in
        switch result {
        case .success(let message):
            self?.handle(message)
            self?.receiveLoop()      // 이 재귀 호출을 빠뜨리면 수신이 멈춘다
        case .failure:
            self?.handleDisconnect()
        }
    }
}
```

**앱 복귀 시** 기존 연결을 신뢰하지 않는다.
```swift
.onChange(of: scenePhase) { _, phase in
    switch phase {
    case .active:   connection.verifyAlive(timeout: 3)   // 짧은 시한으로 재확인
    case .background: connection.disconnect()             // 상태를 정확히 유지
    default: break
    }
}
```

---

## 8. 이벤트 수신 단일 진입점

WebSocket·푸시 후 fetch·재연결 동기화가 모두 같은 곳을 통과하게 한다.

```kotlin
class MessageIngestor(private val dao: MessageDao, private val gapResolver: GapResolver) {

    suspend fun ingest(incoming: MessageEntity) {
        // 중복 판정을 DB 기본키에 맡긴다.
        // 별도 집합을 쓰면 앱 재시작 시 사라지는데, 재시작 직후가 중복이 가장 많은 시점이다
        val rowId = dao.insertIfNew(incoming)
        if (rowId == -1L) return          // 이미 있는 메시지. 화면 갱신도 일어나지 않는다

        // 순번이 건너뛰었으면 빠진 구간을 서버에 요청한다
        val lastSeq = dao.lastSeq(incoming.conversationId) ?: 0
        if (incoming.seq > lastSeq + 1) {
            gapResolver.requestRange(incoming.conversationId, lastSeq + 1, incoming.seq - 1)
        }
        // 화면 갱신 코드가 없다. DB를 관찰 중인 스트림이 알아서 방출한다
    }
}
```

**DAO 쪽**
```kotlin
@Insert(onConflict = OnConflictStrategy.IGNORE)
suspend fun insertIfNew(message: MessageEntity): Long   // 중복이면 -1 반환

// 화면은 도착 순서가 아니라 순번 순서로 읽는다
@Query("SELECT * FROM message WHERE conversationId = :cid ORDER BY seq ASC")
fun observeMessages(cid: String): Flow<List<MessageEntity>>
```

---

## 9. 프레임 단위 배칭

들어오는 이벤트가 처리 속도보다 빠를 때.

**Android**
```kotlin
socket.quotes
    // 수신과 처리를 분리한다. 없으면 처리가 끝날 때까지 수신이 멈춘다
    .buffer(capacity = 256, onBufferOverflow = BufferOverflow.DROP_OLDEST)
    //                       ↑ 시세는 최신 값이 중요하므로 오래된 것을 버린다
    .chunkedByTime(16)                    // 프레임 주기만큼 모은다
    .filter { it.isNotEmpty() }
    .collect { batch ->
        // 같은 대상이 여러 번 왔으면 최신 것만 남긴다
        val latest = batch.associateBy { it.symbol }.values.toList()
        dao.upsertAll(latest.map { it.toEntity() })   // 트랜잭션 1회, 화면 갱신 1회
    }
```

**메시지처럼 버리면 안 되는 데이터는 설정이 다르다.**
```kotlin
socket.messages
    .buffer(capacity = 1024, onBufferOverflow = BufferOverflow.SUSPEND)  // 대기, 유실 없음
    .chunkedByTime(16)
    .collect { batch ->
        dao.insertAllIfNew(batch.map { it.toEntity() })   // 합치지 않고 전부 저장
    }
```

**iOS** — `CADisplayLink`를 쓰면 기기의 실제 주사율에 맞춰진다. 16ms를 하드코딩하면 120Hz 기기에서 절반을 낭비한다.

---

## 10. 민감 값 보안 버퍼

**iOS**
```swift
final class SecureBuffer {
    private let base: UnsafeMutableRawPointer
    private let capacity: Int         // 용량 고정. 늘리면 버려지는 버퍼가 생긴다
    private var isWiped = false

    init(capacity: Int) {
        self.capacity = capacity
        self.base = .allocate(byteCount: capacity, alignment: 1)
        memset(base, 0, capacity)     // 이전에 이 자리에 있던 값이 남아 있을 수 있다
    }

    // 값을 반환하지 않고 클로저 안에서만 접근하게 한다.
    // 반환하면 그 순간 Swift가 관리하는 사본이 생겨 통제를 벗어난다
    func withBytes<T>(_ body: (UnsafeRawBufferPointer) throws -> T) rethrows -> T {
        precondition(!isWiped)
        return try body(UnsafeRawBufferPointer(start: base, count: capacity))
    }

    func wipe() {
        guard !isWiped else { return }
        // 일반 memset은 "이후 아무도 읽지 않으므로 무의미"로 판단되어
        // 컴파일러가 제거할 수 있다. memset_s는 최적화 대상에서 제외된다
        _ = memset_s(base, capacity, 0, capacity)
        isWiped = true
    }

    deinit {
        #if DEBUG
        // 화면을 나갔는데 이 로그가 안 찍히면 참조가 남아 있다는 뜻이다
        print("SecureBuffer 해제 — \(capacity) bytes")
        #endif
        if !isWiped { _ = memset_s(base, capacity, 0, capacity) }
        base.deallocate()             // 지운 다음에 반환한다. 순서가 중요하다
    }
}

// 로그로 새지 않게 한다
extension SecureBuffer: CustomStringConvertible {
    var description: String { "SecureBuffer(\(capacity) bytes)" }
}
```

**Android** — 확정적 해제 시점이 없으므로 `use` 블록이 주 경로다.
```kotlin
class SecureBuffer(capacity: Int) : AutoCloseable {
    // 힙 밖에 할당한다. GC가 옮기지 않으므로 지운 자리가 확실하다
    private val buffer = ByteBuffer.allocateDirect(capacity)

    override fun close() {
        buffer.clear()
        repeat(buffer.capacity()) { buffer.put(0) }
    }
}

// 사용: 블록을 벗어나면 자동 정리
SecureBuffer(19).use { secure -> /* ... */ }
```

**입력 경로:** 숫자 입력이면 커스텀 키패드로 문자열을 아예 만들지 않는 방법이 있다. `text.toString()`이 통제 밖 사본을 만드는 지점이다.

---

## 11. 메모리 구역 (반복 할당 줄이기)

한 프레임에 수백 개씩 생기는 임시 객체를 하나씩 관리하지 않는다.

**Android**
```kotlin
class MemoryRegion(totalBytes: Int, private val wipeOnReset: Boolean = false) : AutoCloseable {

    private val block = ByteBuffer.allocateDirect(totalBytes)
    private var nextOffset = 0

    // 개별 해제 함수를 일부러 만들지 않았다.
    // 만들면 누군가 쓰게 되고, 그러면 하나씩 관리가 다시 시작된다
    fun take(size: Int): ByteBuffer {
        require(nextOffset + size <= block.capacity())
        val slice = block.duplicate().position(nextOffset).limit(nextOffset + size).slice()
        nextOffset += size          // 위치를 미는 것이 할당의 전부
        return slice
    }

    fun reset() {
        if (wipeOnReset) {
            // 민감한 값이 있었다면 0으로 덮는다.
            // 하나씩 추적하지 않아도 안에 있던 모든 값이 함께 정리된다
            block.clear()
            repeat(nextOffset) { block.put(0) }
        }
        nextOffset = 0
    }

    override fun close() = reset()
}
```

**화면 수명에 붙인다.**
```kotlin
class PaymentViewModel : ViewModel() {
    private val region = MemoryRegion(64 * 1024, wipeOnReset = true)

    override fun onCleared() {
        // 화면을 벗어나면 시스템이 반드시 호출한다. 정리를 잊을 수 없는 지점이다
        region.reset()
        super.onCleared()
    }
}
```

**버퍼 재사용 시 정리를 함께** — 성능과 보안을 같은 지점에서 해결한다.
```kotlin
fun <T> borrow(block: (ByteArray) -> T): T {
    val buffer = pool.removeFirstOrNull() ?: ByteArray(size)
    try { return block(buffer) }
    finally {
        buffer.fill(0)          // 다음 사용자가 이전 데이터를 보지 않는다
        pool.addLast(buffer)    // 새로 할당하지 않아 GC 압박이 줄어든다
    }
}
```
