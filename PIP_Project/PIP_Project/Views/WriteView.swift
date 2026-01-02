import SwiftUI

struct WriteView: View {
    let isPresented: Binding<Bool>?

    init(isPresented: Binding<Bool>? = nil) {
        self.isPresented = isPresented
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: {
                    isPresented?.wrappedValue = false
                }) {
                    Text("닫기")
                        .foregroundColor(.white)
                        .padding(12)
                }
            }
            .padding(.top, 8)

            Spacer()

            Text("WRITE")
                .font(.pip.hero)
                .foregroundColor(.white)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    WriteView()
}
