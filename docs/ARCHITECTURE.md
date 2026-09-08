# ARCHITECTURE.md

## 레이어 구조와 의존 방향

```
App
 └── Feature  ──→  Domain (Interface)
      └── ...  ──→  DesignSystem
 └── Domain (Implements)
 └── Data  ──→  Domain (Interface)
      └────→  Core
      └────→  NetworkingInterface  ←──  Networking
```

**허용되는 방향만 허용된다. 역방향은 없다.**

| 레이어 | 역할 | 참조 가능한 레이어 |
|---|---|---|
| `App` | 진입점. 의존성 주입 조립 | Feature, Domain, Data, DesignSystem |
| `Feature` | 화면과 UI 로직 | DomainInterface, DesignSystem |
| `Domain` | Repository/UseCase 선언 + UseCase의 liveValue(오케스트레이션) | 없음 |
| `Data` | Repository의 liveValue(실제 API/시스템 호출 구현) | DomainInterface, Core, NetworkingInterface |
| `Networking` | HTTP 클라이언트 실제 구현(`HTTPClient`), 인증 인터셉터(`TokenRefreshInterceptor`) | NetworkingInterface |
| `NetworkingInterface` | HTTP 클라이언트 포트(`HTTPClienting`, `Requestable`, `TokenProvider` 등) | 없음 |
| `Core` | Keychain 등 인프라 유틸리티 | 없음 |
| `DesignSystem` | 컬러/폰트 등 디자인 토큰 | 없음 |

네트워크 코드는 `Networking`(구현체)/`NetworkingInterface`(포트) 2-target으로 분리되어 있다(`Core`에는 더 이상 네트워크 코드가 없다 — Keychain만 남는다). `Data`는 실제 API/시스템 호출을 전담하지만 **`NetworkingInterface`만 참조하고 구현체인 `Networking`에는 의존하지 않는다** — `Data`는 오직 `@Dependency(\.authenticatedHTTPClient)`/`@Dependency(\.httpClient)`(둘 다 `NetworkingInterface`의 DependencyValue)로만 네트워크를 호출한다. 인증된 클라이언트(`TokenRefreshInterceptor` 적용)를 실제로 만드는 코드는 `Networking`(구현체) 안에 있다 — `Networking`은 인증 토큰을 직접 알지 못하고, `NetworkingInterface`에 선언된 저수준 포트 `TokenProvider`(`getAccessToken`/`refreshAccessToken`)에만 의존한다. 이 `TokenProvider`의 실제 구현(→ `DomainInterface`의 `authSessionRepository` 브릿지)은 `Data`가 제공한다 — 즉 인증 방향은 `Networking → NetworkingInterface ← Data`로, `Networking`이 `Data`/`Domain`을 몰라도 되는 구조를 유지한다. `Domain`은 `Core`/`Networking`/`NetworkingInterface` 어느 것에도 의존하지 않는다 — Repository/UseCase 선언과 UseCase의 오케스트레이션 로직만 있다.

`Shared`는 DesignSystem 하나만 감싸는 빈 aggregator였기 때문에 제거됐다 — `DesignSystem`은 `Projects/DesignSystem`으로 독립된 최상위 모듈이다.

### Repository / UseCase 패턴

FiveVoca의 모든 외부 의존성(Supabase 네트워크 호출, Keychain, AVFoundation 등)은 Repository/UseCase 패턴을 따른다. 과거 사용하던 `Client` struct(Repository+UseCase가 하나로 합쳐진 형태)는 전부 이 패턴으로 전환 완료됐고, `Domain/Interface/Client`·`Domain/Sources/Client` 디렉터리는 더 이상 존재하지 않는다.

