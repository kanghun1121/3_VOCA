import ProjectDescription
import DependencyPlugin

let targets: [Target] = [
    .feature(factory: .init(
        dependencies: [
            .feature(implements: .analysis),
            .feature(implements: .chatBot),
            .feature(implements: .home),
            .feature(implements: .login),
            .feature(implements: .lesson),
            .feature(implements: .vocabulary),
            .feature(implements: .wordGame),
            .feature(implements: .myPage),
        ]
    ))
]

let project = Project.makeModule(name: "Feature", targets: targets)
