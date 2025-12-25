//
//  ContentView.swift
//  physicsapp
//
//  Created by Michelle on 9/13/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedVideo: VideoData?
    @State private var startTime: Double?
    @State private var endTime: Double?
    @State private var duration: Double?

    var body: some View {
        VideoTimestampView(
            selectedVideo: $selectedVideo,
            startTime: $startTime,
            endTime: $endTime,
            duration: $duration
        )
    }
}

#Preview {
    ContentView()
}
