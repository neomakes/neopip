//
//  RailroadView.swift
//  PIP_Project
//
//  Fixed perspective Railroad with 7 gem slots
//  Time grouping: daily (7 days) → weekly → monthly → yearly
//

import SwiftUI

// MARK: - Time Period for Gem Grouping
enum GemGroupPeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

// MARK: - Grouped Gem Data
struct GroupedGem: Identifiable {
    let id = UUID()
    let period: GemGroupPeriod
    let startDate: Date
    let endDate: Date
    let gems: [DailyGem]
    let label: String
    
    // Aggregated properties
    var averageBrightness: Double {
        guard !gems.isEmpty else { return 0.5 }
        return gems.map { $0.brightness }.reduce(0, +) / Double(gems.count)
    }
    
    var dominantColorTheme: ColorTheme {
        // Most common color theme
        let counts = Dictionary(grouping: gems, by: { $0.colorTheme })
        return counts.max(by: { $0.value.count < $1.value.count })?.key ?? .teal
    }
    
    var totalDataPoints: Int {
        gems.reduce(0) { $0 + $1.dataPointIds.count }
    }
}

// MARK: - Railroad View
struct RailroadView: View {
    let gems: [DailyGem]
    let onGemTap: ((DailyGem) -> Void)?
    let onGroupTap: ((GroupedGem) -> Void)?
    
    // Fixed 7 slots for the railroad
    private let slotCount = 7
    
    // Perspective configuration
    private let baseGemSize: CGFloat = 65
    private let minGemSize: CGFloat = 25
    private let baseTrackWidth: CGFloat = 140
    private let minTrackWidth: CGFloat = 35
    
    @State private var currentOffset: Int = 0
    
    init(gems: [DailyGem], 
         onGemTap: ((DailyGem) -> Void)? = nil,
         onGroupTap: ((GroupedGem) -> Void)? = nil) {
        self.gems = gems
        self.onGemTap = onGemTap
        self.onGroupTap = onGroupTap
    }
    
    var body: some View {
        let groupedGems = createGroupedGems()
        let visibleGems = getVisibleGems(from: groupedGems)
        
        GeometryReader { geometry in
            ZStack {
                // Fixed Railroad Track (perspective)
                FixedPerspectiveTrack(
                    slotCount: slotCount,
                    baseWidth: baseTrackWidth,
                    minWidth: minTrackWidth,
                    containerHeight: geometry.size.height
                )
                
                // Gem slots (fixed positions, gems animate in/out)
                ForEach(Array(visibleGems.enumerated()), id: \.element.id) { index, groupedGem in
                    let slotPosition = calculateSlotPosition(
                        slot: index,
                        containerSize: geometry.size
                    )
                    
                    RailroadGemSlot(
                        groupedGem: groupedGem,
                        size: calculateGemSize(for: index),
                        onTap: {
                            if groupedGem.gems.count == 1,
                               let gem = groupedGem.gems.first {
                                onGemTap?(gem)
                            } else {
                                onGroupTap?(groupedGem)
                            }
                        }
                    )
                    .position(slotPosition)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
        }
        .frame(height: 500)
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if value.translation.height < -threshold {
                            // Swipe up - show older
                            currentOffset = min(currentOffset + 1, max(0, createGroupedGems().count - slotCount))
                        } else if value.translation.height > threshold {
                            // Swipe down - show newer
                            currentOffset = max(0, currentOffset - 1)
                        }
                    }
                }
        )
    }
    
    // MARK: - Time Grouping Logic
    
    /// Create grouped gems based on time periods
    private func createGroupedGems() -> [GroupedGem] {
        guard !gems.isEmpty else { return [] }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var groupedGems: [GroupedGem] = []
        
        // Sort gems by date (newest first)
        let sortedGems = gems.sorted { $0.date > $1.date }
        
        // Group 1: Last 7 days - individual daily gems
        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let dayGems = sortedGems.filter { gem in
                calendar.isDate(gem.date, inSameDayAs: targetDate)
            }
            
            if !dayGems.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = dayOffset == 0 ? "'Today'" : (dayOffset == 1 ? "'Yesterday'" : "E")
                
                groupedGems.append(GroupedGem(
                    period: GemGroupPeriod.day,
                    startDate: targetDate,
                    endDate: targetDate,
                    gems: dayGems,
                    label: formatter.string(from: targetDate)
                ))
            }
        }
        
        // Group 2: 1-4 weeks ago - weekly grouped
        for weekOffset in 1...4 {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
                  let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { continue }
            
            let weekGems = sortedGems.filter { gem in
                gem.date >= weekStart && gem.date <= weekEnd &&
                gem.date < calendar.date(byAdding: .day, value: -7, to: today)!
            }
            
            if !weekGems.isEmpty {
                groupedGems.append(GroupedGem(
                    period: GemGroupPeriod.week,
                    startDate: weekStart,
                    endDate: weekEnd,
                    gems: weekGems,
                    label: "W-\(weekOffset)"
                ))
            }
        }
        
        // Group 3: 1-12 months ago - monthly grouped
        for monthOffset in 1...12 {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: today),
                  let monthEnd = calendar.date(byAdding: .month, value: -monthOffset + 1, to: today) else { continue }
            
            let monthGems = sortedGems.filter { gem in
                gem.date >= monthStart && gem.date < monthEnd
            }
            
            if !monthGems.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                
                groupedGems.append(GroupedGem(
                    period: GemGroupPeriod.month,
                    startDate: monthStart,
                    endDate: monthEnd,
                    gems: monthGems,
                    label: formatter.string(from: monthStart)
                ))
            }
        }
        
        // Group 4: Years - yearly grouped (beyond 1 year)
        let yearAgo = calendar.date(byAdding: .year, value: -1, to: today)!
        let oldGems = sortedGems.filter { $0.date < yearAgo }
        
        if !oldGems.isEmpty {
            // Group by year
            let yearGroups = Dictionary(grouping: oldGems) { gem in
                calendar.component(.year, from: gem.date)
            }
            
            for (year, yearGems) in yearGroups.sorted(by: { $0.key > $1.key }) {
                groupedGems.append(GroupedGem(
                    period: GemGroupPeriod.year,
                    startDate: yearGems.last?.date ?? Date(),
                    endDate: yearGems.first?.date ?? Date(),
                    gems: yearGems,
                    label: "\(year)"
                ))
            }
        }
        
        return groupedGems
    }
    
    /// Get visible gems for current offset
    private func getVisibleGems(from allGems: [GroupedGem]) -> [GroupedGem] {
        guard !allGems.isEmpty else { return [] }
        let start = min(currentOffset, max(0, allGems.count - slotCount))
        let end = min(start + slotCount, allGems.count)
        return Array(allGems[start..<end])
    }
    
    // MARK: - Position Calculations
    
    private func calculateSlotPosition(slot: Int, containerSize: CGSize) -> CGPoint {
        let centerX = containerSize.width / 2
        let progress = CGFloat(slot) / CGFloat(slotCount - 1)
        
        // Y position (top = 0, bottom = height)
        let topPadding: CGFloat = 40
        let bottomPadding: CGFloat = 60
        let availableHeight = containerSize.height - topPadding - bottomPadding
        let y = topPadding + availableHeight * progress
        
        // X offset (alternating, decreasing towards top)
        let trackWidth = minTrackWidth + (baseTrackWidth - minTrackWidth) * progress
        let xOffset = trackWidth * 0.4 * (slot % 2 == 0 ? -1 : 1)
        
        return CGPoint(x: centerX + xOffset, y: y)
    }
    
    private func calculateGemSize(for slot: Int) -> CGFloat {
        let progress = CGFloat(slot) / CGFloat(slotCount - 1)
        return minGemSize + (baseGemSize - minGemSize) * progress
    }
}

