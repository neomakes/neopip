import SwiftUI

struct InsightView: View {
    @StateObject private var viewModel = InsightViewModel()
    
    var body: some View {
        ZStack {
            PrimaryBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Orb Visualization Section
                    VStack(spacing: 16) {
                        if let orbViz = viewModel.orbVisualization {
                            OrbView(
                                brightness: orbViz.brightness,
                                borderBrightness: orbViz.borderBrightness,
                                complexity: orbViz.complexity,
                                uncertainty: orbViz.uncertainty,
                                colorGradient: orbViz.colorGradient
                            )
                        } else {
                            ProgressView()
                                .frame(height: 240)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    // MARK: - Dashboard Section
                    DashboardSection(viewModel: viewModel)
                        .padding(.bottom, 15)
                    
                    // MARK: - Analysis Section
                    AnalysisSection(viewModel: viewModel)
                        .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            viewModel.loadInitialData()
        }
    }
}

#Preview {
    InsightView()
}
