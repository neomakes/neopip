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
        loadStory()
    }

    // MARK: - Data Loading
    func loadStory() {
        isLoading = true
        
        print("DEBUG: Loading story for program: \(program.name)")
        print("DEBUG: Story file name: \(program.storyFileName)")
        
        // Load detailed story from programs JSON file
        if let filePath = Bundle.main.path(forResource: program.storyFileName, ofType: "json") {
            print("DEBUG: Found file path: \(filePath)")
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                print("DEBUG: Successfully loaded data, size: \(data.count) bytes")
                self.programStory = try JSONDecoder().decode(ProgramStory.self, from: data)
                self.isLiked = self.programStory?.isLiked ?? false
                print("DEBUG: Successfully decoded ProgramStory")
                self.isLoading = false
                self.startStoryTimer()
            } catch {
                print("DEBUG: Failed to decode JSON: \(error)")
                self.isLoading = false
                self.errorMessage = "Failed to load story data: \(error.localizedDescription)"
            }
        } else {
            print("DEBUG: File not found for resource: \(program.storyFileName).json")
            // List all available resources to debug
            if let bundlePath = Bundle.main.bundlePath as NSString? {
                let jsonFiles = try? FileManager.default.contentsOfDirectory(atPath: bundlePath as String).filter { $0.hasSuffix(".json") }
                print("DEBUG: Available JSON files in bundle: \(jsonFiles ?? [])")
            }
            self.isLoading = false
            self.errorMessage = "No story file found for this program"
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
}