//
//  OnboardingView.swift
//  physicsapp
//
//  Created by Michelle on 12/21/25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    
    private let pages = [
        OnboardingPage(
            title: "Welcome to Physics Timer",
            description: "Measure precise time intervals in your videos with frame-by-frame accuracy.",
            imageName: "stopwatch",
            color: .blue
        ),
        OnboardingPage(
            title: "Upload Your Video",
            description: "Tap the photo icon to select a video from your library. The app supports all common video formats.",
            imageName: "photo.on.rectangle.angled",
            color: .green
        ),
        OnboardingPage(
            title: "Set Timestamps",
            description: "Use the yellow pin button to mark start and end points. Navigate frame-by-frame for precision.",
            imageName: "mappin",
            color: .yellow
        ),
        OnboardingPage(
            title: "View Your Results",
            description: "See the calculated time difference and access your measurement history anytime.",
            imageName: "clock.arrow.circlepath",
            color: .purple
        )
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
                } else {
                    Spacer()
                }
                
                Spacer()
                

                    let notLastPage: Bool = currentPage < (pages.count - 1)
                    
                    Button {
                        if (notLastPage){
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }} else {
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
                    .background(.white, in:.capsule)
                    .fontWeight(.semibold)
                }
            .padding(.horizontal, 20)
//            .padding(.bottom, 0)
        }
       
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 15) {
            Spacer()
            
//            video here
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

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}
