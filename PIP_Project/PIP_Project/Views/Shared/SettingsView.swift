// PIP_Project/PIP_Project/Views/Shared/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Binding var path: NavigationPath
    
    var body: some View {
        List {
            Section(header: Text("Legal").foregroundColor(.gray)) {
                Button(action: {
                    path.append(StatusRoute.licenses)
                }) {
                    Label("Open Source Licenses", systemImage: "text.book.closed.fill")
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            
            Section(header: Text("Device Info").foregroundColor(.gray)) {
                LabeledContent("Version", value: "1.0.0 (Build 2025)")
                    .listRowBackground(Color.white.opacity(0.05))
            }
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}