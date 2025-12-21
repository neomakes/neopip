// Location: Views/HomeView.swift
import SwiftUI

struct HomeView: View {
    var body: some View {
        // Do NOT add PrimaryBackground() here.
        // The background is already provided by MainTabView.
        VStack {
            Text("HOME")
                .font(.pip.hero)
                .foregroundColor(.white)
            
            // Your railroad asset will go here
            // Image("img_railroad")
            //    .resizable()
        }
        // Ensure the view takes up full space but remains transparent
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HomeView()
}
