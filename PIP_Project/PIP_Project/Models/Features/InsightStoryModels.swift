import Foundation

struct InsightStory: Codable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    var pages: [StoryPage]
    var isLiked: Bool = false
}

struct StoryPage: Codable, Identifiable {
    var id: UUID = UUID()
    let pageNumber: Int
    var headline: String
    var body: String
    var imageName: String

    private enum CodingKeys: String, CodingKey {
        case pageNumber, headline, body, imageName
    }
}
