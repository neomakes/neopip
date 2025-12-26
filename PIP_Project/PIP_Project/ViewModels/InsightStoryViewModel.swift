import Foundation
import Combine

@MainActor
class InsightStoryViewModel: ObservableObject {
    @Published var insightStory: InsightStory?
    @Published var currentPageIndex: Int = 0
    @Published var currentPageProgress: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var shouldDismiss: Bool = false

    private let dataService: DataServiceProtocol
    private let cardId: String
    private var cancellables = Set<AnyCancellable>()
    private var pageAdvanceTimer: Timer?
    private var progressTimer: Timer?

    init(dataService: DataServiceProtocol? = nil, cardId: String) {
        self.dataService = dataService ?? MockDataService.shared
        self.cardId = cardId
        fetchInsightStory()
    }

    func fetchInsightStory() {
        isLoading = true
        dataService.fetchInsightStory(for: cardId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                switch completion {
                case .failure(let error):
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] (story: InsightStory) in
                guard let self = self else { return }
                
                // Ensure pages are sorted by pageNumber before assigning
                var sortedStory = story
                sortedStory.pages = story.pages.sorted { $0.pageNumber < $1.pageNumber }

                // Update all state immediately
                self.insightStory = sortedStory
                self.isLoading = false  // ← 핵심: 여기서도 false로 설정!
                self.currentPageIndex = 0
                self.startTimers()
                
                print("DEBUG: Loaded InsightStory id=\(sortedStory.id), title=\(sortedStory.title), pages=\(sortedStory.pages.count)")
                for p in sortedStory.pages {
                    print("DEBUG: Page \(p.pageNumber) - headline: \(p.headline.prefix(40)), imageName: \(p.imageName)")
                }
            })
            .store(in: &cancellables)
    }

    func next() {
        guard let story = insightStory else { 
            print("DEBUG: next() called but no story loaded")
            return 
        }
        if currentPageIndex < story.pages.count - 1 {
            currentPageIndex += 1
            currentPageProgress = 0.0
            print("DEBUG: next() called, currentPageIndex now: \(currentPageIndex), total pages: \(story.pages.count)")
        } else {
            print("DEBUG: next() called but already at last page (\(currentPageIndex + 1)/\(story.pages.count))")
        }
    }

    func previous() {
        if currentPageIndex > 0 {
            currentPageIndex -= 1
            currentPageProgress = 0.0
            print("DEBUG: previous() called, currentPageIndex now: \(currentPageIndex)")
        } else {
            print("DEBUG: previous() called but already at first page")
        }
    }

    func toggleLike() {
        guard var story = insightStory else { return }
        story.isLiked.toggle()
        insightStory = story
        
        // In a production app, you would call the data service here to persist the change:
        // dataService.updateInsightCard(story)
    }
    
    func startTimers() {
        stopTimers() // 기존 타이머 정리
        currentPageProgress = 0.0
        
        // Progress timer: update progress every 0.1 seconds
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.currentPageProgress += 0.1 / 3.0 // 3 seconds total
                if self.currentPageProgress >= 1.0 {
                    self.currentPageProgress = 1.0
                }
            }
        }
        
        // Page advance timer: advance every 3 seconds
        pageAdvanceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self, let story = self.insightStory else { return }
                if self.currentPageIndex < story.pages.count - 1 {
                    print("DEBUG: Auto-advancing to next page")
                    self.next()
                } else {
                    print("DEBUG: Reached last page, stopping auto-advance")
                    self.stopTimers()
                }
            }
        }
    }
    
    func stopTimers() {
        pageAdvanceTimer?.invalidate()
        pageAdvanceTimer = nil
        progressTimer?.invalidate()
        progressTimer = nil
        
        // 마지막 페이지 도달 시 자동 dismiss 트리거
        if let story = insightStory, currentPageIndex == story.pages.count - 1 {
            print("⏱️ [InsightStoryViewModel] Last page reached, auto-dismissing in 2 seconds")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.shouldDismiss = true
            }
        }
    }
    
    func pauseTimers() {
        pageAdvanceTimer?.invalidate()
        pageAdvanceTimer = nil
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    func resumeTimers() {
        startTimers()
    }
}
