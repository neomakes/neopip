import SwiftUI

/// Gem Visualization Info Sheet
///
/// Explains the components and visual meaning of the Goal visualization (Gems).
struct GemInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                PrimaryBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Understanding Your Gems")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Gems represent your active goal programs and your journey through them.")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 8)
                        
                        // MARK: - Visual Components
                        VStack(alignment: .leading, spacing: 16) {
                            SectionTitle(text: "Visual Components")
                            
                            InfoRow(
                                icon: "cube.fill",
                                title: "Gem Shape",
                                description: "Reflects the unique identity of each program."
                            )
                            
                            InfoRow(
                                icon: "sparkles",
                                title: "Radiance & Brightness",
                                description: "Grows brighter as you make progress and improve."
                            )
                            
                            InfoRow(
                                icon: "paintpalette.fill",
                                title: "Theme Color",
                                description: "The core color associated with the program's category."
                            )
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        // MARK: - Interaction & Meaning
                        VStack(alignment: .leading, spacing: 16) {
                            SectionTitle(text: "Interaction")
                            
                            MeaningRow(
                                label: "Center Gem",
                                meaning: "Currently Selected",
                                detail: "Tap to view the program description."
                            )
                            
                            MeaningRow(
                                label: "Swiping",
                                meaning: "Navigation",
                                detail: "Swipe left or right to switch between your enrolled programs."
                            )
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        // MARK: - Data Source
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(text: "Data Source")
                            
                            Text("Your Gems are generated from:")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                BulletPoint(text: "Your active program enrollments")
                                BulletPoint(text: "Daily mission completion progress")
                                BulletPoint(text: "Overall program consistency")
                            }
                        }
                        
                        // MARK: - Bottom Note
                        VStack(alignment: .leading, spacing: 8) {
                            Text("💡 Tip")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Keep your streaks alive to make your Gems shine their brightest!")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct SectionTitle: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)
    }
}

private struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.teal)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct MeaningRow: View {
    let label: String
    let meaning: String
    let detail: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.teal)
                
                Spacer()
                
                Text(meaning)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text(detail)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

private struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.teal)
            
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    GemInfoSheet()
}
