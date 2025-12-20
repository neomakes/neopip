import SwiftUI

struct LaunchView: View {
    var body: some View {
        ZStack {
            // 디자인 시스템의 방사형 그라데이션 사용
            RadialGradient(
                gradient: Gradient(colors: [Color.pip.bgGrad1, Color.pip.bgGrad2]),
                center: .center,
                startRadius: 20,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            // 중앙 로고
            Image("LaunchLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200)
        }
    }
}
