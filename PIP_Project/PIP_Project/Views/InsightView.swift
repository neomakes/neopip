import SwiftUI

struct InsightView: View {
    var body: some View {
        VStack {
            Text("INSIGHT")
                .font(.pip.hero)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    InsightView()
}
