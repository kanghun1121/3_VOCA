import ProjectDescription

let workspace = Workspace(
    name: "FiveVoca",
    projects: ["Projects/**"],
    schemes: [
        .scheme(
            name: "AllTest",
            buildAction: .buildAction(targets: [
                .project(path: "Projects/Core", target: "CoreTests"),
                .project(path: "Projects/Domain", target: "DomainTests"),
                .project(path: "Projects/Data", target: "DataTests"),
                .project(path: "Projects/Networking", target: "NetworkingTests"),
                .project(path: "Projects/Feature/ChunkReader", target: "FeatureChunkReaderTests"),
                .project(path: "Projects/Feature/ChatBot", target: "FeatureChatBotTests"),
                .project(path: "Projects/Feature/Home", target: "FeatureHomeTests"),
                .project(path: "Projects/Feature/Login", target: "FeatureLoginTests"),
                .project(path: "Projects/Feature/MyPage", target: "FeatureMyPageTests"),
                .project(path: "Projects/Feature/Lesson", target: "FeatureLessonTests"),
                .project(path: "Projects/Feature/Word", target: "FeatureWordTests"),
                .project(path: "Projects/Feature/WordGame", target: "FeatureWordGameTests"),
            ]),
            testAction: .targets([
                .testableTarget(
                    target: .project(path: "Projects/Core", target: "CoreTests")
                ),
                .testableTarget(
                    target: .project(path: "Projects/Domain", target: "DomainTests")
                ),
                .testableTarget(
                    target: .project(path: "Projects/Data", target: "DataTests")
                ),
                .testableTarget(
                    target: .project(path: "Projects/Networking", target: "NetworkingTests")
                ),
                .testableTarget(
                    target: .project(path: "Projects/Feature/ChunkReader", target: "FeatureChunkReaderTests")
                ),
                .testableTarget(
                    target: .project(path: "Projects/Feature/ChatBot", target: "FeatureChatBotTests")
                ),
                .testableTarget(
                    target: .project(path: "Projects/Feature/Home", target: "FeatureHomeTests")
                ),
                .testableTarget(
                    target: .project(path: "Projects/Feature/Login", target: "FeatureLoginTests")
                ),
                .testableTarget(
                    target: .project(path: "Projects/Feature/MyPage", target: "FeatureMyPageTests")
                ),
                .testableTarget(
                    target: .project(path: "Projects/Feature/Lesson", target: "FeatureLessonTests")
                ),
                .testableTarget(
                    target: .project(path: "Projects/Feature/Word", target: "FeatureWordTests")
                ),
                .testableTarget(
                    target: .project(path: "Projects/Feature/WordGame", target: "FeatureWordGameTests")
                ),
            ])
        )
    ]
)
