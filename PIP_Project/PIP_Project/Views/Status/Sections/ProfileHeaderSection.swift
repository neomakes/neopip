// PIP_Project/PIP_Project/Views/Status/Sections/ProfileHeaderSection.swift
import SwiftUI
import PhotosUI

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
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image("icon_setting")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 8)
                }
                // Greeting
                Text("Hi \(viewModel.userProfile?.displayName ?? "NEO")!")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 0)
                Spacer()
            }
            .frame(height: 130)
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
            // PhotosPicker Disabled: Storage Billing Issue
            VStack(spacing: 0) {
                if let profileURLString = viewModel.userProfile?.profileImageURL,
                   let url = URL(string: profileURLString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 75, height: 75)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 75, height: 75)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                        case .failure:
                            Image(systemName: "person.fill") // Fallback on failure
                                .resizable()
                                .scaledToFit()
                                .padding(15)
                                .frame(width: 75, height: 75)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    // Default Placeholder
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 75, height: 75)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        )
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.top, -50)
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