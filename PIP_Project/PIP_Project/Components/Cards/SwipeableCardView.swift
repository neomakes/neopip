//
//  SwipeableCardView.swift
//  PIP_Project
//
//  Tinder-style swipeable card with Liquid Glass buttons
//  Updated to support Human World Model inputs (Activity List)
//

import SwiftUI

struct SwipeableCardView: View {
    let card: CardData
    let index: Int
    let positionFromTop: Int
    let isLast: Bool
    let isTop: Bool
    let currentPage: Int?
    let totalPages: Int?
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let onCheck: () -> Void
    let onReturn: (() -> Void)?
    
    @Binding var cardInputs: [String: Any]
    @Binding var textInput: String
    
    @State private var dragOffset = CGSize.zero
    @FocusState private var isTextFieldFocused: Bool
    
    init(card: CardData, index: Int, positionFromTop: Int = 0, isLast: Bool = false, isTop: Bool = false, currentPage: Int? = nil, totalPages: Int? = nil, onSwipeLeft: @escaping () -> Void, onSwipeRight: @escaping () -> Void, onCheck: @escaping () -> Void, onReturn: (() -> Void)?, cardInputs: Binding<[String: Any]>, textInput: Binding<String>) {
        self.card = card
        self.index = index
        self.positionFromTop = positionFromTop
        self.isLast = isLast
        self.isTop = isTop
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
        self.onCheck = onCheck
        self.onReturn = onReturn
        self._cardInputs = cardInputs
        self._textInput = textInput
    }
    
    var body: some View {
        CardContentView(
            card: card,
            isLast: isLast,
            isTop: isTop,
            positionFromTop: positionFromTop,
            currentPage: currentPage,
            totalPages: totalPages,
            inputs: $cardInputs,
            textInput: $textInput,
            isTextFieldFocused: _isTextFieldFocused,
            onCheck: onCheck,
            onReturn: onReturn
        )
        .offset(dragOffset)
        .rotationEffect(.degrees(Double(dragOffset.width / 25)))
        .opacity(1.0 - Double(abs(dragOffset.width)) / 500.0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Disable drag when keyboard is shown
                    if !isTextFieldFocused {
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    let threshold: CGFloat = 100
                    guard !isTextFieldFocused else {
                        withAnimation(.spring()) { dragOffset = .zero }
                        return
                    }

                    let horizontal = value.translation.width
                    if abs(horizontal) > threshold {
                        // Animate card off-screen, then call handler
                        withAnimation(.interpolatingSpring(stiffness: 200, damping: 22)) {
                            dragOffset = CGSize(width: horizontal > 0 ? 900 : -900, height: value.translation.height)
                        }

                        // Delay to allow animation to play before mutating data
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                            if horizontal > 0 {
                                onSwipeRight()
                            } else {
                                onSwipeLeft()
                            }
                            // Reset dragOffset quickly after action
                            dragOffset = .zero
                        }
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
                }
        )
    }
}

// MARK: - Card Content View
struct CardContentView: View {
    let card: CardData
    let isLast: Bool
    let isTop: Bool
    let positionFromTop: Int
    let currentPage: Int?
    let totalPages: Int?
    @Binding var inputs: [String: Any]
    @Binding var textInput: String
    @FocusState var isTextFieldFocused: Bool
    let onCheck: () -> Void
    let onReturn: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            // Title & Subtitle
            VStack(spacing: 8) {
                Text(card.title)
                    .font(.pip.title1)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if let subtitle = card.subtitle {
                    Text(subtitle)
                        .font(.pip.body)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 20)
            
            // Input fields
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(card.inputs.indices, id: \.self) { index in
                        CardInputView(
                            input: card.inputs[index],
                            inputs: $inputs
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20) // Extra padding for scroll
            }
            
            // Text input (with keyboard handling)
            if let textInputConfig = card.textInput {
                let placeholder: String = {
                    switch textInputConfig {
                    case .required(_, let placeholder):
                        return placeholder
                    case .optional(_, let placeholder):
                        return placeholder
                    }
                }()
                
                TextField(
                    placeholder,
                    text: $textInput,
                    axis: .vertical
                )
                .font(.pip.body)
                .foregroundColor(.white)
                .lineLimit(4...8) // Increased size per user request
                .padding(16)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .focused($isTextFieldFocused)
            }
            
            // Bottom buttons
            HStack(spacing: 16) {
                // Return button
                if let onReturn = onReturn {
                    Button(action: onReturn) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                        .font(.pip.body)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // Page indicator
            if let current = currentPage, let total = totalPages, isTop {
                Text("\(current) / \(total)")
                    .font(.pip.body)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 8)
                    .padding(.bottom, 12)
            }
        }
        .frame(width: CGFloat.PIPLayout.writeSheetWidth, height: CGFloat.PIPLayout.writeSheetHeight - CGFloat(positionFromTop) * 22 - (isTop ? 24 : 0))
        .background(
            RoundedRectangle(cornerRadius: CGFloat.PIPLayout.writeSheetCornerRadius)
                .fill(Color.black.opacity(clampedOpacity()))
                .overlay(
                    // Neon stroke for the front-most card
                    Group {
                        if isTop {
                            RoundedRectangle(cornerRadius: CGFloat.PIPLayout.writeSheetCornerRadius)
                                .stroke(LinearGradient(colors: [Color.pip.tabBar.buttonAddGrad1, Color.pip.tabBar.buttonAddGrad2], startPoint: .leading, endPoint: .trailing), lineWidth: 3)
                                .shadow(color: Color.pip.tabBar.buttonAddGrad1.opacity(0.5), radius: 8, x: 0, y: 0)
                                .blur(radius: 4)
                        }
                    }
                )
        )
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
    
    private func clampedOpacity() -> Double {
        if isTop { return 1.0 }
        let base: Double = 0.88
        let opacity = base - Double(positionFromTop - 1) * 0.06
        return max(0.56, opacity)
    }
}

// MARK: - Card Input View
struct CardInputView: View {
    let input: CardInput
    @Binding var inputs: [String: Any]
    
