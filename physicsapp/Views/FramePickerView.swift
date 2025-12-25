//
//  FramePickerView.swift
//  physicsapp
//
//  Created by Michelle on 12/14/25.
//

import AVFoundation
import AVKit
import PhotosUI
import SwiftUI

// Data structure for delta time history
struct DeltaTimeEntry: Codable, Identifiable {
    let id: UUID
    let videoName: String
    let deltaTime: Double
    let startTime: Double
    let endTime: Double
    let timestamp: Date

    init(videoName: String, deltaTime: Double, startTime: Double, endTime: Double, timestamp: Date)
    {
        self.id = UUID()
        self.videoName = videoName
        self.deltaTime = deltaTime
        self.startTime = startTime
        self.endTime = endTime
        self.timestamp = timestamp
    }
}

struct FramePickerView: View {
    @Binding var video: VideoData
    @Binding var startTime: Double?
    @Binding var endTime: Double?
    @Binding var duration: Double?
    let onDismiss: () -> Void

    // Video playback state
    @State private var player: AVPlayer?
    @State private var currentTime: Double = 0.0
    @State private var videoDuration: Double = 0.0
    @State private var isPlaying = false
    @State private var isFrameMode = true
    @State private var timeObserver: Any?
    @State private var fps: Float?

    // Playback state
    @State private var hasFinishedPlaying = false

    // Photo picker state
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoadingNewVideo = false

    // History state
    @State private var showingHistory = false
    @State private var deltaTimeHistory: [DeltaTimeEntry] = []

    // Button press states for scaling animation
    @State private var photoPickerButtonPressed = false
    @State private var historyButtonPressed = false
    @State private var resetButtonPressed = false
    @State private var playButtonPressed = false
    @State private var timestampButtonPressed = false
    @State private var previousButtonPressed = false
    @State private var nextButtonPressed = false
    @State private var emptyViewButtonPressed = false

    // Calculate delta time
    private var deltaTime: Double? {
        if let start = startTime, let end = endTime {
            return abs(end - start)
        }
        return nil
    }

    // Check if we should show empty state
    private var isEmptyVideoState: Bool {
        let urlString = video.url.absoluteString
        return urlString.isEmpty || urlString == "" || urlString == "about:blank"
            || urlString.contains("/dev/null") || video.name.isEmpty
    }

