// ─────────────────────────────────────────────────────────────────────────────
// 4. ArtistMusicApp.swift  (entry point – adds Import tab)
// ─────────────────────────────────────────────────────────────────────────────
import SwiftUI

private struct RootView: View {
    @EnvironmentObject private var store: ArtistStore
    @EnvironmentObject private var player: AudioPlayer

    var body: some View {
        TabView {
            // Existing artist carousel + now‑playing stack
            ZStack(alignment: .bottom) {
                ArtistCarouselView()
                    .environmentObject(store)
                    .environmentObject(player)
                NowPlayingBar()
                    .environmentObject(player)
            }
            .tabItem { Label("Artists", systemImage: "music.mic") }

            // New Import tab
            FileSystemView()
                .environmentObject(store)
                .tabItem { Label("Import", systemImage: "tray.and.arrow.down") }
        }
    }
}

@main
struct ArtistMusicApp: App {
    @StateObject private var store  = ArtistStore()
    @StateObject private var player = AudioPlayer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(player)
        }
    }
}
