import ProjectDescription
import DependencyPlugin

let project = Project.makeModule(
    name: ModulePath.Feature.name + ModulePath.Feature.word.rawValue,
    targets: [
        .feature(implements: .word, factory: .init(
            dependencies: [
                .feature(implements: .chunkReader),
                .feature(implements: .chatBot),
                .dependencies,
                .designSystem,
                .swiftUINavigation,
            ]
        )),
        .feature(tests: .word, factory: .init(
            dependencies: [
                .feature(implements: .word),
                .domainInterface,
                .dependencies,
            ]
        )),
        .feature(example: .word, factory: .init(
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": "1.0",
                "CFBundleVersion": "1",
                "UILaunchStoryboardName": "LaunchScreen",
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": false,
                    "UISceneConfigurations": [:]
                ]
            ]),
            resources: ["Example/Resources/**"],
            dependencies: [
                .feature(implements: .word),
                .dependencies,
                .designSystem,
            ]
        )),
    ],
    schemes: [
        .scheme(
            name: "FeatureWordExample",
            buildAction: .buildAction(targets: [.target("FeatureWordExample")]),
            runAction: .runAction(executable: .target("FeatureWordExample"))
        )
    ]
)
