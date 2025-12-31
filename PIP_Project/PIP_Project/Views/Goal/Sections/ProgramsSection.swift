import SwiftUI

struct ProgramsSection: View {
    @ObservedObject var viewModel: GoalViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Header
            HStack {
                Text("Programs")
                    .font(.pip.title2)
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: {
                    Text("View All Programs")
                }) {
                    Text("View All")
                        .font(.pip.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 16)
            
            // MARK: - Program List
            VStack(spacing: 12) {
                // Display ongoing programs
                ForEach(viewModel.ongoingPrograms.indices, id: \.self) { index in
                    let program = viewModel.ongoingPrograms[index]
                    if let progress = viewModel.programProgress[program.id.uuidString] {
                        ProgramRowView(program: program, progress: progress)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    ProgramsSection(viewModel: GoalViewModel())
        .background(Color.black)
}

// MARK: - Program Row View
struct ProgramRowView: View {
    let program: Program
    let progress: ProgramProgress
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
            
            HStack(spacing: 12) {
                // Program icon based on gem type
                Image(systemName: gemIcon(for: program.gemVisualization.gemType))
                    .foregroundColor(.accentColor)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(.pip.body)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(program.category.rawValue.capitalized) · \(program.duration) days")
                        .font(.pip.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(progress.improvementRate * 100))%")
                        .font(.pip.body)
                        .foregroundColor(.accentColor)
                    
                    Text("Day \(progress.progressHistory.count)")
                        .font(.pip.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(12)
        }
    }
    
    private func gemIcon(for gemType: GemTypeForGoal) -> String {
        switch gemType {
        case .diamond: return "diamond.fill"
        case .sphere: return "circle.fill"
        case .crystal: return "sparkles"
        case .prism: return "square.fill"
        case .custom: return "star.fill"
        }
    }
}