- **Repository**: 외부 API/시스템을 추상화한 포트. `Domain/Interface/Repository/`(`DomainInterface` 타겟)에 struct-of-closures로 선언한다. `testValue`(`unimplemented`)만 가지며 `previewValue`는 없다 — Repository는 ViewModel이 직접 보지 않기 때문이다.
- **UseCase**: 화면(ViewModel)이 실제로 호출하는 단위. `Domain/Interface/UseCase/`(`DomainInterface` 타겟)에 struct-of-closures로 선언하며 `testValue`/`previewValue`를 모두 갖는다. **ViewModel은 Repository가 아닌 UseCase만 `@Dependency`로 주입받는다.**
- **UseCase의 `liveValue`**는 `Domain/Sources/UseCase/`(`Domain` 타겟)에 위치하며, `@Dependency`로 Repository를 주입받아 호출한다(순수 오케스트레이션 — 여러 Repository를 조합하거나 결과를 가공할 수 있다. 예: `SignInWithAppleUseCase`는 `authRepository.signInWithApple`을 호출한 뒤 `authSessionRepository`에 토큰을 저장한다).
- **Repository의 `liveValue`**는 `Data/Sources/<도메인별 폴더>/`에 위치하며, 실제 Supabase 호출(`@Dependency(\.authenticatedHTTPClient)` + `Requestable` 준수 Request struct)이나 Keychain/AVFoundation 같은 시스템 API를 직접 다룬다. 캐싱(예: `AudioDiskCache`, `AudioMemoryCache`)도 Repository의 liveValue 책임이다. 단어/레슨 콘텐츠는
로컬 DB(`Projects/Data/Sources/LocalDatabase`) 도입 이후 별도 캐시 계층 없이 DB가 그 역할을 겸한다. 인증이 필요 없거나 재귀(토큰 갱신 자기 호출)를 피해야 하는 소수의 요청(`RefreshTokenRequest`, `DeleteAccountRequest`)만 예외적으로 `NetworkingInterface`의 `httpClient`(NoopInterceptor) 의존성을 그대로 사용한다.
- DataSource 레이어는 아직 없다 — Repository가 직접 API를 호출하며, 필요해지면 Repository와 실제 호출 사이에 DataSource를 끼워 넣는다.
- `AudioPlayerRepository`처럼 "외부 API"가 아니라 로컬 시스템 프레임워크(AVFoundation)를 감싸는 경우도 있다 — Repository라는 이름이 정확히 들어맞지는 않지만, UseCase 테스트 용이성이라는 동일한 목적으로 같은 패턴을 적용한다.

---

## Feature 모듈 타겟 구성

Feature 모듈 하나는 기본 3개 타겟으로 구성된다.

| 타겟 | 네이밍 예시 | 역할 |
|---|---|---|
| Implements | `FeatureHome` | 실제 View, ViewModel 구현 |
| Tests | `FeatureHomeTests` | 단위 테스트. 외부에 노출 안 됨 |
| Example | `FeatureHomeExample` | 독립 실행 앱. Xcode Preview 대신 실제 기기로 격리 확인 |

> Interface 타겟은 모듈 간 컴파일 의존성을 끊어야 할 시점에 재도입한다. 현재는 Feature 간 의존
> 그래프가 비순환이라 재도입 조건이 성립하지 않는다 — 라우트 그래프에 역방향 엣지가 필요해지는
> 순간(예: 하위 화면이 상위 화면으로 다시 진입해야 할 때)이 재검토 트리거다.

---

## Feature 모듈 경계 규칙

