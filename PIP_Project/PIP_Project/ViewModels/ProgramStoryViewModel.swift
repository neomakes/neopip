import Foundation
import Combine

@MainActor
class ProgramStoryViewModel: ObservableObject {
    enum StoryMode {
        case overview
        case mission
    }
    
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
    private let mode: StoryMode
    private var cancellables = Set<AnyCancellable>()
    private var storyTimer: Timer?
    private let storyDuration: TimeInterval = 5.0 // 한 페이지당 지속시간

    init(program: Program, progress: ProgramProgress?, mode: StoryMode = .mission) {
        self.program = program
        self.progress = progress
        self.mode = mode
        // original behavior: load story immediately (may run in app runtime contexts)
        loadStory()
    }

    // MARK: - Data Loading
    func loadStory() {
        isLoading = true
        
        print("DEBUG: Loading story for program: \(program.name)")
        
        // 0. Check Mode
        if mode == .overview {
            let defaultStory = createDefaultStoryFromProgram(program: program)
            self.programStory = defaultStory
            self.isLiked = defaultStory.isLiked
            self.isLoading = false
            self.startStoryTimer()
            return
        }
        
        // 1. Calculate Current Day
        let currentDay: Int
        if let progress = progress {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: progress.createdAt, to: Date())
            currentDay = max(1, (components.day ?? 0) + 1)
        } else {
            currentDay = 1
        }
        
        // 2. Try to find mission for Current Day
        if let missions = program.missions, let activeMission = missions.first(where: { $0.day == currentDay }) {
            print("DEBUG: Found active mission for Day \(currentDay): \(activeMission.title)")
            let missionStory = createStoryFromMission(activeMission)
            self.programStory = missionStory
            self.isLiked = false // Default or load from somewhere else
            self.isLoading = false
            self.startStoryTimer()
        } else {
            // 3. Fallback: Check for any existing story (legacy) or create default
            // Load story from MockDataService (Legacy check)
            let ongoingStories = MockDataService.shared.loadOngoingProgramStories()
            
            if let story = ongoingStories.first(where: { $0.programId == program.id }) {
                print("DEBUG: Found story in ongoing_programs (Mock)")
                self.programStory = story
                self.isLiked = story.isLiked
                self.isLoading = false
                self.startStoryTimer()
            } else {
                print("DEBUG: Story/Mission not found - generating default story")
                let defaultStory = createDefaultStoryFromProgram(program: program)
                self.programStory = defaultStory
                self.isLiked = defaultStory.isLiked
                self.isLoading = false
                self.startStoryTimer()
            }
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

    private func createStoryFromMission(_ mission: ProgramMission) -> ProgramStory {
        return ProgramStory(
            id: UUID(),
            programId: program.id,
            title: mission.title,
            subtitle: mission.description,
            pages: mission.contentPages,
            colorTheme: program.gemVisualization.colorTheme,
            gradientColors: program.gemVisualization.gradientColors?.compactMap { ColorThemeForGoal(rawValue: $0) },
            isViewed: mission.isCompleted,
            createdAt: Date(),
            isGenerated: true
        )
    }
    
    // MARK: - Fallback story generation
    private func createDefaultStoryFromProgram(program: Program) -> ProgramStory {
        let page1 = ProgramStoryPage(
            pageNumber: 1,
            contentType: .text,
            content: ProgramStoryPageContent(headline: "Welcome to \(program.name)", body: program.description, imageName: nil, mantra: nil)
        )

        // Use missions if available (lazy fetching means they might be nil here)
        var missionDescriptions = ""
        if let missions = program.missions, !missions.isEmpty {
            missionDescriptions = missions.prefix(3).map { "• \($0.title)" }.joined(separator: "\n")
        } else {
             missionDescriptions = "• Complete daily missions\n• Consistency is key\n• Track your progress"
        }
        
        let page2 = ProgramStoryPage(
            pageNumber: 2,
            contentType: .tip,
            content: ProgramStoryPageContent(headline: "Key Steps", body: missionDescriptions, imageName: nil, mantra: "Consistency is key")
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