import SwiftUI

// Location: Views/GoalView.swift
struct GoalView: View {
    var body: some View {
        VStack {
            Text("GOAL")
                .font(.pip.hero)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    GoalView()
}
