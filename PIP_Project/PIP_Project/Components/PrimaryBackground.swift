import SwiftUI

struct PrimaryBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.pip.bgGrad2, Color.pip.bgGrad1]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    PrimaryBackground()
}