// MARK: - Fixed Perspective Track
struct FixedPerspectiveTrack: View {
    let slotCount: Int
    let baseWidth: CGFloat
    let minWidth: CGFloat
    let containerHeight: CGFloat
    
    var body: some View {
        ZStack {
            // Track fill (trapezoid)
            PerspectiveTrackShape(
                baseWidth: baseWidth,
                minWidth: minWidth,
                topPadding: 40,
                bottomPadding: 60
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color.pip.home.railroadFront.opacity(0.05),
                        Color.pip.home.railroadFront.opacity(0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Track rails
            PerspectiveRailsShape(
                baseWidth: baseWidth,
                minWidth: minWidth,
                topPadding: 40,
                bottomPadding: 60
            )
            .stroke(
                LinearGradient(
                    colors: [
                        Color.pip.home.railroadFront.opacity(0.2),
                        Color.pip.home.railroadFront.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 2
            )
            
            // Cross ties at each slot
            ForEach(0..<slotCount, id: \.self) { slot in
                let progress = CGFloat(slot) / CGFloat(slotCount - 1)
                let y = 40 + (containerHeight - 100) * progress
                let tieWidth = minWidth * 0.6 + (baseWidth * 0.6 - minWidth * 0.6) * progress
                
                Rectangle()
                    .fill(Color.pip.home.railroadFront.opacity(0.3 + 0.3 * progress))
                    .frame(width: tieWidth, height: 2 + progress * 2)
                    .position(x: UIScreen.main.bounds.width / 2, y: y)
            }
        }
    }
}

// MARK: - Perspective Track Shape
struct PerspectiveTrackShape: Shape {
    let baseWidth: CGFloat
    let minWidth: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.midX
        let topY = topPadding
        let bottomY = rect.height - bottomPadding
        
        path.move(to: CGPoint(x: centerX - minWidth / 2, y: topY))
        path.addLine(to: CGPoint(x: centerX + minWidth / 2, y: topY))
        path.addLine(to: CGPoint(x: centerX + baseWidth / 2, y: bottomY))
        path.addLine(to: CGPoint(x: centerX - baseWidth / 2, y: bottomY))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Perspective Rails Shape
struct PerspectiveRailsShape: Shape {
    let baseWidth: CGFloat
    let minWidth: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.midX
        let topY = topPadding
        let bottomY = rect.height - bottomPadding
        
        // Left rail
        path.move(to: CGPoint(x: centerX - minWidth / 2, y: topY))
        path.addLine(to: CGPoint(x: centerX - baseWidth / 2, y: bottomY))
        
        // Right rail
        path.move(to: CGPoint(x: centerX + minWidth / 2, y: topY))
        path.addLine(to: CGPoint(x: centerX + baseWidth / 2, y: bottomY))
        
        return path
    }
}

// MARK: - Railroad Gem Slot
struct RailroadGemSlot: View {
    let groupedGem: GroupedGem
    let size: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            // Gem visualization
            ZStack {
                // Glow + Main gem + Stroke - using concrete shapes
                gemVisualization
                
                // Count badge for grouped gems
                if groupedGem.gems.count > 1 {
                    Text("\(groupedGem.gems.count)")
                        .font(.system(size: size * 0.25, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.5))
                        )
                        .offset(x: size * 0.35, y: -size * 0.35)
                }
            }
            .opacity(0.7 + groupedGem.averageBrightness * 0.3)
            
            // Label
            Text(groupedGem.label)
                .font(.system(size: max(10, size * 0.18)))
                .foregroundColor(.white.opacity(0.7))
        }
        .onTapGesture {
            onTap()
        }
    }
    
    @ViewBuilder
    private var gemVisualization: some View {
        switch groupedGem.period {
        case .day:
            gemLayers(shape: DiamondGemShape())
        case .week:
            gemLayers(shape: DoubleTriangleShape())
        case .month:
            gemLayers(shape: StackedRectShape())
        case .year:
            gemLayers(shape: TriangleRectShape())
        }
    }
    
    private func gemLayers<S: Shape>(shape: S) -> some View {
        ZStack {
            // Glow
            shape
                .fill(themeColor.opacity(0.3))
                .frame(width: size * 1.3, height: size * 1.3)
                .blur(radius: 8)
            
            // Main gem
            shape
                .fill(glassGradient)
                .frame(width: size, height: size)
            
            // Stroke
            shape
                .stroke(themeColor.opacity(0.6), lineWidth: 1.5)
                .frame(width: size, height: size)
        }
    }
    
    private var themeColor: Color {
        switch groupedGem.dominantColorTheme {
        case .teal: return Color(red: 0.51, green: 0.92, blue: 0.92)
        case .amber: return Color(red: 1.0, green: 0.65, blue: 0.0)
        case .tiger: return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .blue: return Color(red: 0.0, green: 0.4, blue: 0.8)
        }
    }
    
    private var glassGradient: LinearGradient {
        LinearGradient(
            colors: [
                themeColor.opacity(0.6),
                themeColor.opacity(0.3),
                Color.white.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Custom Shapes

struct TriangleRectShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let triHeight = rect.height * 0.4
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + triHeight))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + triHeight))
        path.closeSubpath()
        
