import SwiftUI

struct LaunchView: View {
    var body: some View {
        ZStack {
            // Use radial gradient from design system
            RadialGradient(
                gradient: Gradient(colors: [Color.pip.bgGrad1, Color.pip.bgGrad2]),
                center: .center,
                startRadius: 20,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            // Center logo
            Image("LaunchLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200)
        }
    }
}

#Preview {
    LaunchView()
}
