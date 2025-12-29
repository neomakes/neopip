import SwiftUI

/// MARK: - ProgramStoryView (MVVM: DetailView - ProgramsSection Navigation Target)
///
/// **Role**: Program의 상세 정보 및 단계별 가이드 페이지
/// ProgramsSection의 프로그램 카드 탭으로 네비게이션되는 상세 뷰
///
/// **MVVM Relationship:**
/// - **View** (현재): ProgramStoryView
///   - 역할: 선택된 프로그램의 상세 내용을 단계별로 표시
///   - Binds to: @State program (Program model)
///   - Input: program (Program), 전달받은 프로그램 정보
///
/// - **ViewModel**: (Optional) ProgramStoryViewModel
///   - 현재는 단순 @State 사용 가능
///   - 향후 복잡성 증가 시 ViewModel 추가
///   - 책임: 단계별 진행 상황, 사용자 입력 처리
///
/// - **Model**: Program + ProgramStep
///   - Program: 프로그램 기본 정보
///   - ProgramStep:
///     * id: String
///     * stepNumber: Int
///     * title: String
///     * description: String
///     * instructions: [String] (단계별 지시사항)
///     * duration: Int (소요 시간, 분)
///     * tips: [String]?
///     * image: String? (asset name)
///
/// **Navigation Flow:**
/// GoalView → ProgramsSection → (card tap) → ProgramStoryView
///
/// **Presentation Style:**
/// Full-screen modal presentation with vertical paging
/// Bottom sheet or full modal with back button
/// Swipeable pages or button-based navigation through steps
///
struct ProgramStoryView: View {
    @Environment(\.presentationMode) var presentationMode
    let program: Program
    let maxPages: Int? // nil이면 모든 페이지, 숫자면 해당 페이지까지만
    
    @State private var currentStepIndex: Int = 0
    @State private var completedSteps: Set<String> = []
    @State private var showAcceptanceAlert = false
    
    init(program: Program, maxPages: Int? = nil) {
        self.program = program
        self.maxPages = maxPages
    }
    
    var effectiveStepsCount: Int {
        if let maxPages = maxPages {
            return min(maxPages, program.steps.count)
        }
        return program.steps.count
    }
    
    var isAcceptanceMode: Bool {
        return maxPages == nil // 모든 페이지를 보여줄 때는 수락 모드
    }
    
    var currentStep: ProgramStep? {
        guard currentStepIndex < effectiveStepsCount else { return nil }
        return program.steps[currentStepIndex]
    }
    
    var progressPercentage: Double {
        guard effectiveStepsCount > 0 else { return 0 }
        return Double(currentStepIndex + 1) / Double(effectiveStepsCount)
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.3),
                    Color.black.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("Step \(currentStepIndex + 1)/\(effectiveStepsCount)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.3),
                                            Color.blue
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progressPercentage)
                        }
                        .frame(height: 4)
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .padding(.bottom, 20)
                
                // Content
                ScrollView {
                    if let step = currentStep {
                        VStack(alignment: .leading, spacing: 24) {
                            // Step Title
                            VStack(alignment: .leading, spacing: 8) {
                                Text(step.title)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Duration: \(step.duration) minutes")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            
                            // Step Image (Placeholder)
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                            }
                            .frame(height: 200)
                            
                            // Description
                            Text(step.description)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(4)

                            
                            Spacer()
                                .frame(height: 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                
                // Navigation Buttons
                HStack(spacing: 12) {
                    if currentStepIndex > 0 {
                        Button(action: { currentStepIndex -= 1 }) {
                            Text("Previous")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    
                    if currentStepIndex < effectiveStepsCount - 1 {
                        Button(role: .none, action: { currentStepIndex += 1 }) {
                            Text("Next")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    } else {
                        if isAcceptanceMode {
                            Button(action: { showAcceptanceAlert = true }) {
                                Text("Accept Program")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                        } else {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Text("Complete")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationBarHidden(true)
        .alert("Accept Program", isPresented: $showAcceptanceAlert) {
            Button("Cancel", role: .cancel) {
                // Do nothing
            }
            Button("Accept", role: .none) {
                // TODO: 프로그램 수락 로직 추가 (GoalViewModel에 addProgram 호출)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Would you like to add '\(program.name)' to your active programs?")
        }
    }
}

#Preview {
    Text("Preview")
}