        path.addRect(CGRect(
            x: rect.minX + rect.width * 0.15,
            y: rect.minY + triHeight - 2,
            width: rect.width * 0.7,
            height: rect.height * 0.6 + 2
        ))
        
        return path
    }
}

struct RectTriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rectHeight = rect.height * 0.5
        
        path.addRect(CGRect(
            x: rect.minX + rect.width * 0.15,
            y: rect.minY,
            width: rect.width * 0.7,
            height: rectHeight
        ))
        
        let triTop = rect.minY + rectHeight - 2
        path.move(to: CGPoint(x: rect.minX, y: triTop))
        path.addLine(to: CGPoint(x: rect.maxX, y: triTop))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}

struct DoubleTriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.closeSubpath()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}

struct StackedRectShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.addRect(CGRect(
            x: rect.minX + rect.width * 0.25,
            y: rect.minY,
            width: rect.width * 0.5,
            height: rect.height * 0.35
        ))
        
        path.addRect(CGRect(
            x: rect.minX + rect.width * 0.1,
            y: rect.minY + rect.height * 0.35 - 2,
            width: rect.width * 0.8,
            height: rect.height * 0.65 + 2
        ))
        
        return path
    }
}

struct DiamondGemShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        RailroadView(
            gems: (0..<30).map { i in
                DailyGem(
                    id: UUID(),
                    accountId: UUID(),
                    date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
                    gemType: [.sphere, .diamond, .crystal, .prism][i % 4],
                    brightness: Double.random(in: 0.6...1.0),
                    uncertainty: Double.random(in: 0.1...0.4),
                    dataPointIds: Array(repeating: "id", count: Int.random(in: 1...5)),
                    colorTheme: [.teal, .amber, .tiger, .blue][i % 4],
                    createdAt: Date()
                )
            },
            onGemTap: { gem in
                print("Tapped gem: \(gem.date)")
            },
            onGroupTap: { group in
                print("Tapped group: \(group.label) with \(group.gems.count) gems")
            }
        )
        .padding(.horizontal, 20)
    }
}
