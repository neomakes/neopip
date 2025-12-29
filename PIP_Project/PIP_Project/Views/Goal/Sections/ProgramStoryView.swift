import SwiftUI

/// ProgramStoryView - Instagram Story Style Program Progress Display
///
/// Displays program stories in an Instagram-like format with:
/// - Page-based navigation (tap sides to move)
/// - Progress indicator at top
/// - Story content (text, tips, milestones, motivation)
/// - Like and reply interactions
///
struct ProgramStoryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPageIndex: Int = 0
    @State private var isLiked: Bool = false
    
    let program: Program
    let progress: ProgramProgress?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.1, green: 0.1, blue: 0.12)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if let progress = progress, !progress.stories.isEmpty {
                    let story = progress.stories[0]  // First story
                    
                    VStack(spacing: 0) {
                        // MARK: - Progress Bar & Header
                        HStack(spacing: 12) {
                            // Progress bars for pages
                            HStack(spacing: 4) {
                                ForEach(0..<story.pages.count, id: \.self) { index in
                                    GeometryReader { geo in
                                        Capsule()
                                            .fill(
                                                index < currentPageIndex ? Color.white :
                                                index == currentPageIndex ? Color.white.opacity(0.7) :
                                                Color.white.opacity(0.3)
                                            )
                                            .frame(height: 2)
                                    }
                                }
                            }
                            .frame(height: 2)
                            
                            // Close button
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .frame(width: 30, height: 30)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        // MARK: - Story Title & Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(story.title)
                                .font(.pip.title2)
                                .foregroundColor(.white)
                            
                            if let subtitle = story.subtitle {
                                Text(subtitle)
                                    .font(.pip.body)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        // MARK: - Page Content
                        if story.pages.indices.contains(currentPageIndex) {
                            let page = story.pages[currentPageIndex]
                            
                            VStack(spacing: 16) {
                                // Content based on page type
                                switch page.contentType {
                                case .text:
                                    textPageContent(content: page.content)
                                case .image:
                                    imagePageContent(imageName: page.content.imageName ?? "")
                                case .tip:
                                    tipPageContent(content: page.content)
                                case .milestone:
                                    milestonePageContent(content: page.content)
                                case .motivation:
                                    motivationPageContent(content: page.content)
                                case .mixed:
                                    mixedPageContent(content: page.content)
                                }
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .transition(.opacity)
                        }
                        
                        // MARK: - Bottom Actions
                        HStack(spacing: 16) {
                            // Like button
                            Button(action: {
                                withAnimation {
                                    isLiked.toggle()
                                }
                            }) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(isLiked ? .red : .white)
                                    .font(.system(size: 16))
                            }
                            
                            // Text input placeholder
                            HStack {
                                Text("Reply...")
                                    .font(.pip.body)
                                    .foregroundColor(.gray)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    // Tap to advance
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let midpoint = geometry.size.width / 2
                        if location.x < midpoint {
                            // Previous page
                            if currentPageIndex > 0 {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentPageIndex -= 1
                                }
                            }
                        } else {
                            // Next page
                            if currentPageIndex < story.pages.count - 1 {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentPageIndex += 1
                                }
                            } else {
                                // Story finished
                                dismiss()
                            }
                        }
                    }
                } else {
                    // No stories available
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No Stories Yet")
                            .font(.pip.title2)
                            .foregroundColor(.white)
                        
                        Text("Stories about this program will appear here as you progress")
                            .font(.pip.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { dismiss() }) {
                            Text("Dismiss")
                                .font(.pip.body)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.accentColor)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Page Content Views
    
    private func textPageContent(content: GoalStoryPageContent) -> some View {
        VStack(spacing: 16) {
            if let headline = content.headline {
                Text(headline)
                    .font(.pip.title2)
                    .foregroundColor(.white)
            }
            
            if let body = content.body {
                Text(body)
                    .font(.pip.body)
                    .foregroundColor(.gray)
                    .lineSpacing(4)
            }
        }
    }
    
    private func imagePageContent(imageName: String) -> some View {
        VStack {
            if !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                    )
            }
        }
    }
    
    private func tipPageContent(content: GoalStoryPageContent) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 20))
                
                Text("Pro Tip")
                    .font(.pip.title2)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if let headline = content.headline {
                Text(headline)
                    .font(.pip.body)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
            
            if let body = content.body {
                Text(body)
                    .font(.pip.body)
                    .foregroundColor(.gray)
                    .lineSpacing(4)
            }
        }
        .padding(12)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func milestonePageContent(content: GoalStoryPageContent) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
                
                Text("Milestone")
                    .font(.pip.title2)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if let headline = content.headline {
                Text(headline)
                    .font(.pip.body)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
            
            if let body = content.body {
                Text(body)
                    .font(.pip.body)
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func motivationPageContent(content: GoalStoryPageContent) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundColor(.yellow)
            
            if let mantra = content.mantra {
                Text(mantra)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }
    
    private func mixedPageContent(content: GoalStoryPageContent) -> some View {
        VStack(spacing: 12) {
            if let headline = content.headline {
                Text(headline)
                    .font(.pip.title2)
                    .foregroundColor(.white)
            }
            
            if let body = content.body {
                Text(body)
                    .font(.pip.body)
                    .foregroundColor(.gray)
                    .lineSpacing(4)
            }
            
            if let mantra = content.mantra {
                Text(mantra)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .italic()
            }
        }
    }
}

#Preview {
    ProgramStoryView(program: Program(
        id: UUID(),
        name: "Test Program",
        description: "Test Description",
        category: GoalCategory.emotional,
        duration: 21,
        difficulty: DifficultyLevel.beginner,
        gemVisualization: GemVisualization(
            gemType: .diamond,
            colorTheme: .amber,
            brightness: 0.8,
            size: 1.0,
            customShape: nil
        ),
        illustration3D: nil,
        popularity: 0.85,
        rating: 4.5,
        reviewCount: 234,
        userCount: 1234,
        steps: [],
        prerequisites: nil,
        tags: ["test"],
        expectedEffects: ["test"],
        requiredDataTypes: ["test"],
        userReviews: nil,
        isRecommended: true,
        createdAt: Date()
    ), progress: nil)
}
