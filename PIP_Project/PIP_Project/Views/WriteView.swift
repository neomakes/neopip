import SwiftUI

struct WriteView: View {
    var body: some View {
        VStack {
            Text("WRITE")
                .font(.pip.hero)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WriteView()
}
