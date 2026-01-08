import SwiftUI

struct WriteView: View {
    let isPresented: Binding<Bool>?
    @StateObject private var viewModel = WriteViewModel()

    @State private var cards: [CardData] = []
    @State private var cardInputs: [[String: Any]] = []
    @State private var textInputs: [String] = []
    @State private var isSaving: Bool = false
    @State private var alertMessage: String?
    @State private var currentPage: Int = 1

    init(isPresented: Binding<Bool>? = nil) {
        self.isPresented = isPresented
    }

    var body: some View {
        ZStack {
            // Primary background behind the card stack
            PrimaryBackground().ignoresSafeArea()

            if cards.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                }
            } else {
                ZStack {
                    // Render cards with perspective stacking: cards[0] is top
                    ForEach(Array(cards.indices.reversed()), id: \.self) { idx in
                        cardView(at: idx)
                    }
                }
                .padding(.bottom, CGFloat.PIPLayout.safeAreaBottomHeight + 60)

                



            }



            // Top-left back button
            VStack {
                HStack {
                    Button(action: { isPresented?.wrappedValue = false }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                            .accessibilityLabel("뒤로")
                    }
                    .padding(.leading, 16)
                    Spacer()
                }
                .padding(.top, 8)
                Spacer()
            }

            if isSaving {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .onAppear(perform: setupCards)
        .alert("Error", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    // MARK: - Helpers
    private func setupCards() {
        let generated = viewModel.generateCards()
        self.cards = generated
        self.currentPage = 1
        self.cardInputs = generated.map { card in
            var dict: [String: Any] = [:]
            for input in card.inputs {
                switch input {
                case .slider(let key, _, _, let defaultValue): dict[key] = defaultValue
                case .toggle(let key, _, let defaultValue): dict[key] = defaultValue
                case .picker(let key, _, _, let selectedIndex): dict[key] = selectedIndex
                case .timeSlotChart(let key, _, _, let defaultValues): dict[key] = defaultValues
                }
            }
            return dict
        }
        self.textInputs = Array(repeating: "", count: generated.count)
    }

    private func bindingForInputs(at index: Int) -> Binding<[String: Any]> {
        Binding(
            get: {
                guard index < cardInputs.count else { return [:] }
                return cardInputs[index]
            },
            set: { new in
                guard index < cardInputs.count else { return }
                cardInputs[index] = new
            }
        )
    }

    private func bindingForText(at index: Int) -> Binding<String> {
        Binding(
            get: { guard index < textInputs.count else { return "" }; return textInputs[index] },
            set: { new in guard index < textInputs.count else { return }; textInputs[index] = new }
        )
    }

    private func defaultInputs(for card: CardData) -> [String: Any] {
        var dict: [String: Any] = [:]
        for input in card.inputs {
            switch input {
            case .slider(let key, _, _, let defaultValue): dict[key] = defaultValue
            case .toggle(let key, _, let defaultValue): dict[key] = defaultValue
            case .picker(let key, _, _, let selectedIndex): dict[key] = selectedIndex
            case .timeSlotChart(let key, _, _, let defaultValues): dict[key] = defaultValues
            }
        }
        return dict
    }

    @ViewBuilder
    private func cardView(at idx: Int) -> some View {
        let card = cards[idx]
        // positionFromTop: 0 = topmost card, increasing for deeper cards
        let positionFromTop = idx
        SwipeableCardView(
            card: card,
            index: idx,
            positionFromTop: positionFromTop,
            isLast: idx == cards.count - 1,
            isTop: idx == 0,
            currentPage: idx == 0 ? currentPage : nil,
            totalPages: idx == 0 ? cards.count : nil,
            onSwipeLeft: { skipCard(at: idx) },
            onSwipeRight: { saveCard(at: idx) },
            onCheck: { saveCard(at: idx) },
            onReturn: nil,
            cardInputs: bindingForInputs(at: idx),
            textInput: bindingForText(at: idx)
        )
        // front card larger, deeper cards progressively smaller
        // Top card moved down slightly to avoid overlapping the back button but kept above the TabBar
        .offset(y: idx == 0 ? 32 : -CGFloat(positionFromTop) * 12)
        .scaleEffect(1.0 - CGFloat(positionFromTop) * 0.06)
        .opacity(1.0 - Double(positionFromTop) * 0.01)
        .shadow(color: Color.pip.tabBar.buttonAddGrad1.opacity(idx == 0 ? 0.36 : 0.16), radius: idx == 0 ? 30 : 8, x: 0, y: 6)
        .zIndex(Double(100 - positionFromTop))
        .animation(.spring(response: 0.36, dampingFraction: 0.75), value: cards.map { $0.id })
    }

    // Move last card to front (previous)
    private func previousCard() {
        guard let last = cards.popLast(), !cards.isEmpty || true else { return }
        withAnimation {
            cards.insert(last, at: 0)
            // also rotate inputs/texts accordingly
            let lastInputs = cardInputs.popLast() ?? defaultInputs(for: last)
            let lastText = textInputs.popLast() ?? ""
            cardInputs.insert(lastInputs, at: 0)
            textInputs.insert(lastText, at: 0)
            // move page back (wrap)
            if cards.count > 0 {
                currentPage = (currentPage - 2 + cards.count) % cards.count + 1
            }
        }
    }

    private func skipCard(at index: Int) {
        guard index < cards.count else { return }
        withAnimation {
            // move skipped card to back without saving
            let movedCard = cards.remove(at: index)
            _ = cardInputs.remove(at: index)
            _ = textInputs.remove(at: index)

            cards.append(movedCard)
            cardInputs.append(defaultInputs(for: movedCard))
            textInputs.append("")
            // advance page (wrap)
            if cards.count > 0 {
                currentPage = currentPage % cards.count + 1
            }
        }
    }

    private func saveCard(at index: Int) {
        guard index < cards.count else { return }
        isSaving = true
        Task {
            let card = cards[index]
            let inputs = cardInputs[index]
            let text = textInputs[index]
            do {
                try await viewModel.saveCard(card, inputs: inputs, textInput: text)
                await MainActor.run {
                    withAnimation {
                        // move card to back instead of removing
                        let movedCard = cards.remove(at: index)
                        _ = cardInputs.remove(at: index)
                        _ = textInputs.remove(at: index)

                        cards.append(movedCard)
                        // reset the inputs for the moved card to defaults
                        cardInputs.append(defaultInputs(for: movedCard))
                        textInputs.append("")
                        // advance page (wrap)
                        if cards.count > 0 {
                            currentPage = currentPage % cards.count + 1
                        }
                    }
                    isSaving = false
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    alertMessage = error.localizedDescription
                }
            }
        }
    }
}


#Preview {
    WriteView()
}
