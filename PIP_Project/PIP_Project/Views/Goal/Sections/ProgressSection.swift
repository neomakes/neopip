import SwiftUI

struct ProgressSection: View {
    @ObservedObject var viewModel: GoalViewModel
    @State private var showProgramStory = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Header
            HStack {
                Text("Progress")
                    .font(.pip.title2)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // MARK: - 2 Column Layout
            HStack(alignment: .top, spacing: 16) {
                // MARK: - Left Column (1/3): Program Card + Stories + Radar Chart
                VStack(spacing: 12) {
                    // Program Card with Tab Navigation
                    if !viewModel.ongoingPrograms.isEmpty {
                        ProgressProgramCardView(
                            program: viewModel.ongoingPrograms[viewModel.currentProgramIndex],
                            progress: viewModel.currentProgramProgress(),
                            onTap: {
                                showProgramStory = true
                            }
                        )
                        
                        // Paging Indicator (dots)
                        HStack(spacing: 6) {
                            ForEach(0..<viewModel.ongoingPrograms.count, id: \.self) { index in
                                Circle()
                                    .fill(index == viewModel.currentProgramIndex ? Color.accentColor : Color.gray.opacity(0.5))
                                    .frame(width: 6, height: 6)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        
                        // Navigation Controls
                        HStack(spacing: 8) {
                            Button(action: { viewModel.selectPreviousProgram() }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .disabled(viewModel.currentProgramIndex == 0)
                            .opacity(viewModel.currentProgramIndex == 0 ? 0.5 : 1.0)
                            
                            Spacer()
                            
                            Button(action: { viewModel.selectNextProgram() }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .disabled(viewModel.currentProgramIndex >= viewModel.ongoingPrograms.count - 1)
                            .opacity(viewModel.currentProgramIndex >= viewModel.ongoingPrograms.count - 1 ? 0.5 : 1.0)
                        }
                        .padding(.horizontal, 4)
                        
                        // Radar Chart (Before vs After Metrics)
                        if let progress = viewModel.currentProgramProgress() {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Metrics Improvement")
                                    .font(.pip.caption)
                                    .foregroundColor(.gray)
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                    
                                    VStack {
                                        // Simple radar chart placeholder
                                        // Actual RadarChart component to be implemented separately
                                        VStack(spacing: 8) {
                                            ForEach(progress.radarChartData, id: \.id) { point in
                                                HStack {
                                                    Text(point.label)
                                                        .font(.pip.caption)
                                                        .foregroundColor(.white)
                                                        .frame(width: 50, alignment: .leading)
                                                    
                                                    GeometryReader { geometry in
                                                        ZStack(alignment: .leading) {
                                                            RoundedRectangle(cornerRadius: 2)
                                                                .fill(Color.gray.opacity(0.3))
                                                            
                                                            RoundedRectangle(cornerRadius: 2)
                                                                .fill(
                                                                    LinearGradient(
                                                                        gradient: Gradient(colors: [
                                                                            Color.accentColor.opacity(0.6),
                                                                            Color.accentColor
                                                                        ]),
                                                                        startPoint: .leading,
                                                                        endPoint: .trailing
                                                                    )
                                                                )
                                                                .frame(width: geometry.size.width * point.improvement.clamped(to: 0...1))
                                                        }
                                                    }
                                                    .frame(height: 8)
                                                    
                                                    HStack(spacing: 4) {
                                                        Text(String(format: "%.0f%%", point.beforeValue * 100))
                                                            .font(.pip.caption)
                                                            .foregroundColor(.gray)
                                                        
                                                        Text("→")
                                                            .font(.pip.caption)
                                                            .foregroundColor(.gray)
                                                        
                                                        Text(String(format: "%.0f%%", point.afterValue * 100))
                                                            .font(.pip.caption)
                                                            .foregroundColor(.accentColor)
                                                    }
                                                    .frame(width: 70)
                                                }
                                            }
                                        }
                                        .padding(12)
                                    }
                                }
                                .frame(height: 160)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                // MARK: - Right Column (2/3): Bar Line Chart
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Progress")
                            .font(.pip.caption)
                            .foregroundColor(.gray)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                            
                            if let progress = viewModel.currentProgramProgress() {
                                VStack(alignment: .leading, spacing: 16) {
                                    // Simple BarLineChart simulation
                                    GeometryReader { geometry in
                                        VStack(alignment: .leading, spacing: 12) {
                                            // Chart area
                                            ZStack(alignment: .bottomLeading) {
                                                // Background grid
                                                VStack(spacing: 0) {
                                                    ForEach(0..<5, id: \.self) { _ in
                                                        Divider()
                                                            .background(Color.white.opacity(0.1))
                                                        Spacer()
                                                    }
                                                }
                                                
                                                // Chart data (last 7 days)
                                                let recentData = progress.progressHistory.prefix(7).reversed()
                                                
                                                HStack(alignment: .bottom, spacing: 0) {
                                                    ForEach(Array(recentData.enumerated()), id: \.element.id) { index, point in
                                                        VStack(alignment: .center, spacing: 4) {
                                                            // Goal Progress Bar (blue)
                                                            VStack {
                                                                Spacer()
                                                                RoundedRectangle(cornerRadius: 2)
                                                                    .fill(Color.blue.opacity(0.7))
                                                                    .frame(width: 4, height: geometry.size.height * point.goalProgress)
                                                            }
                                                            
                                                            // Present Progress Line (orange)
                                                            if index < recentData.count - 1 {
                                                                Circle()
                                                                    .fill(Color.orange)
                                                                    .frame(width: 6, height: 6)
                                                            }
                                                        }
                                                        .frame(maxWidth: .infinity)
                                                    }
                                                }
                                            }
                                            .frame(height: 120)
                                            
                                            // Legend
                                            HStack(spacing: 16) {
                                                HStack(spacing: 6) {
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .fill(Color.blue.opacity(0.7))
                                                        .frame(width: 8, height: 8)
                                                    Text("Goal")
                                                        .font(.pip.caption)
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                HStack(spacing: 6) {
                                                    Circle()
                                                        .fill(Color.orange)
                                                        .frame(width: 6, height: 6)
                                                    Text("Present")
                                                        .font(.pip.caption)
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                Spacer()
                                            }
                                        }
                                    }
                                    
                                    // Statistics
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Progress")
                                                .font(.pip.caption)
                                                .foregroundColor(.gray)
                                            Text(String(format: "%.0f%%", (viewModel.currentProgramProgress()?.improvementRate ?? 0) * 100))
                                                .font(.pip.body)
                                                .foregroundColor(.accentColor)
                                        }
                                        
                                        Divider()
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Sessions")
                                                .font(.pip.caption)
                                                .foregroundColor(.gray)
                                            Text("\(progress.progressHistory.first?.sessionsCompleted ?? 0)/\(progress.progressHistory.first?.sessionsPlanned ?? 30)")
                                                .font(.pip.body)
                                                .foregroundColor(.accentColor)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .padding(12)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .sheet(isPresented: $showProgramStory) {
            if !viewModel.ongoingPrograms.isEmpty {
                ProgramStoryView(
                    program: viewModel.ongoingPrograms[viewModel.currentProgramIndex],
                    progress: viewModel.currentProgramProgress()
                )
            }
        }
    }
}

// MARK: - Program Card View
struct ProgressProgramCardView: View {
    let program: Program
    let progress: ProgramProgress?
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(program.name)
                            .font(.pip.body)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        if let progress = progress {
                            Text(String(format: "%.0f%% Complete", progress.improvementRate * 100))
                                .font(.pip.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Progress Ring
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        
                        Circle()
                            .trim(from: 0, to: progress?.improvementRate ?? 0)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        Text(String(format: "%.0f%%", (progress?.improvementRate ?? 0) * 100))
                            .font(.pip.caption)
                            .foregroundColor(.accentColor)
                    }
                    .frame(width: 60, height: 60)
                }
                
                // Progress bar
                if let progress = progress {
                    VStack(spacing: 4) {
                        ProgressView(value: progress.improvementRate)
                            .tint(.accentColor)
                        
                        HStack(spacing: 8) {
                            Text("Day \(progress.progressHistory.first?.sessionsCompleted ?? 0)")
                                .font(.pip.overline)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("Tap to view story →")
                                .font(.pip.overline)
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .padding(12)
        }
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    ProgressSection(viewModel: GoalViewModel())
        .background(Color.black)
}

// MARK: - Closures extension
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        if self < range.lowerBound {
            return range.lowerBound
        } else if self > range.upperBound {
            return range.upperBound
        } else {
            return self
        }
    }
}
