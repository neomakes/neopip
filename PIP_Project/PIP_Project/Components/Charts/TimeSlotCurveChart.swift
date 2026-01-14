//
//  TimeSlotCurveChart.swift
//  PIP_Project
//
//  Interactive time-slot curve chart for Write cards
//  Allows users to input values for specific time ranges (e.g., excluding sleep hours)
//  Updated to 7 points with persisted control times.
//

import SwiftUI

// MARK: - Time Slot Curve Chart View
struct TimeSlotCurveChart: View {
    @Binding var values: [Double]  // 7 control points (Start ... End)
    @Binding var times: [Double]   // 7 control times (Hours 0-24)
    let range: ClosedRange<Double>
    let label: String

    @State private var selectedControlIndex: Int? = nil
    @State private var isDragging = false
    @State private var dragStartValue: Double? = nil
    @State private var dragStartHour: Double? = nil

    // Default: 7am to 11pm (awake hours) spread over 7 points
    // [7, 9.6, 12.3, 15, 17.6, 20.3, 23] approximately
    
    init(values: Binding<[Double]>, times: Binding<[Double]>, range: ClosedRange<Double> = 0...100, label: String = "Value") {
        self._values = values
        self._times = times
        self.range = range
        self.label = label
    }

    // Get the active time range (from first to last control point)
    private var activeStartHour: Double {
        times.min() ?? 7
    }

    private var activeEndHour: Double {
        times.max() ?? 23
    }

