import SwiftUI

struct ProgressSection: View {
    @ObservedObject var viewModel: GoalViewModel
    @State private var showProgramStory = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Header
            HStack {
                HStack(alignment: .center, spacing:6) {
                    Image("title_logo_1")  // Assuming appropriate logo for Progress
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
            
            // MARK: - Empty State Check
            if viewModel.ongoingPrograms.isEmpty {
                // Show fallback when no programs are enrolled
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    VStack(spacing: 8) {
                        Text("No Progress Data")
                            .font(.pip.title2)
                            .foregroundColor(.white)
                        
                        Text("Enroll in a program to track your progress")
                            .font(.pip.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .padding(.horizontal, 16)
            } else {
                // MARK: - 2 Column Layout
                HStack(alignment: .top, spacing: 16) {
                    // MARK: - Left Column (1/3): Program Card + Stories + Radar Chart
                    VStack(spacing: 12) {
                        // Program Card
                        if !viewModel.ongoingPrograms.isEmpty {
                            let program = viewModel.ongoingPrograms[viewModel.currentProgramIndex]
                            let enrollment = viewModel.activeEnrollments.first(where: { $0.programId == program.id })
                            let currentDay = enrollment?.currentDay ?? 1
                            let activeMission = program.missions?.first(where: { $0.day == currentDay })
                            
                            ProgressProgramCardView(
                                program: program,
                                progress: viewModel.currentProgramProgress(),
                                onTap: {
                                    showProgramStory = true
                                },
                                activeMission: activeMission,
                                currentDay: currentDay
                            )
                            
                            // Radar Chart (Before vs After Metrics)
                            if let progress = viewModel.currentProgramProgress() {
                                if progress.progressHistory.isEmpty {
                                    // Empty State for Radar Chart
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))
                                        
                                        VStack(spacing: 4) {
                                            Image(systemName: "hexagon")
                                                .font(.system(size: 18))
                                                .foregroundColor(.gray.opacity(0.3))
                                            Text("Your growth journey starts now.\nComplete missions to track progress!")
                                                .font(.pip.caption)
                                                .foregroundColor(.gray.opacity(0.5))
                                                .multilineTextAlignment(.center)
                                                .minimumScaleFactor(0.5)
                                        }
                                        .padding(.horizontal, 6) // Reduced 8 -> 6
                                    }
                                    .frame(height: 145) // Increased 130 -> 145
                                } else {
                                    VStack(alignment: .leading, spacing: 6) { // Reduced 8 -> 6
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
                                            .frame(height: 100) // Reduced 120 -> 100
                                            
                                            // After (current) radar chart - accent color fill
                                            RadarChartView(
                                                dataSet: RadarChartDataSet(
                                                    title: "After",
                                                    data: progress.radarChartData.map { RadarChartDataItem(iconName: $0.label.lowercased(), value: $0.afterValue, displayValue: String(format: "%.0f", $0.afterValue * 100)) },
                                                    dataColor: Color.accentColor
                                                ),
                                                showIcons: false
                                            )
                                            .frame(height: 100) // Reduced 120 -> 100
                                            
                                            // Legend for before/after comparison
                                            VStack {
                                                Spacer()
                                                HStack(spacing: 10) { // Reduced 12 -> 10
                                                    HStack(spacing: 4) {
                                                        Circle()
                                                            .stroke(Color.gray.opacity(0.6), lineWidth: 2)
                                                            .fill(Color.clear)
                                                            .frame(width: 5, height: 5) // Reduced 6 -> 5
                                                        Text("Before")
                                                            .font(.pip.overline)
                                                            .foregroundColor(.gray.opacity(0.7))
                                                            .minimumScaleFactor(0.5)
                                                    }
                                                    
                                                    HStack(spacing: 4) {
                                                        Circle()
                                                            .fill(Color.accentColor.opacity(0.8))
                                                            .frame(width: 5, height: 5) // Reduced 6 -> 5
                                                        Text("After")
                                                            .font(.pip.overline)
                                                            .foregroundColor(.accentColor)
                                                            .minimumScaleFactor(0.5)
                                                    }
                                                }
                                                .padding(.bottom, 2) // Reduced 4 -> 2
                                            }
                                        }
                                        .frame(height: 145) // Increased 130 -> 145
                                    }
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
                                    VStack(alignment: .leading, spacing: 4) { // Reduced spacing 8 -> 4
                                        let recentData = Array(progress.progressHistory.prefix(7))
                                        
                                        if recentData.isEmpty {
                                            // Empty State for ENTIRE Right Section
                                            ZStack {
                                                // Removed redundant background to fix "frame on frame" visual
                                                
                                                VStack(spacing: 6) { 
                                                    Image(systemName: "chart.xyaxis.line")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(.gray.opacity(0.4))
                                                    Text("Your growth journey starts now.\nComplete missions to track progress!")
                                                        .font(.pip.caption)
                                                        .foregroundColor(.gray.opacity(0.6))
                                                        .multilineTextAlignment(.center)
                                                        .minimumScaleFactor(0.5)
                                                }
                                                .padding(.horizontal, 8)
                                            }
                                            // Using .frame(minHeight: ...) to ensure it takes up reasonable space without being hardcoded "stretched"
                                            // If left column is ~250 (100+145+spacing), we can match that or just let it fill
                                            .frame(maxWidth: .infinity, maxHeight: .infinity) 
                                        } else {
                                            // Existing Chart Logic
                                            // Compact calculation: target ~130
                                            let pointSpacing: CGFloat = max(16, min(24, 130 / CGFloat(max(1, recentData.count))))
                                            let chartHeight = pointSpacing * CGFloat(recentData.count)
                                            
                                            // Chart with Grid, Curves, and Nodes
                                            GeometryReader { geometry in
                                                let chartWidth = geometry.size.width - 35 // Adjusted margins
                                                let yAxisX: CGFloat = 30 // Adjusted margins
                                                
                                                ZStack(alignment: .topLeading) {
                                                    // Background Grid
                                                    Canvas { context, size in
                                                        // Vertical lines
                                                        for i in 0...5 {
                                                            let x = yAxisX + (chartWidth * CGFloat(i) / 5)
                                                            var path = Path()
                                                            path.move(to: CGPoint(x: x, y: 0))
                                                            path.addLine(to: CGPoint(x: x, y: chartHeight))
                                                            context.stroke(path, with: .color(Color.gray.opacity(0.15)))
                                                        }
                                                        
                                                        // Horizontal lines
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
                                                    
                                                    // Goal trend line
                                                    Canvas { context, size in
                                                        var points: [CGPoint] = []
                                                        for (index, point) in recentData.enumerated() {
                                                            let x = yAxisX + chartWidth * (point.goalProgress.isFinite && point.goalProgress >= 0 ? point.goalProgress : 0)
                                                            let y = CGFloat(index) * pointSpacing + 2
                                                            points.append(CGPoint(x: x, y: y))
                                                        }
                                                        
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
                                                        
                                                        for point in points {
                                                            context.fill(Path(ellipseIn: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)), with: .color(Color.blue.opacity(0.9)))
                                                        }
                                                    }
                                                    .frame(height: chartHeight)
                                                    
                                                    // Present trend line
                                                    Canvas { context, size in
                                                        var points: [CGPoint] = []
                                                        for (index, point) in recentData.enumerated() {
                                                            let x = yAxisX + chartWidth * (point.presentProgress.isFinite && point.presentProgress >= 0 ? point.presentProgress : 0)
                                                            let y = CGFloat(index) * pointSpacing + 2
                                                            points.append(CGPoint(x: x, y: y))
                                                        }
                                                        
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
                                                        
                                                        for point in points {
                                                            context.fill(Path(ellipseIn: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)), with: .color(Color.orange.opacity(0.9)))
                                                        }
                                                    }
                                                    .frame(height: chartHeight)
                                                    
                                                    // Y-axis labels
                                                    VStack(spacing: pointSpacing) {
                                                        ForEach(Array(recentData.enumerated()), id: \.element.id) { index, point in
                                                            Text(index == 0 ? "Today" : "-\(index)")
                                                                .font(.pip.overline)
                                                                .foregroundColor(.gray.opacity(0.6))
                                                                .frame(width: 25, alignment: .trailing)
                                                                .frame(height: 0)
                                                                .minimumScaleFactor(0.7)
                                                        }
                                                    }
                                                    .offset(y: 2)
                                                }
                                            }
                                            .frame(height: chartHeight + 4)
                                        
                                            // X-axis labels
                                            HStack(spacing: 0) {
                                                Text("")
                                                    .frame(width: 30)
                                                
                                                GeometryReader { geometry in
                                                    HStack(spacing: 0) {
                                                        ForEach(0...5, id: \.self) { i in
                                                            VStack(spacing: 0) {
                                                                Text("\(i * 20)%")
                                                                    .font(.pip.overline)
                                                                    .foregroundColor(.gray.opacity(0.5))
                                                                    .minimumScaleFactor(0.7)
                                                            }
                                                            if i < 5 {
                                                                Spacer()
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            .frame(height: 12) // Reduced from 14
                                            
                                            // Legend
                                            HStack(spacing: 6) {
                                                Spacer()
                                                
                                                HStack(spacing: 4) {
                                                    Circle()
                                                        .fill(Color.blue.opacity(0.9))
                                                        .frame(width: 5, height: 5)
                                                    Text("Goal")
                                                        .font(.pip.caption)
                                                        .foregroundColor(.gray)
                                                        .minimumScaleFactor(0.5)
                                                }
                                                
                                                HStack(spacing: 4) {
                                                    Circle()
                                                        .fill(Color.orange.opacity(0.9))
                                                        .frame(width: 5, height: 5)
                                                    Text("Present")
                                                        .font(.pip.caption)
                                                        .foregroundColor(.gray)
                                                        .minimumScaleFactor(0.5)
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
                                                    
                                                    VStack(spacing: 0) {
                                                        Text(String(format: "%.0f%%", progress.improvementRate * 100))
                                                            .font(.pip.body) // Keep body but smaller scale factor if needed
                                                            .bold()
                                                            .foregroundColor(.accentColor)
                                                            .minimumScaleFactor(0.5)
                                                        Text("Complete")
                                                            .font(.pip.overline)
                                                            .foregroundColor(.gray.opacity(0.7))
                                                            .minimumScaleFactor(0.5)
                                                    }
                                                }
                                                .frame(width: 50, height: 50) // Reduced 64 -> 50
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                    }
                                    .padding(8) // Reduced padding
                                }
                            }
                            // Right column height matching
                            // Left column: Program Card (~80-100) + Radar Chart (145) + Spacing (12) ~ 240-260?
                            // We can use a flexible frame
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
            }
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
    // New properties
    var activeMission: ProgramMission? = nil
    var currentDay: Int = 1
    
    var gradientColors: [Color] {
        if let themeNames = program.gemVisualization.gradientColors, !themeNames.isEmpty {
            return themeNames.compactMap { themeName in
                if let theme = ColorThemeForGoal(rawValue: themeName) {
                    return Color(hex: theme.hexColor).opacity(0.3)
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
            
            VStack(alignment: .leading, spacing: 6) { 
                HStack {
                    VStack(alignment: .leading, spacing: 2) { 
                        if let mission = activeMission {
                            Text(mission.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color.pip.goal.textProgram)
                                .lineLimit(2)
                                .minimumScaleFactor(0.6)
                            
                            Text(program.name)
                                .font(.pip.caption)
                                .foregroundColor(Color.pip.goal.textProgram.opacity(0.7))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        } else {
                            Text(program.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color.pip.goal.textProgram)
                                .lineLimit(2)
                                .minimumScaleFactor(0.6)
                        }
                    }
                    
                    Spacer()
                }
                
                // Progress bar
                if let progress = progress {
                    VStack(spacing: 4) {
                        ProgressView(value: progress.improvementRate)
                            .tint(Color.pip.goal.textProgram)
                            .scaleEffect(y: 0.6) // Thinner progress bar
                        
                        HStack(spacing: 8) {
                            Text("Day \(calculateCurrentDay(from: progress.createdAt))") // Ideally use passed currentDay but calculateCurrentDay is fine fallback or we use currentDay
                                .font(.pip.overline)
                                .foregroundColor(.gray)
                                .minimumScaleFactor(0.7)
                            
                            Spacer()
                            
                            Text("View story →") 
                                .font(.pip.overline)
                                .foregroundColor(Color.pip.goal.textProgram)
                                .minimumScaleFactor(0.7)
                        }
                    }
                }
            }
            .padding(8) 
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