    var body: some View {
        switch input {
        case .slider(let key, let label, let range, let defaultValue):
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(label)
                        .font(.pip.body)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    // Display Float with 1 decimal for Fulfillment (1.0 - 5.0)
                    let val = getSliderValue(key: key, defaultValue: defaultValue)
                    Text(String(format: "%.1f", val))
                        .font(.pip.title2)
                        .foregroundColor(.pip.home.numRecords)
                }
                
                GradientSlider(
                    value: Binding(
                        get: { getSliderValue(key: key, defaultValue: defaultValue) },
                        set: { inputs[key] = $0 }
                    ),
                    range: range,
                    step: 0.1
                )
            }
            .padding(.vertical, 8)
            
        case .toggle(let key, let label, let defaultValue):
            Toggle(label, isOn: Binding(
                get: { inputs[key] as? Bool ?? defaultValue },
                set: { inputs[key] = $0 }
            ))
            .font(.pip.body)
            .foregroundColor(.white)
            .tint(.pip.home.buttonAddGrad1)
            .padding(.vertical, 8)
            
        case .picker(let key, let label, let options, let selectedIndex):
            HStack {
                Text(label)
                    .font(.pip.body)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Picker("", selection: Binding(
                    get: { inputs[key] as? Int ?? selectedIndex },
                    set: { inputs[key] = $0 }
                )) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        Text(option).tag(index)
                    }
                }
                .pickerStyle(.menu)
                .tint(.pip.home.numRecords)
            }
            .padding(.vertical, 8)

        case .timeSlotChart(let key, let label, let range, let defaultValues, let defaultTimes):
            TimeSlotCurveChart(
                values: Binding(
                    get: { getTimeSlotValues(key: key, defaultValues: defaultValues) },
                    set: { inputs[key] = $0 }
                ),
                times: Binding(
                    get: {
                        if let t = inputs["\(key)_times"] as? [Double] { return t }
                        return defaultTimes // Provide defaults if missing
                    },
                    set: { inputs["\(key)_times"] = $0 }
                ),
                range: range,
                label: label
            )
            .padding(.vertical, 8)
            
        case .activityList(let key, let label, let limit):
            ActivityListInputView(key: key, label: label, limit: limit, inputs: $inputs)
                .padding(.vertical, 8)
        }
    }

    private func getSliderValue(key: String, defaultValue: Double) -> Double {
        if let value = inputs[key] as? Double {
            return value
        }
        return defaultValue
    }

    private func getTimeSlotValues(key: String, defaultValues: [Double]) -> [Double] {
        if let values = inputs[key] as? [Double], values.count == defaultValues.count {
            return values
        }
        return defaultValues
    }
}

// MARK: - Activity List Input View
struct ActivityListInputView: View {
    let key: String
    let label: String
    let limit: Int
    @Binding var inputs: [String: Any]
    
    var interventions: [Intervention] {
        get { inputs[key] as? [Intervention] ?? [] }
        set { inputs[key] = newValue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.pip.body)
                .foregroundColor(.white.opacity(0.8))
            
            ForEach(Array(interventions.enumerated()), id: \.element.id) { index, intervention in
                ActivityRow(intervention: Binding(
                    get: { 
                        guard index < self.interventions.count else { return intervention }
                        return self.interventions[index] 
                    },
                    set: { newValue in
                        guard index < self.interventions.count else { return }
                        var list = self.interventions
                        list[index] = newValue
                        self.inputs[self.key] = list
                    }
                ), onDelete: {
                    var list = self.interventions
                    if index < list.count {
                        list.remove(at: index)
                        self.inputs[self.key] = list
                    }
                })
            }
            
            if interventions.count < limit {
                Button(action: {
                    var list = interventions
                    // Default new activity
                    list.append(Intervention(type: .work, amount: 50, mindset: .flow))
                    inputs[key] = list
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Activity")
                    }
                    .font(.pip.body)
                    .foregroundColor(.pip.home.buttonAddGrad1)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
            }
        }
    }
}