    var body: some View {
        VStack(spacing: 8) {
            // Video player area with floating top UI
            ZStack {
                // Background color
                Color.black

                // Video content
                if isEmptyVideoState {
                    // Empty state - no video selected
                    EmptyVideoStateView(selectedItem: $selectedItem)
                } else if isLoadingNewVideo {
                    // Loading state
                    VStack(spacing: 20) {
                        Spacer()

                        // Loading spinner
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        Text("Processing video...")
                            .foregroundColor(.white)
                            .font(.title2)
                            .fontWeight(.medium)

                        Text("This may take a moment")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.body)

                        Spacer()
                    }
                } else if let player = player {
                    VideoPlayer(player: player)
                        .disabled(true)  // Disable built-in controls
                } else {
                    VStack {
                        Spacer()
                        Text("Loading video...")
                            .foregroundColor(.white)
                            .font(.title2)
                        Spacer()
                    }
                }

                // Floating UI overlays
                VStack {

                    // Top floating UI
                    HStack {
                        // Delta time and FPS (only show when video is loaded)
                        if !isEmptyVideoState {
                            HStack {
                                HStack(spacing: 20) {
                                    HStack(alignment: .top, spacing: 4) {
                                        Text(formatTime(deltaTime))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .contentTransition(.numericText())
                                        Text("ΔT")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.secondary)
                                    }
                                    HStack(alignment: .top, spacing: 4) {
                                        if let fps = fps {
                                            Text(String(format: "%.0f", fps))
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                                .contentTransition(.numericText())
                                        } else {
                                            Text("-")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                                .contentTransition(.numericText())
                                        }
                                        Text("FPS")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(
                                    EdgeInsets(top: 9, leading: 12, bottom: 9, trailing: 12)
                                )
                                .background(.bar, in: Capsule())
                                .cornerRadius(15)
                            }
                        }

                        Spacer()

                        // Photo picker and history buttons (always visible)
                        HStack(spacing: 12) {
                            // Photo picker button
                            PhotosPicker(selection: $selectedItem, matching: .videos) {
                                HStack(spacing: 8) {
                                    if isLoadingNewVideo {
                                        ProgressView()
                                            .progressViewStyle(
                                                CircularProgressViewStyle(tint: .yellow)
                                            )
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .frame(width: 24, height: 24)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(isLoadingNewVideo ? .yellow : .white)
                                    }
                                }

                            }
                            .disabled(isLoadingNewVideo)
                            .scaleEffect(photoPickerButtonPressed ? 0.9 : 1.0)
                            .animation(
                                .smooth(duration: 0.1, extraBounce: 0),
                                value: photoPickerButtonPressed
                            )
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        if !photoPickerButtonPressed {
                                            photoPickerButtonPressed = true
                                        }
                                    }
                                    .onEnded { _ in
                                        photoPickerButtonPressed = false
                                    }
                            )
                            Button(action: { showingHistory = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .frame(width: 24, height: 24)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(showingHistory ? .yellow : .white)
                                }

                            }
                            .scaleEffect(historyButtonPressed ? 0.9 : 1.0)
                            .animation(
                                .smooth(duration: 0.1, extraBounce: 0), value: historyButtonPressed
                            )
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        if !historyButtonPressed {
                                            historyButtonPressed = true
                                        }
                                    }
                                    .onEnded { _ in
                                        historyButtonPressed = false
                                    }
                            )

                            // Development reset button (debug builds only)
                            #if DEBUG
                                Button(action: resetAppData) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trash.circle")
                                            .frame(width: 24, height: 24)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.red)
                                    }
                                }
                                .scaleEffect(resetButtonPressed ? 0.9 : 1.0)
                                .animation(
                                    .smooth(duration: 0.1, extraBounce: 0),
                                    value: resetButtonPressed
                                )
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            if !resetButtonPressed {
                                                resetButtonPressed = true
                                            }
                                        }
                                        .onEnded { _ in
                                            resetButtonPressed = false
                                        }
                                )
                            #endif
                        }.padding(
                            EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
                        )
                        .background(.bar, in: Capsule())
                        .cornerRadius(15)

                    }.padding(.top).padding(.leading, 20).padding(.trailing, 20)

                    Spacer()

                    // Bottom floating timestamp and play buttons (only show when video is loaded)
                    if !isEmptyVideoState {
                        HStack(spacing: 20) {

                            // Play/pause button
                            Button(action: togglePlayback) {
                                HStack(spacing: 8) {
                                    Image(
                                        systemName: hasFinishedPlaying
                                            ? "arrow.clockwise"
                                            : (isPlaying ? "pause.fill" : "play.fill")
                                    )
                                    .contentTransition(.symbolEffect)
                                    .foregroundColor(.white)
                                }
                                .padding(
                                    EdgeInsets(top: 9, leading: 12, bottom: 9, trailing: 12)
                                )
                                .background(.bar, in: Capsule())
                                .cornerRadius(15)
                            }
                            .disabled(isEmptyVideoState)
                            .scaleEffect(playButtonPressed ? 0.9 : 1.0)
                            .animation(
                                .smooth(duration: 0.1, extraBounce: 0), value: playButtonPressed
                            )
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        if !playButtonPressed {
                                            playButtonPressed = true
                                        }
                                    }
                                    .onEnded { _ in
                                        playButtonPressed = false
                                    }
                            )

                            // Timestamp button (camera record style)
                            Button(action: handleTimestampAction) {
                                ZStack {
                                    // Always show white border
                                    RoundedRectangle(cornerRadius: isInRecordingState() ? 30 : 30)
                                        .stroke(Color.white, lineWidth: 3)
                                        .frame(width: 60, height: 60)

                                    // Main button - animate corner radius and size
                                    RoundedRectangle(cornerRadius: isInRecordingState() ? 8 : 25)
                                        .fill(Color.yellow)
                                        .frame(
                                            width: isInRecordingState() ? 30 : 50,
                                            height: isInRecordingState() ? 30 : 50
                                        )

                                    // Icon
                                    Image(systemName: getTimestampButtonSymbol())
                                        .foregroundStyle(.black)
                                        .font(.system(size: 20, weight: .semibold))
                                        .contentTransition(.symbolEffect)
                                }
                            }
                            .disabled(isEmptyVideoState)
                            .animation(
                                .smooth(duration: 0.3, extraBounce: 0), value: isInRecordingState()
                            )

                        }
                        .padding(.bottom, 20)
                        .padding(.horizontal, 20)
                    }
                }
            }

            // Bottom controls - timeline only (only show when video is loaded)
            if !isEmptyVideoState {
                VStack(spacing: 16) {
                    // Timeline with chevron buttons around progress bar
                    HStack(alignment: .top, spacing: 8) {
                        // Previous frame button
                        Button(action: previousFrame) {
                            Image(systemName: "chevron.left")
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                                .padding(
                                    EdgeInsets(top: 9, leading: 12, bottom: 9, trailing: 12)
                                )
                                .background(.bar, in: Capsule())
                                .cornerRadius(15)
                        }
                        .disabled(isEmptyVideoState)
                        .scaleEffect(previousButtonPressed ? 0.9 : 1.0)
                        .animation(
                            .smooth(duration: 0.1, extraBounce: 0), value: previousButtonPressed
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !previousButtonPressed {
                                        previousButtonPressed = true
                                    }
                                }
                                .onEnded { _ in
                                    previousButtonPressed = false
                                }
                        )

                        // Timeline with markers in VStack with time display
                        VStack(spacing: 8) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background (unplayed section - darker)
                                    Rectangle()
                                        .foregroundColor(.clear)
                                        .background(Color(red: 0.11, green: 0.11, blue: 0.11))
                                        .frame(height: 40)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .inset(by: -1)
                                                .stroke(
                                                    Color(red: 0.20, green: 0.20, blue: 0.20),
                                                    lineWidth: 2)
                                        )

                                    // Progress indicator (played section - blue) with scrubber
                                    if videoDuration > 0 {
                                        ZStack(alignment: .trailing) {
                                            Rectangle()
                                                .foregroundColor(.clear)
                                                .frame(
                                                    width: (currentTime / videoDuration)
                                                        * geometry.size.width, height: 40
                                                )
                                                .background(Color.white.opacity(0.97))
                                                .cornerRadius(10)

                                            // Scrubber inside the progress bar
                                            Rectangle()
                                                .fill(Color.black.opacity(0.5))
                                                .frame(width: 3.5, height: 22)
                                                .cornerRadius(999)
                                                .padding(.trailing, 6)
                                        }
                                    }

                                    // Timeline markers across the bottom
                                    if videoDuration > 0 {
                                        let progressWidth =
                                            (currentTime / videoDuration) * geometry.size.width
                                        let totalWidth = geometry.size.width
                                        let barHeight: CGFloat = 40
                                        let largeBarHeight = barHeight * 0.3
                                        let smallBarHeight = barHeight * 0.15
                                        let barWidth: CGFloat = 3
                                        let largeBarWidth = barWidth
                                        let smallBarWidth = barWidth / 3

                                        let spacing: CGFloat = 8  // Space between markers

                                        // Create markers across the entire timeline (3 small, 1 big pattern)
                                        ForEach(0..<Int(totalWidth / spacing), id: \.self) { i in
                                            let x = CGFloat(i) * spacing
                                            let patternIndex = i % 4  // 4 markers per pattern (3 small + 1 large)

                                            let isLarge = patternIndex == 3  // 3rd marker in each group of 4 is large
                                            let markerHeight =
                                                isLarge ? largeBarHeight : smallBarHeight
                                            let markerWidth =
                                                isLarge ? largeBarWidth : smallBarWidth

                                            let isPlayed = x <= progressWidth
                                            let markerColor =
                                                isPlayed
                                                ? Color.black.opacity(0.1)
                                                : Color.white.opacity(0.1)

                                            Rectangle()
                                                .fill(markerColor)
                                                .frame(width: markerWidth, height: markerHeight)
                                                .offset(
                                                    x: x - markerWidth / 2,
                                                    y: barHeight / 2 - markerHeight / 2)
                                        }
                                    }

                                    // Start time marker
                                    if let start = startTime, videoDuration > 0 {
                                        Rectangle()
                                            .foregroundColor(.clear)
                                            .frame(width: 3.5, height: 22)
                                            .background(.yellow)
                                            .cornerRadius(999)
                                            .offset(
                                                x: (start / videoDuration) * geometry.size.width
                                                    - 2.5)
                                    }

                                    // End time marker
                                    if let end = endTime, videoDuration > 0 {
                                        Rectangle()
                                            .foregroundColor(.clear)
                                            .frame(width: 3.5, height: 22)
                                            .background(.yellow)
                                            .cornerRadius(999)
                                            .offset(
                                                x: (end / videoDuration) * geometry.size.width - 2.5
                                            )
                                    }
                                }
                                .gesture(
                                    video.url.absoluteString.isEmpty
                                        ? nil
                                        : DragGesture()
                                            .onChanged { value in
                                                let newTime =
                                                    (value.location.x / geometry.size.width)
                                                    * videoDuration
                                                let clampedTime = min(
                                                    max(newTime, 0), videoDuration)
                                                currentTime = clampedTime
                                                seekToTime(clampedTime)
                                            }
                                )
                            }
                            .frame(height: 40)

                            // Time display HStack below just the scrubber
                            HStack {
                                // Current time
                                Text(formatVideoTime(currentTime))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .contentTransition(.numericText())

                                Spacer()

                                // Video duration
                                Text(formatVideoTime(videoDuration))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }

                        // Next frame button
                        Button(action: nextFrame) {
                            Image(systemName: "chevron.right")
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                                .padding(
                                    EdgeInsets(top: 9, leading: 12, bottom: 9, trailing: 12)
                                )
                                .background(.bar, in: Capsule())
                                .cornerRadius(15)
                        }
                        .disabled(isEmptyVideoState)
                        .scaleEffect(nextButtonPressed ? 0.9 : 1.0)
                        .animation(.smooth(duration: 0.1, extraBounce: 0), value: nextButtonPressed)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !nextButtonPressed {
                                        nextButtonPressed = true
                                    }
                                }
                                .onEnded { _ in
                                    nextButtonPressed = false
                                }
                        )
                    }
                }
                .padding(.horizontal, 20)
                // .padding(.bottom, 40)
            }
        }
        .background(Color.black)
        //        .ignoresSafeArea()
        .statusBarHidden(true)
        .onAppear {
            if isEmptyVideoState {
                resetToEmptyState()
            } else {
                setupVideo()
            }
            loadExistingTimestamps()
            loadDeltaTimeHistory()
        }
        .onDisappear {
            cleanupPlayer()
        }
        .onChange(of: video.url) {
            // Re-setup video when URL changes (from loading state to actual video)
            if !isEmptyVideoState {
                setupVideo()
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let newItem = newItem {
                    await loadNewVideo(from: newItem)
                }
            }
        }
        .sheet(isPresented: $showingHistory) {
            DeltaTimeHistoryView(history: deltaTimeHistory)
        }
    }

    private func loadDeltaTimeHistory() {
        if let data = UserDefaults.standard.data(forKey: "deltaTimeHistory"),
            let history = try? JSONDecoder().decode([DeltaTimeEntry].self, from: data)
        {
            deltaTimeHistory = history
        }
    }

    private func saveDeltaTimeToHistory() {
        guard let start = startTime, let end = endTime else { return }

        let deltaTime = abs(end - start)
        let entry = DeltaTimeEntry(
            videoName: video.name,
            deltaTime: deltaTime,
            startTime: start,
            endTime: end,
            timestamp: Date()
        )

        // Remove any existing entry for this video (latest overrides previous)
        deltaTimeHistory.removeAll { $0.videoName == video.name }

        // Add new entry at the beginning
        deltaTimeHistory.insert(entry, at: 0)

        // Keep only the last 50 entries to prevent unlimited growth
        if deltaTimeHistory.count > 50 {
            deltaTimeHistory = Array(deltaTimeHistory.prefix(50))
        }

        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(deltaTimeHistory) {
            UserDefaults.standard.set(data, forKey: "deltaTimeHistory")
        }
    }

    private func loadNewVideo(from item: PhotosPickerItem) async {
        isLoadingNewVideo = true

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                print("Failed to load video data")
                isLoadingNewVideo = false
                return
            }

            guard let savedURL = VideoUtils.saveVideoDataToDocuments(data) else {
                print("Failed to save video to documents")
                isLoadingNewVideo = false
                return
            }

            // Get video duration
            let asset = AVAsset(url: savedURL)
            let assetDuration = try await asset.load(.duration)
            let durationSeconds = assetDuration.seconds

            await MainActor.run {
                // Save current delta time to history before switching videos
                if startTime != nil && endTime != nil {
                    saveDeltaTimeToHistory()
                }

                // Update video data
                video = VideoData(
                    url: savedURL,
                    name: item.supportedContentTypes.first?.description ?? "New Video",
                    duration: durationSeconds
                )

                // Reset timestamps for new video
                startTime = nil
                endTime = nil
                duration = nil

                isLoadingNewVideo = false
            }
        } catch {
            print("Error loading new video: \(error)")
            await MainActor.run {
                isLoadingNewVideo = false
            }
        }
    }

    private func setupVideo() {
        // Clean up any existing player first
        cleanupPlayer()

        // Don't create player if in empty state
        guard !isEmptyVideoState else {
            return
        }

        // Create new player
        self.player = AVPlayer(url: video.url)
        self.videoDuration = video.duration ?? 0.0

        // Get the FPS of the video
        self.fps = VideoUtils.getVideoFPS(from: video.url)

        // Add time observer for playback with proper error handling
        guard let player = self.player else { return }

        let interval = CMTime(seconds: 0.033, preferredTimescale: 600)  // ~30fps updates
        self.timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
            time in
            if time.isValid && time.seconds.isFinite && time.seconds >= 0 {
                DispatchQueue.main.async {
                    // Only update currentTime when playing to avoid drift during pause
                    if self.isPlaying {
                        self.currentTime = time.seconds
                    }
                    // Check if video has finished playing (only when actually playing)
                    if self.isPlaying && time.seconds >= self.videoDuration - 0.1 {  // Allow small tolerance
                        self.isPlaying = false
                        self.hasFinishedPlaying = true
                    }
                }
            }
        }

        // Try to get duration from player item with validation
        if let item = player.currentItem {
            let itemDuration = item.duration
            if itemDuration.isValid && !itemDuration.isIndefinite && itemDuration.seconds > 0 {
                self.videoDuration = itemDuration.seconds
            }
        }
    }

    private func loadExistingTimestamps() {
        // Timestamps are already loaded through bindings
        // Set current time to start time if available
        if let start = startTime {
            currentTime = start
            seekToTime(start)
        }
    }

    private func cleanupPlayer() {
        // Stop playback first
        player?.pause()

        // Remove time observer safely
        if let observer = timeObserver, let player = self.player {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }

        // Clear player reference
        player = nil
        isPlaying = false
    }

    private func resetToEmptyState() {
        cleanupPlayer()
        currentTime = 0.0
        videoDuration = 0.0
        isPlaying = false
        hasFinishedPlaying = false
        fps = nil
    }

    #if DEBUG
        private func resetAppData() {
            // Reset onboarding flag to show tutorial again
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

            // Clear delta time history
            UserDefaults.standard.removeObject(forKey: "deltaTimeHistory")
            deltaTimeHistory.removeAll()

            // Reset video state
            resetToEmptyState()

            // Reset timestamps
            startTime = nil
            endTime = nil
            duration = nil

            // Reset video data
            video = VideoData(
                url: URL(string: "about:blank") ?? URL(fileURLWithPath: "/dev/null"),
                name: "",
                duration: 0
            )

            // Post notification to trigger app restart
            NotificationCenter.default.post(name: NSNotification.Name("ResetAppData"), object: nil)
        }
    #endif

    private func togglePlayback() {
        guard let player = player else { return }

        isFrameMode = false

        if hasFinishedPlaying {
            // If video finished, restart from beginning (or startTime if set)
            hasFinishedPlaying = false
            isPlaying = true
            let restartTime = startTime ?? 0.0
            currentTime = restartTime
            let time = CMTime(seconds: restartTime, preferredTimescale: 600)
            player.seek(to: time) { _ in
                player.play()
            }
        } else {
            if isPlaying {
                // Pausing: store the exact current time from the player
                let playerCurrentTime = player.currentTime().seconds
                if playerCurrentTime.isFinite && playerCurrentTime >= 0 {
                    currentTime = playerCurrentTime
                }
                player.pause()
                isPlaying = false
            } else {
                // Resuming: seek to the stored current time before playing
                isPlaying = true
                let time = CMTime(seconds: currentTime, preferredTimescale: 600)
                player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { completed in
                    if completed {
                        player.play()
                    }
                }
            }
        }
    }

    private func previousFrame() {
        isFrameMode = true
        player?.pause()
        isPlaying = false
        hasFinishedPlaying = false

        // Move back by one frame based on actual FPS (fallback to 30fps if unknown)
        let frameRate = fps ?? 30.0
        let frameDuration = 1.0 / Double(frameRate)
        currentTime = max(currentTime - frameDuration, 0)
        seekToTime(currentTime)
    }

    private func nextFrame() {
        isFrameMode = true
        player?.pause()
        isPlaying = false
        hasFinishedPlaying = false

        // Move forward by one frame based on actual FPS (fallback to 30fps if unknown)
        let frameRate = fps ?? 30.0
        let frameDuration = 1.0 / Double(frameRate)
        currentTime = min(currentTime + frameDuration, videoDuration)
        seekToTime(currentTime)
    }

    private func seekToTime(_ time: Double) {
        guard let player = player else { return }

        hasFinishedPlaying = false

        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            // Seek completed
        }
    }

    private func handleTimestampAction() {
        let timeTolerance = 0.1

        // Check if current time is at start time - remove it
        if let start = startTime, abs(currentTime - start) <= timeTolerance {
            startTime = nil
            return
        }

        // Check if current time is at end time - remove it
        if let end = endTime, abs(currentTime - end) <= timeTolerance {
            endTime = nil
            return
        }

        // Simple logic: set start if none, set end if start exists, clear both if both exist
        if startTime == nil {
            // No start time set, set it
            startTime = currentTime
        } else if endTime == nil {
            // Start time exists but no end time, set end time
            endTime = currentTime
        } else {
            // Both times set, clear both and start fresh
            startTime = currentTime
            endTime = nil
        }
    }

    private func saveData() {
        guard let start = startTime, let end = endTime else {
            print(
                "Invalid data for saving: start=\(String(describing: startTime)), end=\(String(describing: endTime))"
            )
            return
        }

        // Calculate and update duration
        let calculatedDuration = abs(end - start)
        duration = calculatedDuration

        // Save to history
        saveDeltaTimeToHistory()

        onDismiss()
    }

    // Get timestamp button SF symbol name
    func getTimestampButtonSymbol() -> String {
        let timeTolerance = 0.1

        // Check if current time is at start time
        if let start = startTime, abs(currentTime - start) <= timeTolerance {
            return "mappin.slash"
        }

        // Check if current time is at end time
        if let end = endTime, abs(currentTime - end) <= timeTolerance {
            return "mappin.slash"
        }

        // Always return mappin for setting timestamps (no replace functionality)
        return "mappin"
    }

    // Check if we're in recording state (have start time and current position is after it)
    func isInRecordingState() -> Bool {
        guard let start = startTime else { return false }
        return currentTime > start && endTime == nil
    }
}