    // Interpolate control points within active range using Catmull-Rom spline
    // Returns (hour, value) pairs only for the active time range
    private func interpolatedPoints() -> [(hour: Double, value: Double)] {
        guard values.count >= 2, values.count == times.count else { return [] }

        // Sort control points by hour
        let sortedIndices = times.indices.sorted { times[$0] < times[$1] }
        let sortedHours = sortedIndices.map { times[$0] }
        let sortedValues = sortedIndices.map { values[$0] }

        let startHour = sortedHours.first ?? 0
        let endHour = sortedHours.last ?? 23

        var result: [(hour: Double, value: Double)] = []

        // Generate points at 0.5 hour intervals for smooth curve
        var h = startHour
        while h <= endHour {
            // Find which segment this hour belongs to
            var segmentIndex = 0
            for i in 0..<(sortedHours.count - 1) {
                if h >= sortedHours[i] && h <= sortedHours[i + 1] {
                    segmentIndex = i
                    break
                }
            }

            // Catmull-Rom interpolation
            let p0 = segmentIndex > 0 ? sortedValues[segmentIndex - 1] : sortedValues[segmentIndex]
            let p1 = sortedValues[segmentIndex]
            let p2 = sortedValues[min(segmentIndex + 1, sortedValues.count - 1)]
            let p3 = sortedValues[min(segmentIndex + 2, sortedValues.count - 1)]

            let h1 = sortedHours[segmentIndex]
            let h2 = sortedHours[min(segmentIndex + 1, sortedHours.count - 1)]

            let t: Double
            if h2 - h1 > 0 {
                t = (h - h1) / (h2 - h1)
            } else {
                t = 0
            }

            // Catmull-Rom formula
            let t2 = t * t
            let t3 = t2 * t

            var interpolatedValue = 0.5 * (
                (2 * p1) +
                (-p0 + p2) * t +
                (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
                (-p0 + 3 * p1 - 3 * p2 + p3) * t3
            )

            // Clamp to range
            interpolatedValue = max(range.lowerBound, min(range.upperBound, interpolatedValue))
            result.append((hour: h, value: interpolatedValue))

            h += 0.2 // Finer resolution for 7 points
        }

        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title with active time range indicator
            HStack {
                Text(label)
                    .font(.pip.body)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                if let controlIndex = selectedControlIndex, controlIndex < times.count, controlIndex < values.count {
                    let hourVal = times[controlIndex]
                    let hour = Int(hourVal)
                    let min = Int(round((hourVal - Double(hour)) * 60)) // Fix floating point truncation (e.g. 9.999 -> 10)
                    let timeStr = String(format: "%02d:%02d", hour, min)
                    
                    Text("\(timeStr) - \(Int(values[controlIndex]))")
                        .font(.pip.title2)
                        .foregroundColor(.pip.home.numRecords)
                } else {
                    // Show active time range
                    let startH = Int(activeStartHour)
                    let startM = Int(round((activeStartHour - Double(startH)) * 60))
                    let endH = Int(activeEndHour)
                    let endM = Int(round((activeEndHour - Double(endH)) * 60))
                    
                    Text(String(format: "%02d:%02d ~ %02d:%02d", startH, startM, endH, endM))
                        .font(.pip.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Curve chart
            GeometryReader { geometry in
                let width = geometry.size.width
                let height: CGFloat = 120 // Slightly taller
                let stepX = width / 24  // Map to 24-hour scale (0-24)

                ZStack {
                    // Grid lines (horizontal)
                    VStack(spacing: 0) {
                        ForEach(0..<5) { _ in
                            Divider()
                                .background(Color.white.opacity(0.1))
                            Spacer()
                        }
                        Divider()
                            .background(Color.white.opacity(0.1))
                    }
                    .frame(height: height)
                    
                    // Vertical Grid Lines (every 3 hours)
                    HStack(spacing: 0) {
                        ForEach(0..<9) { i in
                            Divider()
                                .background(Color.white.opacity(0.05))
                            if i < 8 { Spacer() }
                        }
                    }
                    .frame(height: height)

                    // Zero Line (for ranges crossing 0, e.g., -100 to 100)
                    if range.contains(0) {
                        let zeroY = height - (CGFloat(0 - range.lowerBound) / (range.upperBound - range.lowerBound) * height)
                        Rectangle()
                            .fill(Color.white.opacity(0.3)) // Stronger visual than grid
                            .frame(height: 1)
                            .position(x: width / 2, y: zeroY)
                    }

                    // Inactive zones (sleep/excluded time) - shown as dimmed areas
                    // Left inactive zone (before first control point)
                    if activeStartHour > 0 {
                        Rectangle()
                            .fill(Color.white.opacity(0.03))
                            .frame(width: CGFloat(activeStartHour) * stepX, height: height)
                            .position(x: CGFloat(activeStartHour) * stepX / 2, y: height / 2)
                    }

                    // Right inactive zone (after last control point)
                    if activeEndHour < 24 {
                        let inactiveWidth = CGFloat(24 - activeEndHour) * stepX
                        Rectangle()
                            .fill(Color.white.opacity(0.03))
                            .frame(width: inactiveWidth, height: height)
                            .position(x: width - inactiveWidth / 2, y: height / 2)
                    }

                    // Smooth curve path - only within active range
                    Path { path in
                        let interpolated = interpolatedPoints()
                        guard !interpolated.isEmpty else { return }

                        // Create points for the curve
                        var points: [CGPoint] = []
                        for point in interpolated {
                            let x = CGFloat(point.hour) * stepX
                            let normalizedValue = (point.value - range.lowerBound) / (range.upperBound - range.lowerBound)
                            let y = height - (CGFloat(normalizedValue) * height)
                            points.append(CGPoint(x: x, y: y))
                        }

                        guard !points.isEmpty else { return }
                        path.move(to: points[0])

                        // Use quadratic curves for smoothness
                        for i in 1..<points.count {
                            let current = points[i]
                            let previous = points[i - 1]
                            let midPoint = CGPoint(
                                x: (previous.x + current.x) / 2,
                                y: (previous.y + current.y) / 2
                            )

                            if i == 1 {
                                path.addLine(to: midPoint)
                            } else {
                                path.addQuadCurve(to: midPoint, control: previous)
                            }
                        }
                        path.addLine(to: points.last!)
                    }
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.pip.home.buttonAddGrad1, Color.pip.home.buttonAddGrad2]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: Color.pip.home.buttonAddGrad1.opacity(0.5), radius: 4, x: 0, y: 0)

                    // Fill under curve - only within active range
                    Path { path in
                        let interpolated = interpolatedPoints()
                        guard !interpolated.isEmpty else { return }

                        var points: [CGPoint] = []
                        for point in interpolated {
                            let x = CGFloat(point.hour) * stepX
                            let normalizedValue = (point.value - range.lowerBound) / (range.upperBound - range.lowerBound)
                            let y = height - (CGFloat(normalizedValue) * height)
                            points.append(CGPoint(x: x, y: y))
                        }

                        guard !points.isEmpty else { return }

                        // Start from bottom-left of active area
                        let startX = CGFloat(activeStartHour) * stepX
                        let endX = CGFloat(activeEndHour) * stepX

                        path.move(to: CGPoint(x: startX, y: height))
                        path.addLine(to: points[0])

                        for i in 1..<points.count {
                            let current = points[i]
                            let previous = points[i - 1]
                            let midPoint = CGPoint(
                                x: (previous.x + current.x) / 2,
                                y: (previous.y + current.y) / 2
                            )

                            if i == 1 {
                                path.addLine(to: midPoint)
                            } else {
                                path.addQuadCurve(to: midPoint, control: previous)
                            }
                        }
                        path.addLine(to: points.last!)
                        path.addLine(to: CGPoint(x: endX, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.pip.home.buttonAddGrad1.opacity(0.3), Color.pip.home.buttonAddGrad2.opacity(0.0)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Draggable control points
                    ForEach(0..<times.count, id: \.self) { controlIndex in
                        controlPointView(for: controlIndex, width: width, height: height)
                    }
                }
                .frame(height: height)
                
                // Labels (Using GeometryReader to position exactly)
                ForEach(0..<9) { i in
                    let hour = i * 3
                    let xPos = CGFloat(hour) * stepX
                    Text("\(hour)")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                        .position(x: xPos, y: height + 10) // 10px below chart
                }
            }
            .frame(height: 120 + 20) // Add padding for labels
            .padding(.vertical, 8)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Control Point View
    private func controlPointView(for controlIndex: Int, width: CGFloat, height: CGFloat) -> some View {
        guard controlIndex < values.count, controlIndex < times.count else { return AnyView(EmptyView()) }
        
        let value = values[controlIndex]
        let hour = times[controlIndex]
        let isSelected = selectedControlIndex == controlIndex
        let isEndpoint = controlIndex == 0 || controlIndex == times.count - 1

        let stepX = width / 24
        let x = CGFloat(hour) * stepX
        let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        let y = height - (CGFloat(normalizedValue) * height)

        return AnyView(ZStack {
            // Endpoint indicator (vertical line to show it can move horizontally)
            if isEndpoint && isSelected {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2, height: height)
                    .position(x: x, y: height / 2)
            }

            Circle()
                .fill(isSelected ? Color.white : (isEndpoint ? Color.pip.home.buttonAddGrad2 : Color.pip.home.buttonAddGrad1))
                .frame(width: isSelected ? 16 : (isEndpoint ? 12 : 10), height: isSelected ? 16 : (isEndpoint ? 12 : 10))
                .shadow(color: isSelected ? Color.pip.home.buttonAddGrad1.opacity(0.8) : .clear, radius: 6, x: 0, y: 0)
                .position(x: x, y: y)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    selectedControlIndex = controlIndex
                    isDragging = true

                    // Store initial values on drag start
                    if dragStartValue == nil {
                        dragStartValue = self.values[controlIndex]
                        dragStartHour = self.times[controlIndex]
                    }

                    // Calculate new value (Y-axis)
                    let valueRange = range.upperBound - range.lowerBound
                    let dragSensitivity = valueRange / height
                    let valueDelta = -gesture.translation.height * dragSensitivity
                    let newValue = (dragStartValue ?? self.values[controlIndex]) + valueDelta
                    self.values[controlIndex] = max(range.lowerBound, min(range.upperBound, newValue))

                    // Calculate new hour (X-axis) - ALL points can now move horizontally
                    let hourDelta = gesture.translation.width / stepX
                    var newHour = (dragStartHour ?? self.times[controlIndex]) + Double(hourDelta)
                    
                    // Snap to roughly 10 mins (0.166 hour)
                    let snapInterval = 10.0 / 60.0
                    newHour = round(newHour / snapInterval) * snapInterval

                    // Get sorted control hours to find neighbors
                    // In our case, index IS sorted order because we initialized it that way and enforce constraints
                    // But if users drag freely, we must respect index order
                    
                    let minHour: Double
                    let maxHour: Double

                    if controlIndex == 0 {
                        // First point
                        minHour = 0
                        maxHour = self.times.count > 1 ? self.times[1] - 0.5 : 24
                    } else if controlIndex == self.times.count - 1 {
                        // Last point
                        minHour = self.times[controlIndex - 1] + 0.5
                        maxHour = 24
                    } else {
                        // Middle points
                        minHour = self.times[controlIndex - 1] + 0.5
                        maxHour = self.times[controlIndex + 1] - 0.5
                    }

                    newHour = max(minHour, min(maxHour, newHour))
                    self.times[controlIndex] = newHour
                }
                .onEnded { _ in
                    isDragging = false
                    dragStartValue = nil
                    dragStartHour = nil

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if !isDragging {
                            selectedControlIndex = nil
                        }
                    }
                }
        ))
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var values: [Double] = [0, 20, 40, 60, 40, 20, 0]
        @State private var times: [Double] = [7, 9.5, 12, 14.5, 17, 19.5, 22]

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 40) {
                    TimeSlotCurveChart(values: $values, times: $times, range: -100...100, label: "Mood")
                        .padding(.horizontal, 24)

                    TimeSlotCurveChart(values: $values, times: $times, range: 0...100, label: "Energy")
                        .padding(.horizontal, 24)
                }
            }
        }
    }

    return PreviewWrapper()
}
