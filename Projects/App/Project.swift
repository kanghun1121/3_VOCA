import ProjectDescription
import DependencyPlugin

let project = Project.makeModule(
    name: env.appName,
    targets: [
        .app(factory: .init(
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                "UILaunchStoryboardName": "LaunchScreen",
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": false,
                    "UISceneConfigurations": [:]
                ],
                "SUPABASE_ANON_KEY": "$(SUPABASE_ANON_KEY)",
                "MW_DICTIONARY_API_KEY": "$(MW_DICTIONARY_API_KEY)",
                "ITSAppUsesNonExemptEncryption": false,
                "PRIVACY_POLICY_URL": "https://maize-erica-237.notion.site/387a1c6f6ce080ba927ef413ffe4cfd4",
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
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            entitlements: .file(path: "FiveVoca.entitlements"),
            dependencies: [.feature, .domain, .data, .networking, .core, .designSystem],
            settings: .settings(
                configurations: [
                    .debug(name: "Debug", xcconfig: "Secrets.xcconfig"),
                    .release(name: "Release", settings: [
                        "CODE_SIGN_STYLE": "Manual",
                        "CODE_SIGN_IDENTITY": "Apple Distribution",
                    ], xcconfig: "Secrets.xcconfig")
                ]
            )
        ))
    ],
    schemes: [
        .scheme(
            name: env.appName,
            buildAction: .buildAction(targets: [.target(env.appName)]),
            runAction: .runAction(
                configuration: .debug,
                arguments: .arguments(
                    environmentVariables: [
                        "ENABLE_NETWORK_LOG": .environmentVariable(value: "1", isEnabled: true)
                    ]
                )
            )
        ),
        .scheme(
            name: "\(env.appName)-Release",
            buildAction: .buildAction(targets: [.target(env.appName)]),
            runAction: .runAction(configuration: .release)
        )
    ]
)
