import SwiftUI

struct GoalView: View {
    @ObservedObject var viewModel: GoalViewModel
    
    var body: some View {
        ZStack {
            PrimaryBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Gem Visualization Section
                    GemVizSection(viewModel: viewModel)
                    
                    // MARK: - Progress Section
                    ProgressSection(viewModel: viewModel)
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
