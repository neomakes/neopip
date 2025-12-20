import SwiftUI

@main
struct PIP_ProjectApp: App {
    var body: some Scene {
        WindowGroup {
            // 앱의 시작점을 관리하는 래퍼 뷰 호출
            LaunchScreenWrapper()
        }
    }
}

// 런치 화면을 일정 시간 보여준 후 메인 콘텐츠로 전환하는 래퍼 뷰
struct LaunchScreenWrapper: View {
    @State private var showLaunchScreen = true

    var body: some View {
        ZStack {
            if showLaunchScreen {
                // Views/LaunchView.swift 호출
                LaunchView()
            } else {
                // Views/MainTabView.swift 호출
                MainTabView()
            }
        }
        .onAppear {
            // 1.0초 후 런치 화면 숨기기 (사용자님의 시나리오 반영)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.8)) {
                    showLaunchScreen = false
                }
            }
        }
    }
}

#Preview {
    LaunchScreenWrapper()
}
