//
//  MainAppView.swift
//  physicsapp
//
//  Created by Michelle on 12/21/25.
//

import SwiftUI

struct MainAppView: View {
    @State private var selectedVideo: VideoData?
    @State private var startTime: Double?
    @State private var endTime: Double?
    @State private var duration: Double?
    
    var body: some View {
        
        
        FramePickerView(
            video: Binding(
                get: { 
                    selectedVideo ?? VideoData(
                        url: URL(string: "about:blank") ?? URL(fileURLWithPath: "/dev/null"), 
                        name: "", 
                        duration: 0
                    ) 
                },
                set: { selectedVideo = $0 }
            ),
            startTime: $startTime,
            endTime: $endTime,
            duration: $duration
        ) {
            // onDismiss - not needed since this is the main view
        }
        .onAppear {
            // Ensure we start with empty state
            selectedVideo = nil
            startTime = nil
            endTime = nil
            duration = nil
        }
    }
}

#Preview {
    MainAppView()
        .preferredColorScheme(.dark)
}
