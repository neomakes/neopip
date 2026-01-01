import SwiftUI

struct GoalView: View {
    @ObservedObject var viewModel: GoalViewModel
    
    var body: some View {
        ZStack {
            PrimaryBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Gem Visualization Section
                    GemVizSection(viewModel: viewModel)
                        .padding(.horizontal, 0)
                        .padding(.bottom, 30)
                    
                    // MARK: - Progress Section
                    ProgressSection(viewModel: viewModel)
                        .padding(.horizontal, 0)
                        .padding(.bottom, 30)
                    
                    // MARK: - Programs Section
                    ProgramsSection(viewModel: viewModel)
                        .padding(.horizontal, 0)
                        .padding(.bottom, 100) // TabBar 높이 고려 + 여유 공간
                }
                .frame(maxWidth: .infinity)
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
