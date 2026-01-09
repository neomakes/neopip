//
//  TimeSlotCurveChart.swift
//  PIP_Project
//
//  Interactive time-slot curve chart for Write cards
//  Allows users to input values for specific time ranges (e.g., excluding sleep hours)
//

import SwiftUI

// MARK: - Time Slot Curve Chart View
struct TimeSlotCurveChart: View {
    @Binding var values: [Double]  // 5 control points
    let range: ClosedRange<Double>
    let label: String

    @State private var selectedControlIndex: Int? = nil
    @State private var isDragging = false
    @State private var dragStartValue: Double? = nil
    @State private var dragStartHour: Double? = nil

    // Control point hours - first/last points are now movable to exclude sleep time etc.
    // Default: 7am to 11pm (awake hours)
    @State private var controlHours: [Double] = [7, 10, 14, 18, 22]

    init(values: Binding<[Double]>, range: ClosedRange<Double> = 0...100, label: String = "Value") {
        self._values = values
        self.range = range
        self.label = label

        // Ensure we have 5 control points
        if values.wrappedValue.count != 5 {
            values.wrappedValue = Array(repeating: (range.lowerBound + range.upperBound) / 2, count: 5)
        }
    }

    // Get the active time range (from first to last control point)
    private var activeStartHour: Double {
        controlHours.min() ?? 0
    }

    private var activeEndHour: Double {
        controlHours.max() ?? 23
    }

    // Interpolate control points within active range using Catmull-Rom spline
    // Returns (hour, value) pairs only for the active time range
    private func interpolatedPoints() -> [(hour: Double, value: Double)] {
        guard values.count == 5 else { return [] }

        // Sort control points by hour
        let sortedIndices = controlHours.indices.sorted { controlHours[$0] < controlHours[$1] }
        let sortedHours = sortedIndices.map { controlHours[$0] }
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

            h += 0.5
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

                if let controlIndex = selectedControlIndex {
                    let hour = Int(controlHours[controlIndex])
                    Text("\(hour):00 - \(Int(values[controlIndex]))")
                        .font(.pip.title2)
                        .foregroundColor(.pip.home.numRecords)
                } else {
                    // Show active time range
                    let startHour = Int(activeStartHour)
                    let endHour = Int(activeEndHour)
                    Text("\(startHour):00 ~ \(endHour):00")
                        .font(.pip.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Curve chart
            GeometryReader { geometry in
                let width = geometry.size.width
                let height: CGFloat = 100
                let stepX = width / 23  // Always map to 24-hour scale

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

                    // Inactive zones (sleep/excluded time) - shown as dimmed areas
                    // Left inactive zone (before first control point)
                    if activeStartHour > 0 {
                        Rectangle()
                            .fill(Color.white.opacity(0.03))
                            .frame(width: CGFloat(activeStartHour) * stepX, height: height)
                            .position(x: CGFloat(activeStartHour) * stepX / 2, y: height / 2)
                    }

                    // Right inactive zone (after last control point)
                    if activeEndHour < 23 {
                        let inactiveWidth = CGFloat(23 - activeEndHour) * stepX
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
                    .stroke(Color.pip.home.buttonAddGrad1, lineWidth: 3)
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
                    .fill(Color.pip.home.buttonAddGrad1.opacity(0.2))

                    // Draggable control points
                    ForEach(0..<5) { controlIndex in
                        controlPointView(for: controlIndex, width: width, height: height)
                    }
                }
                .frame(height: height)
            }
            .frame(height: 100)
            .padding(.vertical, 8)

            // Time labels
            HStack(spacing: 0) {
                ForEach(0..<7) { i in
                    let hour = i * 4
                    Text("\(hour):00")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Control Point View
    private func controlPointView(for controlIndex: Int, width: CGFloat, height: CGFloat) -> some View {
        let value = values[controlIndex]
        let hour = controlHours[controlIndex]
        let isSelected = selectedControlIndex == controlIndex
        let isEndpoint = controlIndex == 0 || controlIndex == 4  // First or last point

        let stepX = width / 23
        let x = CGFloat(hour) * stepX
        let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        let y = height - (CGFloat(normalizedValue) * height)

        return ZStack {
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
                        dragStartHour = self.controlHours[controlIndex]
                    }

                    // Calculate new value (Y-axis)
                    let valueRange = range.upperBound - range.lowerBound
                    let dragSensitivity = valueRange / height
                    let valueDelta = -gesture.translation.height * dragSensitivity
                    let newValue = (dragStartValue ?? self.values[controlIndex]) + valueDelta
                    self.values[controlIndex] = max(range.lowerBound, min(range.upperBound, newValue))

                    // Calculate new hour (X-axis) - ALL points can now move horizontally
                    let hourDelta = gesture.translation.width / stepX
                    var newHour = (dragStartHour ?? self.controlHours[controlIndex]) + Double(hourDelta)

                    // Get sorted control hours to find neighbors
                    let sortedWithIndex = controlHours.enumerated().sorted { $0.element < $1.element }
                    let currentSortedIndex = sortedWithIndex.firstIndex { $0.offset == controlIndex } ?? 0

                    // Determine constraints based on position in sorted order
                    let minHour: Double
                    let maxHour: Double

                    if currentSortedIndex == 0 {
                        // First point (leftmost) - can go from 0 to just before next point
                        minHour = 0
                        maxHour = sortedWithIndex.count > 1 ? sortedWithIndex[1].element - 1 : 23
                    } else if currentSortedIndex == sortedWithIndex.count - 1 {
                        // Last point (rightmost) - can go from just after previous point to 23
                        minHour = sortedWithIndex[currentSortedIndex - 1].element + 1
                        maxHour = 23
                    } else {
                        // Middle points - constrained by neighbors
                        minHour = sortedWithIndex[currentSortedIndex - 1].element + 1
                        maxHour = sortedWithIndex[currentSortedIndex + 1].element - 1
                    }

                    newHour = max(minHour, min(maxHour, newHour))
                    self.controlHours[controlIndex] = newHour
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
        )
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var values: [Double] = [40, 60, 80, 50, 30]

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    TimeSlotCurveChart(values: $values, range: 0...100, label: "Mood Throughout Day")
                        .padding(.horizontal, 24)

                    Spacer()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Values: \(values.map { Int($0) }.description)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        Text("Tip: Drag endpoints left/right to set awake hours")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding()
                }
            }
        }
    }

    return PreviewWrapper()
}
