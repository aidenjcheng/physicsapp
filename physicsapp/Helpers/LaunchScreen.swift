//
//  LaunchScreen.swift
//  physicsapp
//
//  Created by Michelle on 12/22/25.
//

import SwiftUI

struct LaunchScreen<RootView: View, Logo: View>: Scene {
    var config: LaunchScreenConfig

    @ViewBuilder var logo: () -> Logo
    @ViewBuilder var rootContent: () -> RootView

    init(
        config: LaunchScreenConfig = LaunchScreenConfig(), @ViewBuilder logo: @escaping () -> Logo,
        @ViewBuilder rootContent: @escaping () -> RootView
    ) {
        self.config = config
        self.logo = logo
        self.rootContent = rootContent
    }

    var body: some Scene {
        WindowGroup {
            rootContent()
                .modifier(LaunchScreenModifier(config: config, logo: logo))
        }
    }
}

private struct LaunchScreenModifier<Logo: View>: ViewModifier {
    var config: LaunchScreenConfig
    @ViewBuilder var logo: () -> Logo
    @Environment(\.scenePhase) private var scenePhase
    @State private var splashWindow: UIWindow?

    func body(content: Content) -> some View {
        content
            .onAppear {
                let scenes = UIApplication.shared.connectedScenes

                for scene in scenes {
                    guard let windowScene = scene as? UIWindowScene,
                        checkStates(windowScene.activationState),
                        !windowScene.windows.contains(where: { $0.tag == 1009 })
                    else {
                        print("Already have a splash window for this scene")
                        continue
                    }

                    let window = UIWindow(windowScene: windowScene)
                    window.tag = 1009
                    window.backgroundColor = .clear
                    window.isHidden = false
                    window.isUserInteractionEnabled = true

                    let rootViewController = UIHostingController(
                        rootView: LaunchScreenView(config: config) {
                            logo()
                        } isCompleted: {
                            window.isHidden = true
                            window.isUserInteractionEnabled = false
                        })
                    rootViewController.view.backgroundColor = .clear
                    window.rootViewController = rootViewController

                    self.splashWindow = window
                    print("splash window added")
                }
            }
    }

    private func checkStates(_ state: UIScene.ActivationState) -> Bool {
        switch scenePhase {
        case .active: return state == .foregroundActive
        case .inactive: return state == .foregroundInactive
        case .background: return state == .background
        default: return state.hashValue == scenePhase.hashValue
        }
    }
}

struct LaunchScreenConfig {
    var initialDelay: Double = 0.35
    var backgroundColor: Color = .black
    var logoBackgroundColor: Color = .white
    var scaling: CGFloat = 4
    var forceHideLogo: Bool = false
    var animation: Animation = .smooth(duration: 0.3, extraBounce: 0)
}

private struct LaunchScreenView<Logo: View>: View {
    var config: LaunchScreenConfig
    @ViewBuilder var logo: () -> Logo
    @State private var scaleDown: Bool = false
    @State private var scaleUp: Bool = false
    var isCompleted: () -> Void

    var body: some View {
        Rectangle()
            .fill(config.backgroundColor)
            .mask {
                GeometryReader { geometry in
                    let size = geometry.size.applying(
                        .init(scaleX: config.scaling, y: config.scaling))

                    Rectangle()
                        .overlay {
                            logo()
                                .blendMode(.destinationOut)
                                .animation(.smooth(duration: 0.3, extraBounce: 0)) { content in
                                    content.scaleEffect(scaleDown ? 0.8 : 1)
                                }
                                .visualEffect { [scaleUp] content, proxy in
                                    let scaleX: CGFloat = size.width / proxy.size.width
                                    let scaleY: CGFloat = size.height / proxy.size.height
                                    let maxScale = Swift.max(scaleX, scaleY)

                                    return
                                        content
                                        .scaleEffect(scaleUp ? maxScale : 1)
                                }
                        }
                }
            }
            .background {
                Rectangle()
                    .fill(config.logoBackgroundColor)
                    .opacity(scaleUp ? 0 : 1)
            }
            .ignoresSafeArea()
            .task {
                guard !scaleDown else { return }
                try? await Task.sleep(for: .seconds(config.initialDelay))
                scaleDown = true
                try? await Task.sleep(for: .seconds(0.1))
                withAnimation(config.animation, completionCriteria: .logicallyComplete) {
                    scaleUp = true
                } completion: {
                    isCompleted()
                }
            }
    }
}
