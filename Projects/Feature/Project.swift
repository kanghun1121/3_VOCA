import ProjectDescription
import DependencyPlugin

let targets: [Target] = [
    .feature(factory: .init(
        dependencies: [
            .feature(implements: .chunkReader),
            .feature(implements: .chatBot),
            .feature(implements: .home),
            .feature(implements: .login),
            .feature(implements: .lesson),
            .feature(implements: .word),
            .feature(implements: .wordGame),
            .feature(implements: .myPage),
        ]
    ))
]

let project = Project.makeModule(name: "Feature", targets: targets)
