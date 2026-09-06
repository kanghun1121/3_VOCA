import ProjectDescription
import DependencyPlugin

let project = Project.makeModule(
    name: "Data",
    targets: [
        .data(factory: .init(
            resources: ["Resources/**"],
            dependencies: [
                .domainInterface,
                .core,
                .networkingInterface,
                .dependencies,
            ]
        )),
        .data(tests: .init(
            dependencies: [
                .data,
                .domainInterface,
                .networkingInterface,
                .dependencies,
            ]
        )),
    ]
)
