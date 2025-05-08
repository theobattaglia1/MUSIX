// ─────────────────────────────────────────────────────────────────────────────
// FileSystemView.swift
// ─────────────────────────────────────────────────────────────────────────────
import SwiftUI
import UniformTypeIdentifiers

struct FileSystemView: View {
    @StateObject private var fs = FileSystemManager()
    @EnvironmentObject private var store: ArtistStore
    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            List {
                if fs.files.isEmpty {
                    ContentUnavailableView("Drop audio files into any selected folder", systemImage: "tray.and.arrow.down")
                } else {
                    ForEach(fs.files, id: \.self) { url in
                        HStack {
                            Image(systemName: "music.note")
                            Text(url.lastPathComponent).lineLimit(1)
                            Spacer()
                            Button("Add") { store.importSong(from: url) }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .navigationTitle("Import")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button { showingPicker = true } label: {
                            Label("Add Folder", systemImage: "folder.badge.plus").labelStyle(.iconOnly)
                        }
                        Button {
                            if let first = fs.folders.first { UIApplication.shared.open(first) }
                        } label: {
                            Label("Open in Files", systemImage: "folder").labelStyle(.iconOnly)
                        }
                    }
                }
            }
            .fileImporter(isPresented: $showingPicker,
                          allowedContentTypes: [.folder],
                          allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls): urls.forEach { fs.addFolder($0) }
                case .failure(let err):  print("Folder import error: \(err.localizedDescription)")
                }
            }
        }
    }
}

