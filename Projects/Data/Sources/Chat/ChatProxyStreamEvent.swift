import Foundation

enum ChatProxyStreamEvent: Sendable, Equatable {
    case textDelta(String)
    case messageStop
}