// Format time string with minimum data
func formatTime(_ time: Double) -> String {
    let minutes = Int(time) / 60
    let remainingSeconds = time.truncatingRemainder(dividingBy: 60)

    if minutes > 0 {
        // Show minutes and seconds with milliseconds (e.g., "1m 1.106s")
        return String(format: "%dm %.3fs", minutes, remainingSeconds)
    } else {
        // Show only seconds with milliseconds (e.g., "1.106s")
        return String(format: "%.3fs", remainingSeconds)
    }
}

// Format time string with optional handling
func formatTime(_ time: Double?) -> String {
    guard let time = time else { return "-" }
    return formatTime(time)
}

// Format time for video playback display (m:ss:milliseconds)
func formatVideoTime(_ time: Double) -> String {
    let totalSeconds = Int(time)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)

    return String(format: "%d:%02d:%03d", minutes, seconds, milliseconds)
}

// History view for displaying previous delta times
struct DeltaTimeHistoryView: View {
    let history: [DeltaTimeEntry]
    @Environment(\.dismiss) private var dismiss
    @State private var doneButtonPressed = false

    var body: some View {
        NavigationView {
            VStack {
                if history.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No History Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        Text("Delta times from your videos will appear here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding()
                } else {
                    List(history) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(entry.videoName)
                                    .font(.headline)
                                    .lineLimit(1)
                                Spacer()
                                Text(formatTime(entry.deltaTime))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }

                            HStack {
                                Text("Start: \(formatTime(entry.startTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("End: \(formatTime(entry.endTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Delta Time History")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .scaleEffect(doneButtonPressed ? 0.9 : 1.0)
                    .animation(.smooth(duration: 0.1, extraBounce: 0), value: doneButtonPressed)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !doneButtonPressed {
                                    doneButtonPressed = true
                                }
                            }
                            .onEnded { _ in
                                doneButtonPressed = false
                            }
                    )
                }
            }
        }
    }

}

// Empty state view when no video is selected
struct EmptyVideoStateView: View {
    @Binding var selectedItem: PhotosPickerItem?
    @State private var emptyViewButtonPressed = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Large video icon
            Image(systemName: "video.badge.plus")
                .font(.system(size: 80, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            // Main text
            VStack(spacing: 12) {
                Text("Upload a video")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Click on the photo icon to get started")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            // Upload button
            PhotosPicker(selection: $selectedItem, matching: .videos) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Choose Video")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(25)
            }
            .scaleEffect(emptyViewButtonPressed ? 0.9 : 1.0)
            .animation(.smooth(duration: 0.1, extraBounce: 0), value: emptyViewButtonPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !emptyViewButtonPressed {
                            emptyViewButtonPressed = true
                        }
                    }
                    .onEnded { _ in
                        emptyViewButtonPressed = false
                    }
            )

            Spacer()
        }
    }
}