struct ActivityRow: View {
    @Binding var intervention: Intervention
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Activity Type Picker
                HStack {
                    // Icon based on type
                    Image(systemName: getActivityIcon(intervention.type))
                        .foregroundColor(.white)
                    
                    Picker("Type", selection: $intervention.type) {
                        ForEach(ActivityType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .tint(.white)
                }
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Custom Label input if "Other" is selected
            if intervention.type == .other {
                TextField("Specify activity...", text: Binding(
                    get: { intervention.customLabel ?? "" },
                    set: { intervention.customLabel = $0 }
                ))
                .font(.pip.caption)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(.white)
            }
            
            // Intensity Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Intensity")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("\(Int(intervention.amount))")
                        .font(.caption)
                        .foregroundColor(.pip.home.numRecords)
                }
                
                GradientSlider(value: $intervention.amount, range: 0...100, step: 5)
            }
            
            // Mindset Picker
            HStack {
                Text("Mindset")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Picker("Mindset", selection: $intervention.mindset) {
                    ForEach(Mindset.allCases, id: \.self) { mindset in
                        Text(mindset.rawValue.capitalized).tag(mindset)
                    }
                }
                .pickerStyle(.menu)
                .tint(.pip.home.numRecords)
            }
            
            // Custom Label input if "Other" Mindset is selected
            if intervention.mindset == .other {
                TextField("Describe mindset...", text: Binding(
                    get: { intervention.customMindsetLabel ?? "" },
                    set: { intervention.customMindsetLabel = $0 }
                ))
                .font(.pip.caption)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(.white)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    func getActivityIcon(_ type: ActivityType) -> String {
        switch type {
        case .work: return "briefcase.fill"
        case .exercise: return "figure.run"
        case .rest: return "moon.zzz.fill"
        case .sleep: return "bed.double.fill"
        case .social: return "person.2.fill"
        case .hobby: return "paintpalette.fill"
        case .chore: return "house.fill"
        case .transit: return "car.fill"
        case .eat: return "fork.knife"
        case .other: return "questionmark.circle.fill"
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var cardInputs: [String: Any] = [:]
        @State private var textInput: String = ""
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                SwipeableCardView(
                    card: CardData(
                        type: .action,
                        title: "Action Card",
                        subtitle: "What did you do today?",
                        inputs: [
                            .activityList(key: "actions", label: "Activities", limit: 3)
                        ],
                        textInput: .optional(key: "notes", placeholder: "Notes...")
                    ),
                    index: 0,
                    isLast: false,
                    onSwipeLeft: {},
                    onSwipeRight: {},
                    onCheck: {},
                    onReturn: { print("Return") },
                    cardInputs: $cardInputs,
                    textInput: $textInput
                )
            }
        }
    }
    
    return PreviewWrapper()
}

// MARK: - Gradient Slider
struct GradientSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height: CGFloat = 6
            let trackHeight: CGFloat = 6
            let thumbSize: CGFloat = 20
            
            let percent = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let restrictedPercent = min(max(percent, 0), 1)
            let fillWidth = max(0, width * CGFloat(restrictedPercent))
            
            ZStack(alignment: .leading) {
                // Background Track
                RoundedRectangle(cornerRadius: trackHeight/2)
                    .fill(Color.white.opacity(0.15))
                    .frame(height: trackHeight)
                
                // Active Gradient Track
                RoundedRectangle(cornerRadius: trackHeight/2)
                    .fill(
                        LinearGradient(
                            colors: [.pip.home.buttonAddGrad1, .pip.home.buttonAddGrad2],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth, height: trackHeight)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                    .offset(x: fillWidth - (thumbSize / 2))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                let locationX = v.location.x
                                let newPercent = locationX / width
                                let newValue = range.lowerBound + (newPercent * (range.upperBound - range.lowerBound))
                                
                                // Snap logic
                                let steppedValue = round(newValue / step) * step
                                self.value = min(max(steppedValue, range.lowerBound), range.upperBound)
                            }
                    )
            }
            .frame(height: thumbSize) // Container height
            .alignmentGuide(VerticalAlignment.center) { d in d[VerticalAlignment.center] }
        }
        .frame(height: 20)
    }
}
