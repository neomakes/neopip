//
//  TimeSlotBarChart.swift
//  PIP_Project
//
//  Interactive time-slot bar chart for Write cards
//  Allows users to input values for different time periods throughout the day
//

import SwiftUI

// MARK: - Time Slot Model
struct TimeSlot: Identifiable {
    let id = UUID()
    let label: String
    let timeRange: String
    var value: Double  // 0-100
}

// MARK: - Time Slot Bar Chart View
struct TimeSlotBarChart: View {
    @Binding var values: [Double]  // 6 values for 6 time slots
    let range: ClosedRange<Double>
    let label: String

    private let timeSlots: [String] = ["Dawn", "Morning", "Noon", "Afternoon", "Evening", "Night"]
    private let timeRanges: [String] = ["0-4", "4-8", "8-12", "12-16", "16-20", "20-24"]

    @State private var selectedSlotIndex: Int? = nil
    @State private var isDragging = false

    init(values: Binding<[Double]>, range: ClosedRange<Double> = 0...100, label: String = "Value") {
        self._values = values
        self.range = range
        self.label = label

        // Ensure we have 6 values
        if values.wrappedValue.count != 6 {
            values.wrappedValue = Array(repeating: range.lowerBound, count: 6)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            HStack {
                Text(label)
                    .font(.pip.body)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                if let index = selectedSlotIndex {
                    Text("\(timeSlots[index]): \(Int(values[index]))")
                        .font(.pip.title2)
                        .foregroundColor(.pip.home.numRecords)
                } else {
                    Text("Tap bars to adjust")
                        .font(.pip.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<6) { index in
                    barView(for: index)
                }
            }
            .frame(height: 120)
            .padding(.vertical, 8)

            // Time labels
            HStack(spacing: 8) {
                ForEach(0..<6) { index in
                    VStack(spacing: 2) {
                        Text(timeSlots[index])
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text(timeRanges[index])
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Bar View
    private func barView(for index: Int) -> some View {
        let normalizedValue = (values[index] - range.lowerBound) / (range.upperBound - range.lowerBound)
        let isSelected = selectedSlotIndex == index

        return VStack(spacing: 0) {
            Spacer()

            // Bar
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: isSelected ? [
                            Color.pip.home.buttonAddGrad1,
                            Color.pip.home.buttonAddGrad2
                        ] : [
                            Color.pip.home.buttonAddGrad1.opacity(0.6),
                            Color.pip.home.buttonAddGrad2.opacity(0.6)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(maxWidth: .infinity)
                .frame(height: max(8, 120 * CGFloat(normalizedValue)))
                .shadow(
                    color: isSelected ? Color.pip.home.buttonAddGrad1.opacity(0.5) : .clear,
                    radius: 8,
                    x: 0,
                    y: 0
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            isSelected ? Color.white.opacity(0.5) : Color.clear,
                            lineWidth: 2
                        )
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: normalizedValue)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    selectedSlotIndex = index
                    isDragging = true

                    // Calculate value based on vertical drag position
                    let barHeight: CGFloat = 120
                    let yPosition = max(0, min(barHeight, barHeight - value.location.y))
                    let newNormalizedValue = Double(yPosition / barHeight)
                    let newValue = range.lowerBound + newNormalizedValue * (range.upperBound - range.lowerBound)

                    values[index] = max(range.lowerBound, min(range.upperBound, newValue))
                }
                .onEnded { _ in
                    isDragging = false
                    // Keep selection for a moment
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if !isDragging {
                            selectedSlotIndex = nil
                        }
                    }
                }
        )
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var values: [Double] = [30, 50, 70, 60, 40, 20]

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    TimeSlotBarChart(values: $values, range: 0...100, label: "Mood Throughout Day")
                        .padding(.horizontal, 24)

                    Spacer()

                    Text("Values: \(values.map { Int($0) }.description)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                }
            }
        }
    }

    return PreviewWrapper()
}
