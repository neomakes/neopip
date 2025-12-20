//
//  StatusView.swift
//  PIP_Project
//
//  Created by NEO on 12/20/25.
//

import SwiftUI

// MARK: - Navigation Route
enum AppRoute: Hashable {
    case settings
    case licenses
}

struct StatusView: View {
    // Manage navigation state
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 25) {
                // Status Content Area
                Image(systemName: "bolt.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.yellow)
                
                Text("System Operational")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Navigation Button to Settings
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
                    .background(Color.blue)
                    .cornerRadius(15)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Status")
            // Navigation Router
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .settings:
                    SettingsView(path: $path)
                case .licenses:
                    LicenseView()
                }
            }
        }
    }
}

struct SettingsView: View {
    @Binding var path: NavigationPath
    
    var body: some View {
        List {
            Section(header: Text("Legal")) {
                Button(action: {
                    path.append(AppRoute.licenses)
                }) {
                    Label("Open Source Licenses", systemImage: "text.book.closed.fill")
                }
            }
            
            Section(header: Text("Device Info")) {
                LabeledContent("Version", value: "1.0.0 (Build 2025)")
            }
        }
        .navigationTitle("Settings")
    }
}

struct LicenseView: View {
    var body: some View {
        List(LicenseData.items) { item in
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.headline)
                
                Text("Author: \(item.author)")
                    .font(.subheadline)
                
                HStack {
                    Text(item.licenseType)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    if let url = URL(string: item.url) {
                        Link("Source", destination: url)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Licenses")
    }
}

#Preview {
    StatusView()
}
