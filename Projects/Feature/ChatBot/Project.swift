import ProjectDescription
import DependencyPlugin

let project = Project.makeModule(
    name: ModulePath.Feature.name + ModulePath.Feature.chatBot.rawValue,
    targets: [
        .feature(implements: .chatBot, factory: .init(
            dependencies: [
                .domainInterface,
                .dependencies,
                .designSystem,
            ]
        )),
        .feature(tests: .chatBot, factory: .init(
            dependencies: [
                .feature(implements: .chatBot),
                .dependencies,
            ]
        )),
        .feature(example: .chatBot, factory: .init(
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
                .feature(implements: .chatBot),
                .domainInterface,
                .domain,
                .data,
                .networking,
                .dependencies,
                .designSystem,
            ],
            settings: .settings(
                configurations: [
                    .debug(name: "Debug", xcconfig: "../../App/Secrets.xcconfig"),
                    .release(name: "Release", xcconfig: "../../App/Secrets.xcconfig")
                ]
            )
        )),
    ],
    schemes: [
        .scheme(
            name: "FeatureChatBotExample",
            buildAction: .buildAction(targets: [.target("FeatureChatBotExample")]),
            runAction: .runAction(executable: .target("FeatureChatBotExample"))
        )
    ]
)