Feature 모듈을 나누거나 이름 붙일 때 따르는 규칙이다. 리팩토링(#107)을 계기로 명문화됐다.

1. **Feature 모듈 이름은 그 모듈이 소유한 라우트(화면) 묶음의 이름이지, Domain 엔티티 이름이
   아니다.** 대응하는 Domain 타입이 없어도 정상이다(`FeatureWordGame`, `FeatureChunkReader`처럼
   화면 전용 개념일 수 있다).
2. 라우트가 1개면 **모듈명 = 라우트명**(`FeatureChunkReader`, `FeatureChatBot`, `FeatureLogin`,
   `FeatureMyPage`).
3. 라우트가 여러 개면 그 라우트들이 공통으로 다루는 **화면 계층 단위**를 이름으로 쓴다
   (`FeatureLesson` = 레슨을 고르고 여는 화면들, `FeatureWord` = 단어를 보는 화면들).
4. **한 라우트는 정확히 한 모듈에 속하고, 그 라우트 전용 부속 View/Model은 같은 폴더 안에 둔다**
   (화면 내부 폴더링 세부 규칙은 `feature-foldering` 스킬 참고).
5. **같은 이름을 서로 다른 뜻으로 코드베이스 안에서 함께 쓰지 않는다.** 예: `Vocabulary`라는
   이름이 Feature 모듈(단어 화면)과 Domain 타입(레벨/레슨 진행률)에서 서로 다른 것을 가리키던
   것이 이번 리팩토링의 근본 원인이었다.

### 용어 사전 (Ubiquitous Language)

| 용어 | 뜻 | 유일한 쓰임 |
|---|---|---|
| `Level` | CEFR 기반 레벨. 레슨을 담는다 | `LevelSummary`, `LevelEntity` |
| `Lesson` | 약 20단어 묶음의 학습 단위 | `Lesson`, `LessonProgress`, `LessonEntity` |
| `Word` | 단어. 문맥에 따라 두 타입만 존재한다 | `Lesson.Word`(게임 재료, distractors 포함) / `WordDetail`(사전 항목) — 이 둘 외 새 "Word" 타입을 추가하지 않는다 |
| `LearningLibrary` | 레벨/레슨 전체 진행률 대시보드 | `LearningLibrary`, `LearningLibraryRepository` |
| `LearningHistory` | 레슨별 학습 완료 이력 | `LearningHistory`, `LearningHistoryRepository` |
| `Session` | **로그인 세션만.** 학습 단위(레슨)에는 쓰지 않는다 | `AuthSessionRepository` 계열 |
| ~~`Vocabulary`~~ | **금지어.** 어느 레이어에서도 새로 쓰지 않는다 | — |

### 승격 트리거 (미리 정해두는 재검토 조건)

- **Markdown 렌더러**(`Feature/ChatBot/Sources/Markdown/`)는 소비처가 1개(챗봇 말풍선)인 동안은
  ChatBot 모듈 안에 둔다. 두 번째 소비처가 생기는 시점에 `FeatureMarkdown`으로 승격한다.
- **Interface 타겟 / Feature 간 DI 추상화**는 위에서 언급한 대로, 라우트 그래프에 역방향 엣지가
  필요해지는 시점에 재도입한다.

---

## 데이터 모델: DTO → Domain Model

데이터는 한 방향으로만 변환된다.

```
Entity (DTO)  ──→  Domain Model
   (Data)        (DomainInterface)
```

**Entity (DTO)**
- Supabase 응답을 그대로 매핑하는 `Decodable` struct
- `Data` 타겟 내부(`Data/Sources/<도메인별 폴더>`)에만 존재. `Domain`/`Feature`에 절대 노출되지 않는다 — Repository의 liveValue가 반환하기 전에 `.toDomain()`으로 변환한다

**Domain Model**
- 앱의 진짜 데이터 모델. UI와 무관하게 정의된다
- `DomainInterface` 타겟에 위치. `Feature`와 `Data` 양쪽이 참조한다(`Domain`은 Repository/UseCase 시그니처를 통해 다룰 뿐 DTO를 모른다)
- 날짜는 `Date`, 수치는 `Double` — 포맷 없는 순수 값

### 변환 규칙

변환 함수는 **변환 대상 타입의 extension**으로 작성한다. 별도 Mapper 클래스를 만들지 않는다.

```swift
// Entity → Domain: Data 타겟 내부 (Repository의 liveValue가 호출)
extension WordEntity {
    func toLessonWord(meanings: [WordMeaningEntity]) -> Lesson.Word { ... }
}
```

### Feature는 Domain Model을 직접 다룬다

과거에는 Domain Model을 표시용 PresentationModel(구 ViewState)로 한 번 더 변환하는 계층이 있었다.
이 계층은 제거됐다 — ViewModel은 UseCase가 반환한 Domain Model을 그대로 상태로 보유하고, View는
Domain Model을 직접 렌더링한다.

```swift
@Observable
final class WordDetailViewModel {
    enum ViewState {
        case loading
        case loaded(WordDetail)   // Domain Model을 그대로 보유. 별도 PresentationModel 없음
        case error(String)
    }
}
```

**화면에 필요한 파생값(그룹핑, 상태 판정, 라벨 변환)은 Domain Model의 extension으로 표현한다.**
새 struct 계층을 만드는 대신, Domain 타입에 계산 프로퍼티/함수를 추가하되 **extension은 Feature
모듈 안에 둔다** — Domain 타입 자체(`DomainInterface`)는 UI 관심사를 모른다.

```swift
// Feature/Word/Sources/WordDetail/WordDetail+DefinitionGrouping.swift
extension WordDetail {
    struct DefinitionGroup: Equatable, Identifiable { ... }  // 그룹핑 산물만 별도 타입
    func groupedDefinitions() -> [DefinitionGroup] { ... }
}

// Feature/Lesson/Sources/LearningLibrary/Model/LevelSummary+Status.swift
extension LevelSummary {
    var status: LevelStatus { ... }  // 임곗값 판단 결과는 enum으로 표현
}
```

**판단 결과는 enum으로 표현한다.** `completedLessons == totalLessons` 같은 임곗값 판단은 이
extension 안에서 처리하되, 판단 결과는 `LevelStatus`/`LessonCellStatus` 같은 enum으로 반환한다.
View는 분기하지 않고 값을 그대로 쓴다. 색상/아이콘 등 DesignSystem 매핑은 이 enum을 받는 View
extension에서 담당한다(예: `LevelStatus.badgeInfo`) — 파생 로직에도 DesignSystem 의존을 넣지 않는다.

같은 Domain 타입을 여러 Feature 모듈이 각자 가공해야 할 때(예: `Lesson.Word`가 Lesson/Word/
WordGame 세 화면에서 쓰일 때), 모듈 의존 방향이 순환되지 않는 한 공유 확장을 새로 만들지 않고
각 모듈에 필요한 만큼만 개별적으로(짧은 중복을 감수하고) 확장한다. 파생 프로퍼티가 한두 줄
수준이면 이 중복이 잘못된 방향의 모듈 의존(순환 의존)보다 싸다.

**예외**: 파생 프로퍼티가 UI/DesignSystem 개념을 전혀 포함하지 않고 순수하게 Domain 모델의
불변식(정렬 순서, 기본값 선택 등)만 표현한다면 위 "각자 중복" 원칙을 적용하지 않고
`DomainInterface`에 둔다 — 이 경우는 여러 Feature가 "화면별로 다르게 가공"하는 게 아니라
"이미 존재하는 하나의 도메인 사실을 그대로 반복 복사"하는 것이므로, 중복을 감수할 이유가 없다.
예: `Lesson.Word.primaryMeaning`(`definitions.first?.meaning` — "definitions는 순서가 있고
첫 번째가 대표 뜻"이라는 도메인 불변식)은 `DomainInterface`에 위치한다. 반대로 화면 상태 판정·
라벨·색상이 조금이라도 섞이면 이 예외를 적용하지 않고 각 Feature 모듈에 둔다.

---

## 내비게이션 — enum Destination (SOT)

내비게이션 상태는 ViewModel의 `destination` 프로퍼티 하나가 단일 진실 공급원(SOT)이다.

```swift
@Observable
final class HomeViewModel {
    var destination: Destination?

    @CasePathable
    enum Destination {
        case lesson(LessonDetailViewModel)
    }

    func didTapLesson(id: String) {
        destination = .lesson(LessonDetailViewModel(lessonID: id))
    }
}
```

View는 `destination`을 바인딩으로 연결하고, 분기 로직을 직접 갖지 않는다.

```swift
.navigationDestination(item: $viewModel.destination.lesson) { detailVM in
    LessonDetailView(viewModel: detailVM)
}
```

**이 패턴의 핵심 규칙**:

- `destination = nil` 이면 내비게이션 없음, `destination = .some(case)` 이면 해당 화면으로 이동 — 상태와 UI가 항상 동기화된다
- 다음 화면의 ViewModel(`LessonDetailViewModel`)을 `Destination` case의 연관값으로 넘긴다. View는 ViewModel을 직접 생성하지 않는다
- `@CasePathable`은 SwiftUINavigation이 `$viewModel.destination.lesson` 처럼 특정 case만 바인딩하기 위해 필요하다. 제거하면 컴파일 에러가 아닌 런타임 오작동이 발생하므로 반드시 유지한다

---

## DI 패턴 — swift-dependencies

모든 외부 의존성(Supabase, Keychain, AVFoundation 등)은 struct-of-closures로 감싼다. Repository/UseCase 각각이 이 형태를 따른다 — 자세한 위치와 역할은 위 [Repository / UseCase 패턴](#repository--usecase-패턴) 참고.

```swift
// Repository — Domain/Interface/Repository/LessonRepository.swift
public struct LessonRepository: Sendable {
    public var fetchDetail: @Sendable (_ id: String) async throws -> Lesson
}

extension LessonRepository: TestDependencyKey {
    public static let testValue = LessonRepository(
        fetchDetail: unimplemented("\(Self.self).fetchDetail")
    )
    // previewValue 없음 — ViewModel이 직접 참조하지 않는다
}

// UseCase — Domain/Interface/UseCase/LoadLessonDetailUseCase.swift
public struct LoadLessonDetailUseCase: Sendable {
    public var execute: @Sendable (_ id: String) async throws -> (lesson: Lesson, audioReady: Task<Void, Never>)
}

extension LoadLessonDetailUseCase: TestDependencyKey {
    public static let testValue = LoadLessonDetailUseCase(
        execute: unimplemented("\(Self.self).execute")
    )
}

// UseCase의 liveValue — Domain/Sources/UseCase/LoadLessonDetailUseCase+Live.swift
extension LoadLessonDetailUseCase: DependencyKey {
    public static let liveValue = LoadLessonDetailUseCase(
        execute: { id in
            @Dependency(\.lessonRepository) var lessonRepository
            let lesson = try await lessonRepository.fetchDetail(id)
            let audioReady = Task { /* 오디오 prefetch */ }
            return (lesson, audioReady)
        }
    )
}
```

- Repository의 `liveValue`(Supabase 실제 호출)는 `Data/Sources/Lesson/LessonRepository+Live.swift`에 위치한다
- `testValue`: `unimplemented` — 호출 시 테스트 즉시 실패. 의도하지 않은 호출 감지
- UseCase의 `previewValue`: 고정 Fixture 반환. ViewModel/Example 앱이 사용한다

---
