import Foundation

import Dependencies

public extension DependencyValues {
    var sseClient: any SSEClienting {
        get { self[SSEClientKey.self] }
        set { self[SSEClientKey.self] = newValue }
    }
}

public enum SSEClientKey: TestDependencyKey {
    public static let testValue: any SSEClienting = unimplemented(
        "\(Self.self).testValue",
        placeholder: NoopSSEClient()
    )
}

private struct NoopSSEClient: SSEClienting {
    func stream(
        _ requestable: any Requestable,
        onResponse: (@Sendable (HTTPURLResponse) -> Void)?
    ) -> AsyncThrowingStream<SSEFrame, Error> {
        AsyncThrowingStream { $0.finish() }
    }
}
