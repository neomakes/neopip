import Foundation
import Combine

@MainActor
class ProgramStoryViewModel: ObservableObject {
    @Published var programStory: ProgramStory?
    @Published var currentPageIndex: Int = 0
    @Published var currentPageProgress: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var shouldDismiss: Bool = false
    @Published var isPaused: Bool = false
    @Published var isLiked: Bool = false

    private let program: Program
    private let progress: ProgramProgress?
    private var cancellables = Set<AnyCancellable>()
    private var storyTimer: Timer?
    private let storyDuration: TimeInterval = 5.0 // 한 페이지당 지속시간

    init(program: Program, progress: ProgramProgress?) {
        self.program = program
        self.progress = progress
        // original behavior: load story immediately (may run in app runtime contexts)
        loadStory()
    }

    // MARK: - Data Loading
    func loadStory() {
        isLoading = true
        
        print("DEBUG: Loading story for program: \(program.name)")
        print("DEBUG: Program ID: \(program.id)")
        
        // Load story from MockDataService
        let ongoingStories = MockDataService.shared.loadOngoingProgramStories()
        print("DEBUG: Found \(ongoingStories.count) ongoing stories")
        
        for story in ongoingStories {
            print("DEBUG: Story programId: \(story.programId)")
        }
        
        if let story = ongoingStories.first(where: { $0.programId == program.id }) {
            print("DEBUG: Found story in ongoing_programs")
            self.programStory = story
            self.isLiked = story.isLiked
            self.isLoading = false
            self.startStoryTimer()
        } else {
            print("DEBUG: Story not found for this program — generating default story")
            // Fallback: generate a default ProgramStory based on Program metadata so UI can present something
            let defaultStory = createDefaultStoryFromProgram(program: program)
            self.programStory = defaultStory
            self.isLiked = defaultStory.isLiked
            self.isLoading = false
            self.startStoryTimer()
        }
    }

    // MARK: - Story Navigation
    func goToNextStory() {
        guard let story = programStory else { return }
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
        guard let story = programStory else { return }
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
            Task { @MainActor in
                await self?.updateProgress()
            }
        }
    }

    private func updateProgress() {
        guard !isPaused, let story = programStory, currentPageIndex < story.pages.count else { return }

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
        isLiked.toggle()
        if var story = programStory {
            story.isLiked = isLiked
            programStory = story
        }
        // TODO: Persist this change via dataService
    }

    func dismissStory() {
        stopStoryTimer()
        shouldDismiss = true
    }

    // MARK: - Fallback story generation
    private func createDefaultStoryFromProgram(program: Program) -> ProgramStory {
        let page1 = ProgramStoryPage(
            pageNumber: 1,
            contentType: .text,
            content: ProgramStoryPageContent(headline: "Welcome to \(program.name)", body: program.description, imageName: nil, mantra: nil)
        )

        let stepDescriptions = program.steps.prefix(3).map { "• \($0.title)" }.joined(separator: "\n")
        let page2 = ProgramStoryPage(
            pageNumber: 2,
            contentType: .tip,
            content: ProgramStoryPageContent(headline: "Key Steps", body: stepDescriptions.isEmpty ? "Follow the program steps to progress." : stepDescriptions, imageName: nil, mantra: "Consistency is key")
        )

        let page3 = ProgramStoryPage(
            pageNumber: 3,
            contentType: .motivation,
            content: ProgramStoryPageContent(headline: nil, body: nil, imageName: nil, mantra: "You are capable of amazing things")
        )

        let story = ProgramStory(
            id: UUID(),
            programId: program.id,
            title: program.name,
            subtitle: program.description,
            pages: [page1, page2, page3],
            colorTheme: program.gemVisualization.colorTheme,
            gradientColors: program.gemVisualization.gradientColors?.compactMap { ColorThemeForGoal(rawValue: $0) },
            isViewed: false,
            createdAt: Date(),
            isGenerated: true
        )

        return story
    }
}