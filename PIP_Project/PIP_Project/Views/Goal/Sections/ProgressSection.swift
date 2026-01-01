import SwiftUI

struct ProgressSection: View {
    @ObservedObject var viewModel: GoalViewModel
    @State private var showProgramStory = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Header
            HStack {
                HStack(alignment: .center, spacing:6) {
                    Image("title_logo_7")  // Assuming appropriate logo for Progress
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                    
                    Text("Progress")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // MARK: - 2 Column Layout
            HStack(alignment: .top, spacing: 16) {
                // MARK: - Left Column (1/3): Program Card + Stories + Radar Chart
                VStack(spacing: 12) {
                    // Program Card
                    if !viewModel.ongoingPrograms.isEmpty {
                        ProgressProgramCardView(
                            program: viewModel.ongoingPrograms[viewModel.currentProgramIndex],
                            progress: viewModel.currentProgramProgress(),
                            onTap: {
                                showProgramStory = true
                            }
                        )
                        
                        // Radar Chart (Before vs After Metrics)
                        if let progress = viewModel.currentProgramProgress() {
                            VStack(alignment: .leading, spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                    
                                    // Before (past) radar chart - gray outline
                                    RadarChartView(
                                        dataSet: RadarChartDataSet(
                                            title: "Before",
                                            data: progress.radarChartData.map { RadarChartDataItem(iconName: $0.label.lowercased(), value: $0.beforeValue, displayValue: String(format: "%.0f", $0.beforeValue * 100)) },
                                            dataColor: Color.gray.opacity(0.6)
                                        ),
                                        showIcons: false
                                    )
                                    .frame(height: 160)
                                    
                                    // After (current) radar chart - accent color fill
                                    RadarChartView(
                                        dataSet: RadarChartDataSet(
                                            title: "After",
                                            data: progress.radarChartData.map { RadarChartDataItem(iconName: $0.label.lowercased(), value: $0.afterValue, displayValue: String(format: "%.0f", $0.afterValue * 100)) },
                                            dataColor: Color.accentColor
                                        ),
                                        showIcons: false
                                    )
                                    .frame(height: 160)
                                    
                                    // Legend for before/after comparison
                                    VStack {
                                        Spacer()
                                        HStack(spacing: 16) {
                                            HStack(spacing: 6) {
                                                Circle()
                                                    .stroke(Color.gray.opacity(0.6), lineWidth: 2)
                                                    .fill(Color.clear)
                                                    .frame(width: 8, height: 8)
                                                Text("Before")
                                                    .font(.pip.overline)
                                                    .foregroundColor(.gray.opacity(0.7))
                                            }
                                            
                                            HStack(spacing: 6) {
                                                Circle()
                                                    .fill(Color.accentColor.opacity(0.8))
                                                    .frame(width: 8, height: 8)
                                                Text("After")
                                                    .font(.pip.overline)
                                                    .foregroundColor(.accentColor)
                                            }
                                        }
                                        .padding(.bottom, 4)
                                    }
                                }
                                .frame(height: 200)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                // MARK: - Right Column (2/3): Bar Line Chart
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                            
                            if let progress = viewModel.currentProgramProgress() {
                                VStack(alignment: .leading, spacing: 8) {
                                    let recentData = Array(progress.progressHistory.prefix(7))
                                    let pointSpacing: CGFloat = max(18, min(26, 160 / CGFloat(max(1, recentData.count))))
                                    let chartHeight = pointSpacing * CGFloat(recentData.count)
                                    
                                    // Chart with Grid, Curves, and Nodes
                                    GeometryReader { geometry in
                                        let chartWidth = geometry.size.width - 45 // 좌측 여백 40 + 스페이서 5
                                        let yAxisX: CGFloat = 40
                                        
                                        ZStack(alignment: .topLeading) {
                                            // Background Grid
                                            Canvas { context, size in
                                                // Vertical lines (20% intervals)
                                                for i in 0...5 {
                                                    let x = yAxisX + (chartWidth * CGFloat(i) / 5)
                                                    var path = Path()
                                                    path.move(to: CGPoint(x: x, y: 0))
                                                    path.addLine(to: CGPoint(x: x, y: chartHeight))
                                                    context.stroke(path, with: .color(Color.gray.opacity(0.15)))
                                                }
                                                
                                                // Horizontal lines (point spacing intervals)
                                                for i in 0..<recentData.count {
                                                    let y = CGFloat(i) * pointSpacing
                                                    var path = Path()
                                                    path.move(to: CGPoint(x: yAxisX, y: y))
                                                    path.addLine(to: CGPoint(x: yAxisX + chartWidth, y: y))
                                                    context.stroke(path, with: .color(Color.gray.opacity(0.1)))
                                                }
                                            }
                                            .frame(height: chartHeight)
                                            
                                            // Y-axis line
                                            Path { path in
                                                path.move(to: CGPoint(x: yAxisX, y: 0))
                                                path.addLine(to: CGPoint(x: yAxisX, y: chartHeight))
                                            }
                                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                            
                                            // Goal trend line with nodes
                                            Canvas { context, size in
                                                var points: [CGPoint] = []
                                                for (index, point) in recentData.enumerated() {
                                                    let x = yAxisX + chartWidth * (point.goalProgress.isFinite && point.goalProgress >= 0 ? point.goalProgress : 0)
                                                    let y = CGFloat(index) * pointSpacing + 2
                                                    points.append(CGPoint(x: x, y: y))
                                                }
                                                
                                                // Draw curve
                                                if !points.isEmpty {
                                                    var path = Path()
                                                    path.move(to: points[0])
                                                    for i in 0..<(points.count - 1) {
                                                        let current = points[i]
                                                        let next = points[i + 1]
                                                        let controlX = (current.x + next.x) / 2
                                                        path.addQuadCurve(to: next, control: CGPoint(x: controlX, y: current.y))
                                                    }
                                                    context.stroke(path, with: .color(Color.blue.opacity(0.7)), lineWidth: 2)
                                                }
                                                
                                                // Draw nodes
                                                for point in points {
                                                    context.fill(
                                                        Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)),
                                                        with: .color(Color.blue.opacity(0.9))
                                                    )
                                                }
                                            }
                                            .frame(height: chartHeight)
                                            
                                            // Present trend line with nodes
                                            Canvas { context, size in
                                                var points: [CGPoint] = []
                                                for (index, point) in recentData.enumerated() {
                                                    let x = yAxisX + chartWidth * (point.presentProgress.isFinite && point.presentProgress >= 0 ? point.presentProgress : 0)
                                                    let y = CGFloat(index) * pointSpacing + 2
                                                    points.append(CGPoint(x: x, y: y))
                                                }
                                                
                                                // Draw curve
                                                if !points.isEmpty {
                                                    var path = Path()
                                                    path.move(to: points[0])
                                                    for i in 0..<(points.count - 1) {
                                                        let current = points[i]
                                                        let next = points[i + 1]
                                                        let controlX = (current.x + next.x) / 2
                                                        path.addQuadCurve(to: next, control: CGPoint(x: controlX, y: current.y))
                                                    }
                                                    context.stroke(path, with: .color(Color.orange.opacity(0.8)), lineWidth: 2)
                                                }
                                                
                                                // Draw nodes
                                                for point in points {
                                                    context.fill(
                                                        Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)),
                                                        with: .color(Color.orange.opacity(0.9))
                                                    )
                                                }
                                            }
                                            .frame(height: chartHeight)
                                            
                                            // Y-axis labels (dates)
                                            VStack(spacing: pointSpacing) {
                                                ForEach(Array(recentData.enumerated()), id: \.element.id) { index, point in
                                                    Text(index == 0 ? "Today" : "-\(index)")
                                                        .font(.pip.overline)
                                                        .foregroundColor(.gray.opacity(0.6))
                                                        .frame(width: 35, alignment: .trailing)
                                                        .frame(height: 0)
                                                }
                                            }
                                            .offset(y: 2)
                                        }
                                    }
                                    .frame(height: chartHeight + 4)
                                    
                                    // X-axis labels (percentage)
                                    HStack(spacing: 0) {
                                        Text("")
                                            .frame(width: 40)
                                        
                                        GeometryReader { geometry in
                                            HStack(spacing: 0) {
                                                ForEach(0...5, id: \.self) { i in
                                                    VStack(spacing: 0) {
                                                        Text("\(i * 20)%")
                                                            .font(.pip.overline)
                                                            .foregroundColor(.gray.opacity(0.5))
                                                    }
                                                    if i < 5 {
                                                        Spacer()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .frame(height: 16)
                                    
                                    // Legend
                                    HStack(spacing: 6) {
                                        Spacer()
                                        
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(Color.blue.opacity(0.9))
                                                .frame(width: 8, height: 8)
                                            Text("Goal")
                                                .font(.pip.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(Color.orange.opacity(0.9))
                                                .frame(width: 8, height: 8)
                                            Text("Present")
                                                .font(.pip.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    // Statistics
                                    HStack(spacing: 12) {
                                        // Progress Ring centered
                                        ZStack {
                                            Circle()
                                                .stroke(Color.white.opacity(0.1), lineWidth: 4)
                                            
                                            Circle()
                                                .trim(from: 0, to: progress.improvementRate)
                                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                                .rotationEffect(.degrees(-90))
                                            
                                            VStack(spacing: 2) {
                                                Text(String(format: "%.0f%%", progress.improvementRate * 100))
                                                    .font(.pip.body)
                                                    .foregroundColor(.accentColor)
                                                Text("Complete")
                                                    .font(.pip.overline)
                                                    .foregroundColor(.gray.opacity(0.7))
                                            }
                                        }
                                        .frame(width: 80, height: 80)
                                    }
                                    .frame(maxWidth: .infinity)
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
    
    var gradientColors: [Color] {
        if let themeNames = program.gemVisualization.gradientColors, !themeNames.isEmpty {
            return themeNames.compactMap { themeName in
                if let theme = ColorThemeForGoal(rawValue: themeName) {
                    return Color(hex: theme.hexColor).opacity(0.4)
                } else {
                    return nil
                }
            }
        } else {
            return [Color.white.opacity(0.05)]
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    gradientColors.count > 1 ?
                        AnyShapeStyle(
                            LinearGradient(
                                gradient: Gradient(colors: gradientColors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ) :
                        AnyShapeStyle(gradientColors.first ?? Color.white.opacity(0.05))
                )
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(program.name)
                            .font(.pip.body)
                            .foregroundColor(Color.pip.goal.textProgram)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                
                // Progress bar
                if let progress = progress {
                    VStack(spacing: 4) {
                        ProgressView(value: progress.improvementRate)
                            .tint(Color.pip.goal.textProgram)
                        
                        HStack(spacing: 8) {
                            Text("Day \(calculateCurrentDay(from: progress.createdAt))")
                                .font(.pip.overline)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("Tap to view story →")
                                .font(.pip.overline)
                                .foregroundColor(Color.pip.goal.textProgram)
                        }
                    }
                }
            }
            .padding(12)
        }
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Helper Functions
private func calculateCurrentDay(from startDate: Date) -> Int {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.day], from: startDate, to: Date())
    return max(1, (components.day ?? 0) + 1) // 최소 1일부터 시작
}

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd"
    return formatter.string(from: date)
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
