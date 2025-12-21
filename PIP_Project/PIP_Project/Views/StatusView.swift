// Location: Views/StatusView.swift
import SwiftUI

enum AppRoute: Hashable {
    case settings
    case licenses
}

struct StatusView: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 25) {
                Spacer()
                
                Image(systemName: "bolt.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.yellow)
                
                Text("System Operational")
                    .font(.pip.hero)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Clicking this will push SettingsView onto the stack
                Button(action: {
                    path.append(AppRoute.settings)
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("Open Settings")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(15)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Status")
            .background(Color.clear) // Essential for transparency
            .scrollContentBackground(.hidden)
            // This handles the transition to sub-pages
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .settings:
                    SettingsView(path: $path)
                case .licenses:
                    LicenseView()
                }
            }
        }
        .background(Color.clear)
        .onAppear {
            setNavigationTransparency()
        }
    }
    
    // Forces the system NavigationBar to be transparent
    private func setNavigationTransparency() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
struct SettingsView: View {
    @Binding var path: NavigationPath
    
    var body: some View {
        List {
            Section(header: Text("Legal").foregroundColor(.gray)) {
                Button(action: {
                    path.append(AppRoute.licenses)
                }) {
                    Label("Open Source Licenses", systemImage: "text.book.closed.fill")
                }
                .listRowBackground(Color.white.opacity(0.05)) // Subtle row tint
            }
            
            Section(header: Text("Device Info").foregroundColor(.gray)) {
                LabeledContent("Version", value: "1.0.0 (Build 2025)")
                    .listRowBackground(Color.white.opacity(0.05))
            }
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden) // Critical for transparency
        .background(Color.clear)
    }
}

struct LicenseView: View {
    var body: some View {
        List(LicenseData.items) { item in
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Author: \(item.author)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Text(item.licenseType)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    if let url = URL(string: item.url) {
                        Link("Source", destination: url)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .listRowBackground(Color.white.opacity(0.05))
        }
        .navigationTitle("Licenses")
        .scrollContentBackground(.hidden) // Critical for transparency
        .background(Color.clear)
    }
}

#Preview {
    StatusView()
}
