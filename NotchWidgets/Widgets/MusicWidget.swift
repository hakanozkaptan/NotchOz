import SwiftUI
import AppKit

// MARK: - Hover animation

private struct HoverScaleModifier: ViewModifier {
    var scale: CGFloat = 1.06
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

private extension View {
    func musicHoverScale(_ scale: CGFloat = 1.06) -> some View {
        modifier(HoverScaleModifier(scale: scale))
    }
}

// MARK: - Widget

struct MusicWidget: View {
    let compact: Bool
    @StateObject private var viewModel = MusicWidgetViewModel()

    var body: some View {
        Group {
            if viewModel.isPlaying, let track = viewModel.currentTrack {
                HStack(spacing: 12) {
                    artworkView
                    trackInfoView(track: track)
                    mediaControls(isPlaying: true)
                    barVisualizer
                }
            } else {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 44, height: 44)
                        Image(systemName: "music.note")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(Color.white.opacity(0.25))
                    }
                    Text(L10n.string("music_not_playing"))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.45))
                    Spacer(minLength: 0)
                    mediaControls(isPlaying: false)
                }
            }
        }
        .onAppear { viewModel.startPolling() }
        .onDisappear { viewModel.stopPolling() }
    }

    private var artworkView: some View {
        Group {
            if let art = viewModel.artworkImage {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                    .transition(.opacity)
            } else {
                RoundedRectangle(cornerRadius: 9)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.55, blue: 0.38),
                                Color(red: 0.12, green: 0.35, blue: 0.48)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(.white.opacity(0.7))
                    )
                    .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
            }
        }
        .animation(.easeOut(duration: 0.25), value: viewModel.artworkImage != nil)
        .musicHoverScale(1.08)
    }

    private func trackInfoView(track: NowPlayingTrack) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(track.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(track.artist)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.5))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var barVisualizer: some View {
        BarVisualizerView()
    }

    private func mediaControls(isPlaying: Bool) -> some View {
        HStack(spacing: 10) {
            // Previous
            Button(action: { MusicWidgetViewModel.spotifyPrevious() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .musicHoverScale(1.12)

            // Play / Pause — circular accent button
            Button(action: { MusicWidgetViewModel.spotifyPlayPause() }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.52, green: 0.36, blue: 0.80),
                                    Color(red: 0.68, green: 0.46, blue: 0.90)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .shadow(color: Color(red: 0.6, green: 0.4, blue: 0.85).opacity(0.45), radius: 8, x: 0, y: 2)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .offset(x: isPlaying ? 0 : 1)
                }
            }
            .buttonStyle(.plain)
            .musicHoverScale(1.1)

            // Next
            Button(action: { MusicWidgetViewModel.spotifyNext() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .musicHoverScale(1.12)
        }
    }
}

struct BarVisualizerView: View {
    private let barCount = 4
    private let barWidth: CGFloat = 2.5
    private let barMaxHeight: CGFloat = 16

    private let accentColor = Color(red: 0.6, green: 0.42, blue: 0.88)

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.12)) { context in
            let t = context.date.timeIntervalSince1970
            HStack(spacing: 2.5) {
                ForEach(0..<barCount, id: \.self) { i in
                    let phase = t + Double(i) * 0.3
                    let h = 0.25 + 0.65 * (sin(phase * 3.8 + Double(i) * 0.8) * 0.5 + 0.5)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: barWidth, height: max(4, barMaxHeight * CGFloat(h)))
                }
            }
            .frame(height: barMaxHeight, alignment: .bottom)
        }
    }
}

struct NowPlayingTrack {
    let name: String
    let artist: String
}

@MainActor
final class MusicWidgetViewModel: ObservableObject {
    @Published private(set) var currentTrack: NowPlayingTrack?
    @Published private(set) var isPlaying = false
    @Published private(set) var artworkImage: NSImage?

    private var pollingTask: Task<Void, Never>?
    private let pollInterval: UInt64 = 2_000_000_000  // 2 seconds in nanoseconds

    func startPolling() {
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { break }
                await self.poll()
                try? await Task.sleep(nanoseconds: self.pollInterval)
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    // Runs on @MainActor; dispatches blocking osascript to a detached task
    private func poll() async {
        let result = await Task.detached(priority: .utility) {
            Self.getSpotifyNowPlaying()
        }.value

        guard let (name, artist, playing) = result else {
            isPlaying = false
            currentTrack = nil
            artworkImage = nil
            return
        }

        isPlaying = playing
        if playing, !name.isEmpty {
            currentTrack = NowPlayingTrack(name: name, artist: artist)
            let artworkURL = await Task.detached(priority: .utility) {
                Self.getSpotifyArtworkURL()
            }.value
            if let url = artworkURL {
                artworkImage = await Self.loadArtwork(from: url)
            } else {
                artworkImage = nil
            }
        } else {
            currentTrack = nil
            artworkImage = nil
        }
    }

    private nonisolated static func getSpotifyNowPlaying() -> (String, String, Bool)? {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                try
                    set playerState to player state
                    if playerState is playing then
                        set trackName to name of current track
                        set artistName to artist of current track
                        if trackName is not "" then
                            return trackName & "|||" & artistName & "|||1"
                        end if
                    end if
                end try
            end tell
        end if
        return "|||0"
        """
        guard let output = runOsascript(script) else { return nil }
        let segments = output.components(separatedBy: "|||").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if segments.count >= 2, segments[1] == "0" {
            return ("", "", false)
        }
        guard segments.count >= 3 else { return nil }
        let name = segments[0]
        let artist = segments[1]
        let playing = segments[2] == "1"
        return (name, artist, playing)
    }

    private nonisolated static func getSpotifyArtworkURL() -> URL? {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify" to try
                return artwork url of current track
            end try
        end if
        return ""
        """
        guard let urlString = runOsascript(script),
              !urlString.isEmpty,
              let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        return url
    }

    private nonisolated static let artworkSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 4
        return URLSession(configuration: config, delegate: nil, delegateQueue: queue)
    }()

    private nonisolated static func loadArtwork(from url: URL) async -> NSImage? {
        let data = try? await artworkSession.data(from: url).0
        return data.flatMap { NSImage(data: $0) }
    }

    private nonisolated static func runOsascript(_ script: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    static func spotifyPrevious() {
        Task.detached(priority: .userInitiated) {
            _ = runOsascript("if application \"Spotify\" is running then tell application \"Spotify\" to previous track")
        }
    }

    static func spotifyPlayPause() {
        Task.detached(priority: .userInitiated) {
            _ = runOsascript("if application \"Spotify\" is running then tell application \"Spotify\" to playpause")
        }
    }

    static func spotifyNext() {
        Task.detached(priority: .userInitiated) {
            _ = runOsascript("if application \"Spotify\" is running then tell application \"Spotify\" to next track")
        }
    }
}
