//
//  SwipeableCardView.swift
//  PIP_Project
//
//  Tinder-style swipeable card with Liquid Glass buttons
//

import SwiftUI

struct SwipeableCardView: View {
    let card: CardData
    let index: Int
    let isLast: Bool
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let onCheck: () -> Void
    let onReturn: (() -> Void)?
    
    @Binding var cardInputs: [String: Any]
    @Binding var textInput: String
    
    @State private var dragOffset = CGSize.zero
    @FocusState private var isTextFieldFocused: Bool
    
    init(card: CardData, index: Int, isLast: Bool = false, onSwipeLeft: @escaping () -> Void, onSwipeRight: @escaping () -> Void, onCheck: @escaping () -> Void, onReturn: (() -> Void)?, cardInputs: Binding<[String: Any]>, textInput: Binding<String>) {
        self.card = card
        self.index = index
        self.isLast = isLast
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
                    if abs(value.translation.width) > threshold && !isTextFieldFocused {
                        if value.translation.width > 0 {
                            onSwipeRight()
                        } else {
                            onSwipeLeft()
                        }
                    }
                    withAnimation(.spring()) {
                        dragOffset = .zero
                    }
                }
        )
    }
}

// MARK: - Card Content View
struct CardContentView: View {
    let card: CardData
    let isLast: Bool
    @Binding var inputs: [String: Any]
    @Binding var textInput: String
    @FocusState var isTextFieldFocused: Bool
    let onCheck: () -> Void
    let onReturn: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text(card.title)
                .font(.pip.title1)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
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
                .lineLimit(3...6)
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
                
                // Save/Check button
                Button(action: {
                    isTextFieldFocused = false
                    onCheck()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isLast ? "checkmark.circle.fill" : "arrow.right")
                        Text(isLast ? "Save" : "Next")
                    }
                    .font(.pip.body)
                    .foregroundColor(.pip.home.buttonCheck)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: CGFloat.PIPLayout.writeSheetWidth, height: CGFloat.PIPLayout.writeSheetHeight)
        .background(
            RoundedRectangle(cornerRadius: CGFloat.PIPLayout.writeSheetCornerRadius)
                .fill(Color.black.opacity(0.8))
        )
        .onTapGesture {
            // Dismiss keyboard on tap outside
            isTextFieldFocused = false
        }
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
                    
                    Text("\(Int(getSliderValue(key: key, defaultValue: defaultValue)))")
                        .font(.pip.title2)
                        .foregroundColor(.pip.home.numRecords)
                }
                
                Slider(
                    value: Binding(
                        get: { getSliderValue(key: key, defaultValue: defaultValue) },
                        set: { inputs[key] = $0 }
                    ),
                    in: range,
                    step: 1
                )
                .tint(.pip.home.buttonAddGrad1)
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
        }
    }
    
    private func getSliderValue(key: String, defaultValue: Double) -> Double {
        if let value = inputs[key] as? Double {
            return value
        }
        return defaultValue
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
                        type: .mind,
                        title: "How was your mood today?",
                        inputs: [
                            .slider(key: "mood", label: "Mood", range: 0...100, value: 75),
                            .slider(key: "stress", label: "Stress", range: 0...100, value: 30)
                        ],
                        textInput: .optional(key: "notes", placeholder: "Today's note")
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
