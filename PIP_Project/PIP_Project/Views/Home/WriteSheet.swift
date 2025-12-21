//
//  WriteSheet.swift
//  PIP_Project
//
//  Card-based data input sheet with Liquid Glass UI
//

import SwiftUI

struct WriteSheet: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var currentCardIndex = 0
    @State private var cardData: [CardData] = []
    @State private var cardInputsDict: [UUID: [String: Any]] = [:]
    @State private var textInputsDict: [UUID: String] = [:]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Header with close button
                HStack {
                    // Close button (back to railroad)
                    LiquidGlassButton(
                        systemIcon: "xmark",
                        size: 44,
                        isCircle: true
                    ) {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    // Progress indicator
                    LiquidGlassContainer(cornerRadius: 16) {
                        Text("\(currentCardIndex + 1) / \(cardData.count)")
                            .font(.pip.body)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Card stack
                ZStack {
                    ForEach(Array(cardData.enumerated()), id: \.element.id) { index, card in
                        if index >= currentCardIndex && index < currentCardIndex + 3 {
                            SwipeableCardView(
                                card: card,
                                index: index - currentCardIndex,
                                isLast: currentCardIndex == cardData.count - 1,
                                onSwipeLeft: {
                                    withAnimation(.spring()) {
                                        if currentCardIndex < cardData.count - 1 {
                                            currentCardIndex += 1
                                        }
                                    }
                                },
                                onSwipeRight: {
                                    withAnimation(.spring()) {
                                        currentCardIndex = max(0, currentCardIndex - 1)
                                    }
                                },
                                onCheck: {
                                    saveCurrentCard()
                                    if currentCardIndex < cardData.count - 1 {
                                        withAnimation(.spring()) {
                                            currentCardIndex += 1
                                        }
                                    } else {
                                        dismiss()
                                    }
                                },
                                onReturn: currentCardIndex > 0 ? {
                                    withAnimation(.spring()) {
                                        currentCardIndex = max(0, currentCardIndex - 1)
                                    }
                                } : nil,
                                cardInputs: Binding(
                                    get: { cardInputsDict[card.id] ?? [:] },
                                    set: { cardInputsDict[card.id] = $0 }
                                ),
                                textInput: Binding(
                                    get: { textInputsDict[card.id] ?? "" },
                                    set: { textInputsDict[card.id] = $0 }
                                )
                            )
                            .offset(x: CGFloat(index - currentCardIndex) * 15)
                            .scaleEffect(1.0 - CGFloat(abs(index - currentCardIndex)) * 0.04)
                            .zIndex(Double(cardData.count - index))
                        }
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            cardData = viewModel.generateCards()
        }
    }
    
    private func saveCurrentCard() {
        guard currentCardIndex < cardData.count else { return }
        let card = cardData[currentCardIndex]
        let inputs = cardInputsDict[card.id] ?? [:]
        let textInput = textInputsDict[card.id] ?? ""
        
        viewModel.saveCardData(card, inputs: inputs, textInput: textInput)
    }
}

#Preview {
    WriteSheet(viewModel: HomeViewModel())
}
