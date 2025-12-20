
import SwiftUI

struct LaunchBackground: View {
    var body: some View {
        ZStack {
            // 1. 방사형 그라데이션 배경
            // DesignSystem에 정의된 색상 사용: Color.pip.bgGrad1 (#333333), Color.pip.bgGrad2 (#000000)
            RadialGradient(
                gradient: Gradient(colors: [Color.pip.bgGrad1, Color.pip.bgGrad2]),
                center: .center,
                startRadius: 30, // 프리뷰를 보며 조절: 중심점 밝기를 조절
                endRadius: 400 // 프리뷰를 보며 조절: 그라데이션이 끝나는 범위
            )
            .ignoresSafeArea() // 화면 전체를 채우도록 설정
            
            // 2. Launch Logo (SVG)
            // Assets에 등록한 '01_LaunchLogo' 이미지 사용
            Image("LaunchLogo")
                .resizable()
                .aspectRatio(contentMode: .fit) // 이미지 비율 유지
                .frame(width: 200) // 로고 크기 조절 (프리뷰를 보며 최적화)
        }
    }
}

// MARK: - Preview
struct LaunchBackground_Previews: PreviewProvider {
    static var previews: some View {
        LaunchBackground()
            .preferredColorScheme(.dark) // 런치 화면은 항상 다크 모드이므로 미리보기 설정
    }
}
