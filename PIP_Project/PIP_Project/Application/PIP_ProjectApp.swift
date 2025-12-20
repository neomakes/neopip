import SwiftUI

@main
struct PIP_ProjectApp: App {
    var body: some Scene {
        WindowGroup {
            LaunchScreenWrapper() // LaunchScreenWrapper를 앱의 시작점으로 설정
        }
    }
}

// 런치 화면을 일정 시간 보여준 후 메인 콘텐츠로 전환하는 래퍼 뷰
struct LaunchScreenWrapper: View {
    @State private var showLaunchScreen = true

    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchBackground() // 우리의 커스텀 런치 배경 + 로고
            } else {
                MainTabView() // 앱의 실제 메인 콘텐츠 뷰 (아직 구현 안 됨)
            }
        }
        .onAppear {
            // 1.5초 후 런치 화면 숨기기 (애니메이션과 함께 전환)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.8)) { // 부드러운 전환 효과
                    showLaunchScreen = false
                }
            }
        }
    }
}
