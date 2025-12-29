// PIP_Project/PIP_Project/Views/Shared/LicenseView.swift
import SwiftUI

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
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}