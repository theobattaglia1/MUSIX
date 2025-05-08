// ─────────────────────────────────────────────────────────────────────────────
// 3. ArtistStore+Import.swift  (data‑layer helper)
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

extension ArtistStore {
    /// Imports an audio file into a special “External Imports” artist bucket.
    @MainActor
    func importSong(from url: URL) {
        let title     = url.deletingPathExtension().lastPathComponent
        let fileName  = url.lastPathComponent

        let song = Song(title: title,
                        version: "",            // placeholder; customize as needed
                        creators: [],
                        date: Date(),
                        notes: "",              // empty string avoids optional mismatch
                        artworkData: nil,
                        fileName: fileName)

        let bucketName = "External Imports"
        if let idx = artists.firstIndex(where: { $0.name == bucketName }) {
            artists[idx].songs.append(song)
        } else {
            let newArtist = Artist(name: bucketName,
                                   bannerData: nil,
                                   avatarData: nil,
                                   songs: [song])
            artists.append(newArtist)
        }
    }
}
