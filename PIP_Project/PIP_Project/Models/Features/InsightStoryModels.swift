import Foundation

struct InsightStory: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    var pages: [StoryPage]
    var isLiked: Bool = false
    
    // Equatable implementation - compare by id and isLiked
    static func == (lhs: InsightStory, rhs: InsightStory) -> Bool {
        lhs.id == rhs.id && lhs.isLiked == rhs.isLiked
    }
}

struct StoryPage: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    let pageNumber: Int
    var headline: String
    var body: String
    var imageName: String

    private enum CodingKeys: String, CodingKey {
        case pageNumber, headline, body, imageName
    }
    
    // Equatable implementation - compare by pageNumber and headline (UUID differs each time)
    static func == (lhs: StoryPage, rhs: StoryPage) -> Bool {
        lhs.pageNumber == rhs.pageNumber && lhs.headline == rhs.headline
    }
}
