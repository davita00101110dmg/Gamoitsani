//
//  WordStoreFactory.swift
//  GamoitsaniData
//
import Foundation
import SwiftData

public enum WordStoreFactory {

    /// Opens the on-disk cache, rebuilding it if it cannot be loaded.
    public static func makeOnDisk(
        url: URL? = nil,
        rebuildOnFailure: Bool = true
    ) throws -> (store: WordStore, didRebuild: Bool) {
        let configuration = url.map { ModelConfiguration(url: $0) } ?? ModelConfiguration()

        do {
            let container = try ModelContainer(for: CachedWord.self, configurations: configuration)
            return (WordStore(modelContainer: container), false)
        } catch {
            guard rebuildOnFailure else { throw error }

            // Delete whatever is there and try once more. If this also fails the problem is
            // not the store's contents and the error should propagate.
            let storeURL = configuration.url
            try? FileManager.default.removeItem(at: storeURL)
            for suffix in ["-wal", "-shm"] {
                try? FileManager.default.removeItem(
                    at: storeURL.deletingPathExtension()
                        .appendingPathExtension("store" + suffix)
                )
            }

            let container = try ModelContainer(for: CachedWord.self, configurations: configuration)
            return (WordStore(modelContainer: container), true)
        }
    }

    /// An in-memory store, for tests and previews.
    public static func makeInMemory() throws -> WordStore {
        let container = try ModelContainer(
            for: CachedWord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return WordStore(modelContainer: container)
    }
}
