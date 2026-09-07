import Foundation

import DomainInterface
import NetworkingInterface

import Dependencies

extension AudioRepository: DependencyKey {
    public static let liveValue = AudioRepository(
        prefetch: { words in
            @Dependency(\.audioMemoryCache) var memory
            @Dependency(\.audioDiskCache) var disk
            @Dependency(\.audioRemoteDataSource) var remote

            await withTaskGroup(of: Void.self) { group in
                for (term, audioUrlString) in words {
                    group.addTask {
                        if await memory.url(for: term) != nil { return }
                        if let diskURL = disk.url(for: term) {
                            await memory.markReady(term, url: diskURL)
                            return
                        }
                        guard let remoteURL = URL(string: audioUrlString) else { return }
                        guard let data = try? await remote.download(from: remoteURL) else { return }
                        guard let fileURL = try? disk.store(data, for: term) else { return }
                        await memory.markReady(term, url: fileURL)
                    }
                }
            }
        },
        fetchURL: { term, audioUrlString in
            @Dependency(\.audioMemoryCache) var memory
            @Dependency(\.audioDiskCache) var disk
            @Dependency(\.audioRemoteDataSource) var remote

            if let cached = await memory.url(for: term) { return cached }
            if let diskURL = disk.url(for: term) {
                await memory.markReady(term, url: diskURL)
                return diskURL
            }
            guard let remoteURL = URL(string: audioUrlString) else { return nil }
            guard let data = try? await remote.download(from: remoteURL) else { return nil }
            guard let fileURL = try? disk.store(data, for: term) else { return nil }
            await memory.markReady(term, url: fileURL)
            return fileURL
        },
        url: { term in
            @Dependency(\.audioMemoryCache) var memory
            @Dependency(\.audioDiskCache) var disk

            if let cached = await memory.url(for: term) { return cached }
            guard let diskURL = disk.url(for: term) else { return nil }
            await memory.markReady(term, url: diskURL)
            return diskURL
        }
    )
}
