import ProjectDescription
import DependencyPlugin

let project = Project.makeModule(
    name: ModulePath.Feature.name + ModulePath.Feature.home.rawValue,
    targets: [
        .feature(implements: .home, factory: .init(
            dependencies: [
                .feature(implements: .lesson),
                .domainInterface,
                .dependencies,
                .designSystem,
                .swiftUINavigation,
            ]
        )),
        .feature(tests: .home, factory: .init(
            dependencies: [
                .feature(implements: .home),
                .domainInterface,
                .dependencies,
            ]
        )),
        .feature(example: .home, factory: .init(
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": "1.0",
                "CFBundleVersion": "1",
                "UILaunchStoryboardName": "LaunchScreen",
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": false,
                    "UISceneConfigurations": [:]
                ],
                "UIAppFonts": [
                    "Pretendard-Thin.otf",
                    "Pretendard-ExtraLight.otf",
                    "Pretendard-Light.otf",
                    "Pretendard-Regular.otf",
                    "Pretendard-Medium.otf",
                    "Pretendard-SemiBold.otf",
                    "Pretendard-Bold.otf",
                    "Pretendard-ExtraBold.otf",
                    "Pretendard-Black.otf"
                ]
            ]),
            resources: ["Example/Resources/**"],
            dependencies: [
                .feature(implements: .home),
                .dependencies,
                .designSystem,
            ]
        )),
    ],
    schemes: [
        .scheme(
            name: "FeatureHomeExample",
            buildAction: .buildAction(targets: [.target("FeatureHomeExample")]),
            runAction: .runAction(executable: .target("FeatureHomeExample"))
        )
    ]
)
