//
//  OnboardingView.swift
//  physicsapp
//
//  Created by Michelle on 12/21/25.
//

import AVFoundation
import AVKit
import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    @State private var backButtonPressed = false
    @State private var nextButtonPressed = false

    private let pages = [
        OnboardingPage(
            title: "Find the exact change in time",
            description:
                "Measure the exact time difference between two points in a video. Perfect for physics labs.",
            // imageName: "stopwatch",
            color: .blue,
            videoName: "timestamp_edited"  // Add your video file name without extension
        ),
        OnboardingPage(
            title: "Move frame by frame",
            description:
                "Move frame by frame to find the exact time difference with auto-detected FPS.",
            // imageName: "photo.on.rectangle.angled",
            color: .green,
            videoName: "frame_by_frame_edited"
        ),
        OnboardingPage(
            title: "Quickly change videos",
            description:
                "Use the top upload button to quickly change videos.",
            // imageName: "mappin",
            color: .yellow,
            videoName: "change_video_edited"
        ),
        OnboardingPage(
            title: "Check previous measurements",
            description:
                "See the calculated time difference and access your measurement history from previous videos.",
            // imageName: "clock.arrow.circlepath",
            color: .purple,
            videoName: "check_history_edited"
        ),
    ]

    var body: some View {
        VStack {
            // Page indicator
            //            HStack(spacing: 8) {
            //                ForEach(0..<pages.count, id: \.self) { index in
            //                    Circle()
            //                        .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
            //                        .frame(width: 8, height: 8)
            //                        .animation(.easeInOut(duration: 0.3), value: currentPage)
            //                }
            //            }
            //            .padding(.top, 50)
            //
            // Tab view for pages
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())

            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage -= 1
                        }
                    }
                    .foregroundStyle(.white.opacity(0.7))
                    .fontWeight(.medium)
                    .scaleEffect(backButtonPressed ? 0.9 : 1.0)
                    .animation(.smooth(duration: 0.1, extraBounce: 0), value: backButtonPressed)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !backButtonPressed {
                                    backButtonPressed = true
                                }
                            }
                            .onEnded { _ in
                                backButtonPressed = false
                            }
                    )
                } else {
                    Spacer()
                }

                Spacer()

                let notLastPage: Bool = currentPage < (pages.count - 1)

                Button {
                    if notLastPage {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    } else {
                        // Mark onboarding as completed
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        showOnboarding = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(notLastPage ? "Next" : "Get Started")
                            .contentTransition(.numericText())
                        Image(systemName: "chevron.right")
                    }
                }
                .foregroundColor(.black)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .padding(.trailing, 12)
                .padding(.leading, 12)
                .background(.white, in: .capsule)
                .fontWeight(.semibold)
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
            .padding(.horizontal, 20)
            //            .padding(.bottom, 0)
        }

    }
}

struct OnboardingPage {
    let title: String
    let description: String
    // let imageName: String
    let color: Color
    let videoName: String?  // Optional video file name
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var player: AVPlayer?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Video Player
            if let videoName = page.videoName {
                OnboardingVideoPlayer(videoName: videoName)
                    .frame(maxWidth: .infinity, maxHeight: 700)
                    .padding(.horizontal, 20)
            }

            // Title
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)

            Spacer().frame(maxHeight: 60)
        }
    }
}

struct OnboardingVideoPlayer: View {
    let videoName: String
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onAppear {
                        // Auto-play and loop the video
                        player.play()

                        // Set up looping
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player.currentItem,
                            queue: .main
                        ) { _ in
                            player.seek(to: .zero)
                            player.play()
                        }
                    }
                    .onDisappear {
                        player.pause()
                        NotificationCenter.default.removeObserver(self)
                    }
            } else {
                // Fallback placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        VStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.6))
                            Text("Demo Video")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.caption)
                        }
                    )
            }
        }
        .onAppear {
            setupPlayer()
        }
    }

    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            print("Could not find video file: \(videoName).mp4")
            return
        }

        player = AVPlayer(url: url)
        player?.isMuted = true  // Mute for better UX in onboarding
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}
