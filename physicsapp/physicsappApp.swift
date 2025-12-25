//
//  physicsappApp.swift
//  physicsapp
//
//  Created by Michelle on 9/13/25.
//

import SwiftUI

@main
struct physicsappApp: App {
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some Scene {
        LaunchScreen() {
            Image(.launchScreenLogo)
        } rootContent: {
            Group {
                if showOnboarding {
                    OnboardingView(showOnboarding: $showOnboarding)
                        .fontDesign(.rounded)
                } else {
                    MainAppView()
                        .fontDesign(.rounded)
                }
            }
            .preferredColorScheme(.dark)
            #if DEBUG
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetAppData"))) { _ in
                // Reset onboarding state to show tutorial again
                showOnboarding = true
            }
            #endif
        }
    }
}
