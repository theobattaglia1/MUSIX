// ─────────────────────────────────────────────────────────────────────────────
// 1. FileSystemManager.swift
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import Combine
import UniformTypeIdentifiers

@MainActor
public final class FileSystemManager: ObservableObject {
    // Published list of audio files across all watched folders, alpha‑sorted.
    @Published public private(set) var files:   [URL] = []
    @Published public private(set) var folders: [URL] = []   // for UI / future removal

    // MARK: – Private state ----------------------------------------------------
    private struct Watcher { let descriptor: Int32; let source: DispatchSourceFileSystemObject }
    nonisolated(unsafe) private var watchers: [URL: Watcher] = [:]

    private enum Keys { static let bookmarks = "ImportFolderBookmarks" }

    // MARK: – Init -------------------------------------------------------------
    public init() {
        let docs  = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let local = docs.appendingPathComponent("Import", isDirectory: true)
        try? FileManager.default.createDirectory(at: local, withIntermediateDirectories: true)
        addFolder(local, saveBookmark: false)

        if let datas = UserDefaults.standard.array(forKey: Keys.bookmarks) as? [Data] {
            for data in datas {
                var stale = false
                if let url = try? URL(resolvingBookmarkData: data, options: [.withoutUI], bookmarkDataIsStale: &stale) {
                    _ = url.startAccessingSecurityScopedResource()
                    addFolder(url, saveBookmark: false)
                }
            }
        }

        refreshAllFiles()
    }

    // MARK: – Deinit -----------------------------------------------------------
    deinit {
        for watcher in watchers.values {
            watcher.source.cancel()
            close(watcher.descriptor)
        }
        // Main‑actor access to `folders` for security‑scope teardown
        Task { @MainActor in
            for url in folders where url.hasDirectoryPath {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }

    // MARK: – Public API -------------------------------------------------------
    public func addFolder(_ url: URL, saveBookmark: Bool = true) {
        guard watchers[url] == nil else { return }
        folders.append(url)
        startWatching(url)
        refreshAllFiles()
        if saveBookmark { persistBookmark(for: url) }
    }

    // MARK: – Private helpers --------------------------------------------------
    private func startWatching(_ folderURL: URL) {
        let descriptor = open(folderURL.path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        let src = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: .write, queue: .main)
        src.setEventHandler { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in self.refreshAllFiles() }
        }
        src.setCancelHandler { close(descriptor) }
        src.resume()
        watchers[folderURL] = Watcher(descriptor: descriptor, source: src)
    }

    private func refreshAllFiles() {
        let keys: [URLResourceKey] = [.isRegularFileKey, .typeIdentifierKey]
        var aggregated: [URL] = []
        for folder in folders {
            let urls = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles])) ?? []
            aggregated.append(contentsOf: urls.filter { Self.isAudioFile($0) })
        }
        files = aggregated.sorted { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() }
    }

    private func persistBookmark(for url: URL) {
        guard let data = try? url.bookmarkData(options: [.minimalBookmark], includingResourceValuesForKeys: nil, relativeTo: nil) else { return }
        var current = (UserDefaults.standard.array(forKey: Keys.bookmarks) as? [Data]) ?? []
        current.append(data)
        UserDefaults.standard.set(current, forKey: Keys.bookmarks)
    }

    private static func isAudioFile(_ url: URL) -> Bool {
        guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else { return false }
        return type.conforms(to: .audio)
    }
}
