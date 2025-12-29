// PIP_Project/PIP_Project/Views/Status/Sections/ValuesSection.swift
import SwiftUI

// MARK: - Values Section
struct ValuesSection: View {
    let valueAnalysis: ValueAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(alignment: .center, spacing: 6) {
                    Image("title_logo_3")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                    
                    Text("Values")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 20) {
                ForEach(valueAnalysis.topValues.prefix(3), id: \.id) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 8) {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                
                                GeometryReader { geometry in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(getColorForValue(item.score))
                                        .frame(width: geometry.size.width * item.score, alignment: .leading)
                                }
                            }
                            .frame(height: 8)
                            
                            Text(String(format: "%.0f%%", item.score * 100))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.gray)
                                .frame(width: 30)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            
            // Comparison info
            if let comparison = valueAnalysis.comparisonData {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Compared to others")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Percentile")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                            
                            Text(String(format: "%.1f%%", comparison.userPercentile))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Divider()
                            .foregroundColor(.white.opacity(0.2))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Average Score")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                            
                            Text(String(format: "%.2f", comparison.averageScore))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(8)
                .padding(.horizontal, 16)
            }
        }
    }
    
    private func getColorForValue(_ value: Double) -> Color {
        switch value {
        case 0.8...:
            return Color(red: 0.3, green: 0.8, blue: 0.6)
        case 0.6...:
            return Color(red: 0.8, green: 0.7, blue: 0.3)
        default:
            return Color(red: 0.8, green: 0.4, blue: 0.3)
        }
    }
}
