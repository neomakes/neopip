import SwiftUI

struct InsightView: View {
    @ObservedObject var viewModel: InsightViewModel
    
    var body: some View {
        ZStack {
            PrimaryBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Orb Visualization Section
                    OrbVizSection(viewModel: viewModel)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 80)
                    
                    // MARK: - Dashboard Section
                    DashboardSection(viewModel: viewModel)
                        .padding(.horizontal, 0)
                        .padding(.bottom, 20)
                    
                    // MARK: - Analysis Section
                    AnalysisSection(viewModel: viewModel)
                        .padding(.horizontal, 0)
                        .padding(.bottom, 110) // TabBar 높이 고려 + 여유 공간
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
    InsightView(viewModel: InsightViewModel())
}
