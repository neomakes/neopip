import SwiftUI

/// Orb 시각화 설명 시트
///
/// Orb의 구성 요소와 시각적 의미를 설명하는 정보 시트
struct OrbInfoSheet: View {
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
                            Text("Understanding Your Orb")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Your Orb is a unique visualization of your data patterns and analysis insights")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 8)
                        
                        // MARK: - Orb Components
                        VStack(alignment: .leading, spacing: 16) {
                            SectionTitle(text: "Orb Components")
                            
                            InfoRow(
                                icon: "circle.fill",
                                title: "Base Liquid Orb",
                                description: "The foundation image that represents your data sphere"
                            )
                            
                            InfoRow(
                                icon: "circle.lefthalf.filled",
                                title: "Radial Gradient Overlay",
                                description: "Brightness represents prediction accuracy - brighter means more accurate predictions"
                            )
                            
                            InfoRow(
                                icon: "paintpalette.fill",
                                title: "Linear Gradient Overlay",
                                description: "Color gradient based on your unique features and characteristics"
                            )
                            
                            InfoRow(
                                icon: "circle.dotted",
                                title: "Border Brightness",
                                description: "Represents prediction uncertainty - dimmer border means higher uncertainty"
                            )
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        // MARK: - Visual Meaning
                        VStack(alignment: .leading, spacing: 16) {
                            SectionTitle(text: "Visual Meaning")
                            
                            MeaningRow(
                                label: "Brightness",
                                meaning: "Model's prediction accuracy",
                                detail: "Higher brightness = More confident predictions"
                            )
                            
                            MeaningRow(
                                label: "Border Brightness",
                                meaning: "Prediction uncertainty",
                                detail: "Brighter border = Lower uncertainty"
                            )
                            
                            MeaningRow(
                                label: "Color Gradient",
                                meaning: "Your unique characteristics",
                                detail: "Colors derived from your personal data patterns"
                            )
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        // MARK: - Data Source
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(text: "Data Source")
                            
                            Text("Your Orb is generated from:")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                BulletPoint(text: "Weekly and monthly data patterns")
                                BulletPoint(text: "Analysis results from your data")
                                BulletPoint(text: "Time series analysis of your recorded data")
                                BulletPoint(text: "Patterns extracted from your behavior")
                            }
                        }
                        
                        // MARK: - Bottom Note
                        VStack(alignment: .leading, spacing: 8) {
                            Text("💡 Note")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("As you record more data, your Orb will become more accurate and personalized, reflecting your unique patterns and helping predict future trends.")
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
    OrbInfoSheet()
}
