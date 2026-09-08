import ProjectDescription
import DependencyPlugin

let project = Project.makeModule(
    name: ModulePath.Feature.name + ModulePath.Feature.chunkReader.rawValue,
    targets: [
        .feature(implements: .chunkReader, factory: .init(
            dependencies: [
                .domainInterface,
                .dependencies,
                .designSystem,
                .swiftUINavigation,
            ]
        )),
        .feature(tests: .chunkReader, factory: .init(
            dependencies: [
                .feature(implements: .chunkReader),
                .domainInterface,
                .dependencies,
            ]
        )),
        .feature(example: .chunkReader, factory: .init(
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
                .feature(implements: .chunkReader),
                .domainInterface,
                .dependencies,
                .designSystem,
            ]
        )),
    ],
    schemes: [
        .scheme(
            name: "FeatureChunkReaderExample",
            buildAction: .buildAction(targets: [.target("FeatureChunkReaderExample")]),
            runAction: .runAction(executable: .target("FeatureChunkReaderExample"))
        )
    ]
)
