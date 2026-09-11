import Foundation

import DomainInterface
import NetworkingInterface

import Dependencies

extension AudioRepository: DependencyKey {
    public static let liveValue = AudioRepository(
        prefetch: { words in
            @Dependency(\.audioMemoryCache) var memoryCache
            @Dependency(\.audioDiskCache) var diskCache
            @Dependency(\.audioRemoteDataSource) var remoteDataSource

            await withTaskGroup(of: Void.self) { group in
                for (term, audioUrlString) in words {
                    group.addTask {
                        if await memoryCache.url(for: term, expecting: audioUrlString) != nil { return }
                        if let diskURL = diskCache.url(for: term, expecting: audioUrlString) {
                            await memoryCache.markReady(term, url: diskURL, remoteURLString: audioUrlString)
                            return
                        }
                        guard let remoteURL = URL(string: audioUrlString) else { return }
                        guard let data = try? await remoteDataSource.download(from: remoteURL) else { return }
                        guard let fileURL = try? diskCache.store(data, for: term, remoteURLString: audioUrlString) else { return }
                        await memoryCache.markReady(term, url: fileURL, remoteURLString: audioUrlString)
                    }
                }
            }
        },
        fetchURL: { term, audioUrlString in
            @Dependency(\.audioMemoryCache) var memoryCache
            @Dependency(\.audioDiskCache) var diskCache
            @Dependency(\.audioRemoteDataSource) var remoteDataSource

            if let cached = await memoryCache.url(for: term, expecting: audioUrlString) { return cached }
            if let diskURL = diskCache.url(for: term, expecting: audioUrlString) {
                await memoryCache.markReady(term, url: diskURL, remoteURLString: audioUrlString)
                return diskURL
            }
            guard let remoteURL = URL(string: audioUrlString) else { return nil }
            guard let data = try? await remoteDataSource.download(from: remoteURL) else { return nil }
            guard let fileURL = try? diskCache.store(data, for: term, remoteURLString: audioUrlString) else { return nil }
            await memoryCache.markReady(term, url: fileURL, remoteURLString: audioUrlString)
            return fileURL
        },
        url: { term in
            @Dependency(\.audioMemoryCache) var memoryCache
            @Dependency(\.audioDiskCache) var diskCache

            if let cached = await memoryCache.url(for: term) { return cached }
            guard let diskURL = diskCache.url(for: term) else { return nil }
            await memoryCache.markReady(term, url: diskURL)
            return diskURL
        }
    )
}
