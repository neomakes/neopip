import SwiftUI

struct ProgramsSection: View {
    @ObservedObject var viewModel: GoalViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Header
            HStack {
                Text("Programs")
                    .font(.pip.title2)
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: {
                    Text("View All Programs")
                }) {
                    Text("View All")
                        .font(.pip.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 16)
            
            // MARK: - Program List
            VStack(spacing: 12) {
                // TODO: Selected goal's program list
                ForEach(0..<3, id: \.self) { _ in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                        
                        HStack(spacing: 12) {
                            // Program icon
                            Image(systemName: "star.fill")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Program Name")
                                    .font(.pip.body)
                                    .foregroundColor(.white)
                                
                                Text("Exercise · 3 sessions")
                                    .font(.pip.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("75%")
                                    .font(.pip.body)
                                    .foregroundColor(.accentColor)
                                
                                Text("This week")
                                    .font(.pip.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(12)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    ProgramsSection(viewModel: GoalViewModel())
        .background(Color.black)
}
