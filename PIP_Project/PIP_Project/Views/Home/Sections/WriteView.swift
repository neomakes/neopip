import SwiftUI

struct WriteView: View {
    let isPresented: Binding<Bool>?
    @StateObject private var viewModel = WriteViewModel()

    @State private var cards: [CardData] = []
    @State private var cardInputs: [[String: Any]] = []
    @State private var textInputs: [String] = []
    @State private var isSaving: Bool = false
    @State private var alertMessage: String?
    @State private var totalCardsCount: Int = 3
    
    // 현재 페이지 계산 (전체 - 남은카드 + 1). 카드가 없으면 0.
    private var currentPage: Int {
        guard !cards.isEmpty else { return 0 }
        return totalCardsCount - cards.count + 1
    }

    init(isPresented: Binding<Bool>? = nil) {
        self.isPresented = isPresented
    }

    var body: some View {
        ZStack {
            // Primary background behind the card stack
            PrimaryBackground().ignoresSafeArea()

            if cards.isEmpty || viewModel.isRestoring {
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
        // DB에서 오늘 데이터가 있는지 확인하고 로드 (Draft가 없으면)
        viewModel.checkAndLoadTodayData()

        // 로컬 캐시 존재 여부: accumulatedValues에 실제 데이터가 있는지 확인
        // cachedInputs는 기본값으로 채워질 수 있으므로, accumulatedValues를 기준으로 판단
        let hasRealData = viewModel.hasAccumulatedData()

        if hasRealData {
            print("WriteView: Real data exists in accumulation. Proceeding immediately.")
            performSetupCards()
            return
        }

        // 실제 데이터가 없고 ViewModel이 복원 중이면 대기 (DB에서 가져오는 중)
        guard !viewModel.isRestoring else {
            print("WriteView: No real data, ViewModel is restoring from DB, waiting...")
            Task {
                // isRestoring이 false가 될 때까지 대기
                while viewModel.isRestoring {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                }
                await MainActor.run {
                    self.performSetupCards()
                }
            }
            return
        }

        performSetupCards()
    }

    private func performSetupCards() {
        // 1. 전체 카드 수 확인
        let totalCount = viewModel.getTotalCardsCount()
        self.totalCardsCount = totalCount

        // 2. 이미 처리된 카드를 제외하고 남은 카드만 가져오기 (Draft Restoration)
        let remainingCards = viewModel.getRemainingCards()
        self.cards = remainingCards

        // 3. 현재 페이지 번호 계산 (Computed property currentPage가 자동 처리)
        print("WriteView: Restoration - Total: \(totalCount), Remaining: \(remainingCards.count), Current: \(currentPage)")

        // 남은 카드가 없으면 자동 닫기 (또는 완료 화면)
        if remainingCards.isEmpty {
            print("WriteView: All cards completed. Dismissing.")
            isPresented?.wrappedValue = false
            return
        }

        // ViewModel에서 캐시 복원 시도 (DB 복원 후 cachedInputs가 설정되었을 수 있음)
        // restoreInputsFromAccumulation()이 호출되면 cachedInputs가 업데이트됨
        viewModel.refreshCachedInputsIfNeeded()

        // cachedInputs 처리 (남은 카드에 대한 캐시만 적용)
        if viewModel.cachedInputs.count == remainingCards.count && !viewModel.cachedInputs.isEmpty {
            self.cardInputs = viewModel.cachedInputs
            print("WriteView: Loaded cached inputs for \(remainingCards.count) cards")
        } else {
            // Default Inputs 생성
            self.cardInputs = remainingCards.map { card in
                var dict: [String: Any] = [:]
                for input in card.inputs {
                    switch input {
                    case .slider(let key, _, _, let defaultValue): dict[key] = defaultValue
                    case .toggle(let key, _, let defaultValue): dict[key] = defaultValue
                    case .picker(let key, _, _, let selectedIndex): dict[key] = selectedIndex
                    case .timeSlotChart(let key, _, _, let defaultValues, let defaultTimes): 
                        dict[key] = defaultValues
                        dict["\(key)_times"] = defaultTimes
                    case .activityList(let key, _, _): dict[key] = []
                    }
                }
                return dict
            }
            // 캐시 초기화
            viewModel.cachedInputs = self.cardInputs
            // viewModel.saveCachedInputs() // REMOVED: Prevent poisoning cache with defaults
            print("WriteView: Initialized default inputs for \(remainingCards.count) cards")
        }

        // 저장된 노트 복원
        if viewModel.cachedTextInputs.count == remainingCards.count && !viewModel.cachedTextInputs.isEmpty {
            self.textInputs = viewModel.cachedTextInputs
            print("WriteView: Loaded cached text inputs")
        } else {
             self.textInputs = remainingCards.map { viewModel.getNotes(for: $0) }
        }
    }

    private func bindingForInputs(at index: Int) -> Binding<[String: Any]> {
        Binding(
            get: {
                guard index < cardInputs.count else { return [:] }
                return cardInputs[index]
            },
            set: { new in
                guard index < cardInputs.count else { return }
                
                var finalInputs = new
                let oldInputs = cardInputs[index]
                
                // Sync Logic for State Card (Mood & Energy Times)
                if cards.indices.contains(index), cards[index].type == .state {
                    let moodTimesKey = "mood_times"
                    let energyTimesKey = "energy_times"
                    
                    let newMoodTimes = finalInputs[moodTimesKey] as? [Double]
                    let oldMoodTimes = oldInputs[moodTimesKey] as? [Double]
                    
                    let newEnergyTimes = finalInputs[energyTimesKey] as? [Double]
                    let oldEnergyTimes = oldInputs[energyTimesKey] as? [Double]
                    
                    // Sync Mood -> Energy (Start/End only)
                    if let nm = newMoodTimes, let om = oldMoodTimes, var ne = newEnergyTimes, !nm.isEmpty, !om.isEmpty, !ne.isEmpty {
                        var changed = false
                        // Sync Start
                        if nm.first != om.first {
                            ne[0] = nm[0]
                            changed = true
                        }
                        // Sync End
                        if nm.last != om.last {
                            ne[ne.count - 1] = nm[nm.count - 1]
                            changed = true
                        }
                        
                        if changed {
                            finalInputs[energyTimesKey] = ne
                            print("WriteView: Synced Energy start/end times to Mood")
                        }
                    }
                    
                    // Sync Energy -> Mood (Start/End only)
                    if let ne = newEnergyTimes, let oe = oldEnergyTimes, var nm = newMoodTimes, !ne.isEmpty, !oe.isEmpty, !nm.isEmpty {
                        var changed = false
                        // Sync Start
                        if ne.first != oe.first {
                            nm[0] = ne[0]
                            changed = true
                        }
                        // Sync End
                        if ne.last != oe.last {
                            nm[nm.count - 1] = ne[ne.count - 1]
                            changed = true
                        }
                        
                        if changed {
                            finalInputs[moodTimesKey] = nm
                            print("WriteView: Synced Mood start/end times to Energy")
                        }
                    }
                }
                
                cardInputs[index] = finalInputs
                viewModel.updateLocalCache(inputs: finalInputs, for: index)
                print("WriteView: Updated inputs for card \(index)")
            }
        )
    }

    private func bindingForText(at index: Int) -> Binding<String> {
        Binding(
            get: { guard index < textInputs.count else { return "" }; return textInputs[index] },
            set: { new in 
                guard index < textInputs.count else { return }
                textInputs[index] = new 
                viewModel.updateLocalTextCache(text: new, for: index)
            }
        )
    }

    private func defaultInputs(for card: CardData) -> [String: Any] {
        var dict: [String: Any] = [:]
        for input in card.inputs {
            switch input {
            case .slider(let key, _, _, let defaultValue): dict[key] = defaultValue
            case .toggle(let key, _, let defaultValue): dict[key] = defaultValue
            case .picker(let key, _, _, let selectedIndex): dict[key] = selectedIndex
            case .timeSlotChart(let key, _, _, let defaultValues, let defaultTimes): 
                dict[key] = defaultValues
                dict["\(key)_times"] = defaultTimes
            case .activityList(let key, _, _): dict[key] = []
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
            totalPages: idx == 0 ? totalCardsCount : nil,
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
            // move page back (wrap) - Computed property updates automatically
        }
        // Save to cache when card changes
        viewModel.cachedInputs = self.cardInputs
        viewModel.saveCachedInputs()
        print("WriteView: Saved cache on previousCard")
    }

    private func skipCard(at index: Int) {
        guard index < cards.count else { return }
        withAnimation {
            // move skipped card to back - KEEP the current inputs
            let movedCard = cards.remove(at: index)
            let movedInputs = cardInputs.remove(at: index)
            let movedText = textInputs.remove(at: index)

            cards.append(movedCard)
            cardInputs.append(movedInputs)  // Keep existing inputs
            textInputs.append(movedText)    // Keep existing text
            // advance page (wrap) - Computed property updates automatically
        }
        // Save to cache when card changes
        viewModel.cachedInputs = self.cardInputs
        viewModel.saveCachedInputs()
        print("WriteView: Saved cache on skipCard")
    }

    private func saveCard(at index: Int) {
        guard index < cards.count, index < cardInputs.count, index < textInputs.count else { return }
        let card = cards[index]
        let inputs = cardInputs[index]
        let text = textInputs[index]
        
        // 마지막 카드인지 확인 (남은 카드가 1개일 때)
        let isLast = (cards.count == 1)
        
        isSaving = true
        Task {
            do {
                try await viewModel.saveCard(card, inputs: inputs, textInput: text, isLast: isLast)
                await MainActor.run {
                    withAnimation {
                        cards.remove(at: index)
                        cardInputs.remove(at: index)
                        textInputs.remove(at: index)
                        if cards.isEmpty {
                            isPresented?.wrappedValue = false
                        }
                    }
                    print("WriteView: Saved cache on saveCard")
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
