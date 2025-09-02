import Foundation

struct QuickLinkItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String?
    var urlString: String
}


