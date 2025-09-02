import Foundation
import SwiftUI
import Combine

final class LinkStore: ObservableObject {
    @Published var links: [QuickLinkItem] = []
    @Published var errorMessage: String?

    #if DEBUG
    static var simulateSaveFailure: Bool = false
    #endif

    private let userDefaultsKey = "quicklink.links"

    init() {
        loadLinks()
        seedIfNeeded()
    }

    func addLink(title: String, urlInput: String) {
        guard let normalized = normalizeURLString(urlInput) else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle: String? = trimmedTitle.isEmpty ? nil : trimmedTitle
        let newItem = QuickLinkItem(id: UUID(), title: finalTitle, urlString: normalized)

        let previous = links
        links.append(newItem)
        if let error = trySaveLinks() {
            links = previous
            errorMessage = error.localizedDescription
        }
    }

    func deleteLinks(at offsets: IndexSet) {
        let previous = links
        withAnimation(.easeInOut(duration: 0.2)) {
            links.remove(atOffsets: offsets)
        }
        if let error = trySaveLinks() {
            withAnimation(.easeInOut(duration: 0.2)) {
                links = previous
            }
            errorMessage = error.localizedDescription
        }
    }

    func remove(item: QuickLinkItem) {
        guard let index = links.firstIndex(of: item) else { return }
        let previous = links
        links.remove(at: index)

        if let error = trySaveLinks() {
            links = previous
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Persistence

    private func trySaveLinks() -> Error? {
        #if DEBUG
        if LinkStore.simulateSaveFailure {
            errorMessage = "Simulated"
            return NSError(domain: "QuickLink", code: -1, userInfo: [NSLocalizedDescriptionKey: "Simulated Error"])
        }
        #endif
        do {
            let data = try JSONEncoder().encode(links)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            errorMessage = nil
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return error
        }
    }

    private func loadLinks() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([QuickLinkItem].self, from: data)
            links = decoded
        } catch {
            // Ignore malformed cache
            links = []
        }
    }

    private func seedIfNeeded() {
        if links.isEmpty {
            links = [
                QuickLinkItem(id: UUID(), title: "Apple", urlString: "https://www.apple.com")
            ]
        }
    }

    // MARK: - Validation / Normalization

    private func normalizeURLString(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Prepend https scheme if missing
        let withScheme: String
        if trimmed.contains("://") {
            withScheme = trimmed
        } else {
            withScheme = "https://" + trimmed
        }

        guard let components = URLComponents(string: withScheme),
              let scheme = components.scheme,
              let host = components.host,
              !scheme.isEmpty,
              !host.isEmpty else {
            return nil
        }
        return withScheme
    }
}


