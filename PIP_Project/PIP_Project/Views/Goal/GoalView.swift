import SwiftUI

struct GoalView: View {
    @ObservedObject var viewModel: GoalViewModel
    
    var body: some View {
        ZStack {
            PrimaryBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Goal Header
                    if let selectedGoal = viewModel.selectedGoal {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedGoal.title)
                                        .font(.pip.title2)
                                        .foregroundColor(.white)
                                    
                                    if let desc = selectedGoal.description {
                                        Text(desc)
                                            .font(.pip.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(2)
                                    }
                                }
                                
                                Spacer()
                                
                                // Goal Progress Ring
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 3)
                                    
                                    Circle()
                                        .trim(from: 0, to: selectedGoal.progress)
                                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                        .rotationEffect(.degrees(-90))
                                    
                                    Text(String(format: "%.0f%%", selectedGoal.progress * 100))
                                        .font(.pip.overline)
                                        .foregroundColor(.accentColor)
                                        .lineLimit(1)
                                }
                                .frame(width: 60, height: 60)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
                .padding(.top, 16)
            }
        }
        .onAppear {
            viewModel.loadInitialData()
        }
    }
}

#Preview {
    GoalView(viewModel: GoalViewModel())
}
