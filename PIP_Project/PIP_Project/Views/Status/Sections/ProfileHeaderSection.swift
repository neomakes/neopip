// PIP_Project/PIP_Project/Views/Status/Sections/ProfileHeaderSection.swift
import SwiftUI

// MARK: - Profile Header Section
struct ProfileHeaderSection: View {
    @ObservedObject var viewModel: StatusViewModel
    @Binding var path: NavigationPath
    
    var body: some View {
        VStack(spacing: 0) {
            // Background section with settings and greeting
            VStack(spacing: 4) {
                // Settings button in top-right
                HStack {
                    Spacer()
                    Button(action: {
                        path.append(StatusRoute.settings)
                    }) {
                        Image("icon_setting")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 16)
                
                // Greeting
                Text("Hi \(viewModel.userProfile?.displayName ?? "NEO")!")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        randomColor()
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .ignoresSafeArea(edges: .horizontal)
            
            // Profile image
            VStack(spacing: 0) {
                if let profileImageName = viewModel.userProfile?.profileImageURL {
                    Image(profileImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.top, -75)
        }
    }
    
    private func randomColor() -> Color {
        let colors: [Color] = [
            Color(red: 0.5, green: 0.85, blue: 0.85),
            Color(red: 0.8, green: 0.4, blue: 0.6),
            Color(red: 0.4, green: 0.7, blue: 0.9),
            Color(red: 0.6, green: 0.5, blue: 0.8),
            Color(red: 0.3, green: 0.8, blue: 0.6)
        ]
        return colors.randomElement() ?? Color(red: 0.5, green: 0.85, blue: 0.85)
    }
}