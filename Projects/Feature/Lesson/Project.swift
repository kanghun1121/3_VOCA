import ProjectDescription
import DependencyPlugin

let project = Project.makeModule(
    name: ModulePath.Feature.name + ModulePath.Feature.lesson.rawValue,
    targets: [
        .feature(implements: .lesson, factory: .init(
            dependencies: [
                .feature(implements: .vocabulary),
                .feature(implements: .wordGame),
                .dependencies,
                .designSystem,
                .swiftUINavigation,
            ]
        )),
        .feature(tests: .lesson, factory: .init(
            dependencies: [
                .feature(implements: .lesson),
                .domainInterface,
                .dependencies,
            ]
        )),
        .feature(example: .lesson, factory: .init(
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
                .feature(implements: .lesson),
                .dependencies,
                .designSystem,
            ]
        )),
    ],
    schemes: [
        .scheme(
            name: "FeatureLessonExample",
            buildAction: .buildAction(targets: [.target("FeatureLessonExample")]),
            runAction: .runAction(executable: .target("FeatureLessonExample"))
        )
    ]
)
