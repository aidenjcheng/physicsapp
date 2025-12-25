//
//  VideoTimestampView.swift
//  physicsapp
//
//  Created by Michelle on 12/14/25.
//

import AVFoundation
import PhotosUI
import SwiftUI

struct VideoTimestampView: View {
    @Binding var selectedVideo: VideoData?
    @Binding var startTime: Double?
    @Binding var endTime: Double?
    @Binding var duration: Double?

    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var showingFramePicker = false
    @State private var showingPhotosPicker = false

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)

            VStack(spacing: 32) {
                // Title
                Text("Video Timestamp Collector")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color("Shark"))
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)

                // Video selection/upload area
                VStack(spacing: 20) {
                    if let video = selectedVideo, let start = startTime, let end = endTime,
                        let calculatedDuration = duration
                    {
                        // Results display
                        VStack(spacing: 16) {
                            VStack(spacing: 12) {
                                HStack(spacing: 20) {
                                    VStack(spacing: 4) {
                                        Text("Start")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                        Text(String(format: "%.2fs", start))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.blue)
                                    }

                                    VStack(spacing: 4) {
                                        Text("End")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                        Text(String(format: "%.2fs", end))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.blue)
                                    }

                                    VStack(spacing: 4) {
                                        Text("Duration")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                        Text(String(format: "%.2fs", calculatedDuration))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.green)
                                    }
                                }

                                // Adjust timestamps button
                                Button(action: {
                                    showingFramePicker = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "timer")
                                        Text("Adjust Timestamps")
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)

                            // Select new video button
                            Button(action: {
                                showingPhotosPicker = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Select Different Video")
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                    } else {
                        // No video selected - show upload prompt
                        VStack(spacing: 20) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 120)

                                VStack(spacing: 8) {
                                    Image(systemName: "video.badge.plus")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)

                                    Text("No video selected")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            }

                            Button(action: {
                                showingPhotosPicker = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Select Video")
                                }
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .photosPicker(
            isPresented: $showingPhotosPicker, selection: $selectedVideoItem, matching: .videos
        )
        .onChange(of: selectedVideoItem) { _, newItem in
            if let item = newItem {
                saveVideoFromPhotos(item: item)
            }
        }
        .fullScreenCover(isPresented: $showingFramePicker) {
            if selectedVideo != nil {
                FramePickerView(
                    video: Binding(
                        get: { selectedVideo ?? VideoData(url: URL(string: "about:blank") ?? URL(fileURLWithPath: "/dev/null"), name: "", duration: 0) },
                        set: { selectedVideo = $0 }
                    ),
                    startTime: $startTime,
                    endTime: $endTime,
                    duration: $duration
                ) {
                    showingFramePicker = false
                }
            }
        }
    }

    private func saveVideoFromPhotos(item: PhotosPickerItem) {
        // Immediately show frame picker with loading state
        let placeholderVideo = VideoData(
            url: URL(fileURLWithPath: ""),  // Empty URL indicates loading
            name: "Loading Video...",
            duration: nil
        )

        selectedVideo = placeholderVideo
        startTime = nil
        endTime = nil
        duration = nil
        selectedVideoItem = nil
        showingFramePicker = true

        // Process video in background
        Task {
            do {
                guard let videoData = try await item.loadTransferable(type: Data.self) else {
                    print("Could not load video data")
                    await MainActor.run {
                        showingFramePicker = false
                        selectedVideo = nil
                    }
                    return
                }

                guard let videoURL = VideoUtils.saveVideoDataToDocuments(videoData) else {
                    print("Could not save video to documents")
                    await MainActor.run {
                        showingFramePicker = false
                        selectedVideo = nil
                    }
                    return
                }

                // Get video duration
                let asset = AVURLAsset(url: videoURL)
                var videoDuration: Double = 5.0  // Default fallback

                do {
                    let duration = try await asset.load(.duration)
                    if duration.isValid && !duration.isIndefinite && duration.seconds > 0 {
                        videoDuration = duration.seconds
                    }
                } catch {
                    print("Error loading video duration: \(error)")
                }

                let videoName = "Selected Video"
                let videoDataObj = VideoData(
                    url: videoURL, name: videoName, duration: videoDuration)

                await MainActor.run {
                    // Update the video data - this will refresh the frame picker
                    selectedVideo = videoDataObj
                }
            } catch {
                print("Error saving video: \(error)")
                await MainActor.run {
                    showingFramePicker = false
                    selectedVideo = nil
                    selectedVideoItem = nil
                }
            }
        }
    }
}
