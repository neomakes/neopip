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
    @Published var isPaused: Bool = false

    private let dataService: DataServiceProtocol
    private let cardId: String
    private var cancellables = Set<AnyCancellable>()
    private var storyTimer: Timer?
    private let storyDuration: TimeInterval = 5.0 // 한 페이지당 지속시간

    init(dataService: DataServiceProtocol? = nil, cardId: String) {
        self.dataService = dataService ?? MockDataService.shared
        self.cardId = cardId
        fetchInsightStory()
    }
    
    // MARK: - Data Fetching
    func fetchInsightStory() {
        isLoading = true
        dataService.fetchInsightStory(for: cardId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] story in
                guard let self = self else { return }
                var sortedStory = story
                sortedStory.pages = story.pages.sorted { $0.pageNumber < $1.pageNumber }

                self.insightStory = sortedStory
                self.isLoading = false
                self.currentPageIndex = 0
                self.startStoryTimer()
            })
            .store(in: &cancellables)
    }

    // MARK: - Story Navigation
    func goToNextStory() {
        guard let story = insightStory else { return }
        if currentPageIndex < story.pages.count - 1 {
            currentPageIndex += 1
            resetCurrentPage()
        } else {
            // 마지막 페이지에서 다음으로 넘기려고 하면 닫기
            dismissStory()
        }
    }

    func goToPreviousStory() {
        if currentPageIndex > 0 {
            currentPageIndex -= 1
            resetCurrentPage()
        } else {
            // 첫 페이지에서 이전으로 넘기려고 하면 닫기 (선택적)
            // 또는 첫 페이지 처음부터 다시 재생
            resetCurrentPage()
        }
    }
    
    private func advanceToNextPage() {
        guard let story = insightStory else { return }
        if currentPageIndex < story.pages.count - 1 {
            currentPageIndex += 1
            currentPageProgress = 0.0
        } else {
            dismissStory()
        }
    }
    
    // MARK: - Timer and Progress Control
    func startStoryTimer() {
        stopStoryTimer()
        currentPageProgress = 0.0
        
        storyTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }

    private func updateProgress() {
        guard !isPaused, let story = insightStory, currentPageIndex < story.pages.count else { return }
        
        let increment = 0.05 / storyDuration
        currentPageProgress += increment
        
        if currentPageProgress >= 1.0 {
            advanceToNextPage()
        }
    }
    
    func stopStoryTimer() {
        storyTimer?.invalidate()
        storyTimer = nil
    }

    func pauseStory() {
        isPaused = true
    }

    func resumeStory() {
        isPaused = false
    }

    private func resetCurrentPage() {
        currentPageProgress = 0.0
        // 타이머를 재시작하여 현재 페이지부터 다시 진행
        startStoryTimer()
    }

    // MARK: - Actions
    func toggleLike() {
        insightStory?.isLiked.toggle()
        // TODO: Persist this change via dataService
    }

    func dismissStory() {
        stopStoryTimer()
        shouldDismiss = true
    }
}
