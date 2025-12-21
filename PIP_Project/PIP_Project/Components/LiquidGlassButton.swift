//
//  LiquidGlassButton.swift
//  PIP_Project
//
//  Liquid Glass style button component
//  iOS 18 style frosted glass effect with blur and gradient
//

import SwiftUI

// MARK: - Liquid Glass Button
struct LiquidGlassButton: View {
    let icon: String?
    let systemIcon: String?
    let title: String?
    let action: () -> Void
    
    // Customization
    var size: CGFloat = 56
    var cornerRadius: CGFloat = 16
    var tintColor: Color = .white
    var isCircle: Bool = false
    
    init(
        icon: String? = nil,
        systemIcon: String? = nil,
        title: String? = nil,
        size: CGFloat = 56,
        cornerRadius: CGFloat = 16,
        tintColor: Color = .white,
        isCircle: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.systemIcon = systemIcon
        self.title = title
        self.size = size
        self.cornerRadius = cornerRadius
        self.tintColor = tintColor
        self.isCircle = isCircle
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Glass background
                glassBackground
                
                // Content
                content
            }
            .frame(width: title != nil ? nil : size, height: size)
            .frame(minWidth: title != nil ? 100 : size)
        }
        .buttonStyle(LiquidGlassButtonStyle())
    }
    
    private var glassBackground: some View {
        Group {
            if isCircle {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.5, height: size * 0.5)
            } else if let systemIcon = systemIcon {
                Image(systemName: systemIcon)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(tintColor)
            }
            
            if let title = title {
                Text(title)
                    .font(.pip.body)
                    .foregroundColor(tintColor)
            }
        }
        .padding(.horizontal, title != nil ? 20 : 0)
    }
}

// MARK: - Liquid Glass Button Style
struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Liquid Glass Container
struct LiquidGlassContainer<Content: View>: View {
    let cornerRadius: CGFloat
    let content: () -> Content
    
    init(cornerRadius: CGFloat = 20, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

// MARK: - Liquid Glass Tab Bar (Navigation Only)
struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [String]  // Asset names without "icon_" prefix
    
    var body: some View {
        LiquidGlassContainer(cornerRadius: 28) {
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }) {
                        let isSelected = selectedTab == index
                        let assetName = "icon_\(tabs[index])"
                        
                        Image(assetName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .opacity(isSelected ? 1.0 : 0.4)
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3), value: isSelected)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 60)
    }
}

// MARK: - Floating Write Button (Separate from TabBar)
struct FloatingWriteButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.pip.home.buttonAddGrad1.opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                
                // Liquid glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Icon
                Image("icon_write")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            }
        }
        .buttonStyle(LiquidGlassButtonStyle())
    }
}

// MARK: - Preview
#Preview("Liquid Glass Buttons") {
    ZStack {
        LinearGradient(
            colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 24) {
            // Circle button
            LiquidGlassButton(
                systemIcon: "xmark",
                size: 44,
                isCircle: true,
                action: {}
            )
            
            // Icon + Title button
            LiquidGlassButton(
                systemIcon: "checkmark",
                title: "Save",
                size: 48,
                action: {}
            )
            
            // Icon only rounded rect
            LiquidGlassButton(
                systemIcon: "arrow.left",
                size: 56,
                cornerRadius: 16,
                action: {}
            )
            
            // Tab bar + Write button (Notion style)
            HStack(spacing: 12) {
                LiquidGlassTabBar(
                    selectedTab: .constant(0),
                    tabs: ["home", "insight", "goal", "status"]
                )
                
                FloatingWriteButton {
                    print("Write tapped")
                }
            }
            .padding(.horizontal, 16)
        }
        .padding()
    }
}
