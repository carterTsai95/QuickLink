//
//  ContentView.swift
//  QuickLink
//
//  Created by Hung-Chun Tsai on 2025-09-01.
//

import SwiftUI
import Combine

// MARK: - Models

struct QuickLinkItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String?
    var urlString: String
}

// MARK: - Store

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

    // Opening URLs is handled in the View via SwiftUI's openURL environment

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

// MARK: - UI

struct ContentView: View {
    @StateObject private var store = LinkStore()
    @State private var newTitle: String = ""
    @State private var newURL: String = ""
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("QuickLink", systemImage: "link")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add a new link")
                        .foregroundStyle(.secondary)
                    if let message = store.errorMessage, !message.isEmpty {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .id("error_\(message)")
                    }
                }
                HStack(spacing: 8) {
                    TextField("Title (optional)", text: $newTitle)
                        .textFieldStyle(.roundedBorder)
                    TextField("URL (e.g. https://example.com)", text: $newURL)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        store.addLink(title: newTitle, urlInput: newURL)
                        newTitle = ""
                        newURL = ""
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
#if DEBUG
                Toggle("Simulate save failure", isOn: Binding(
                    get: { LinkStore.simulateSaveFailure },
                    set: { LinkStore.simulateSaveFailure = $0 }
                ))
                .toggleStyle(.switch)
                .font(.caption)
                .foregroundStyle(.secondary)
#endif
            }

            Divider()

            if store.links.isEmpty {
                ContentUnavailableView("No links yet", systemImage: "tray", description: Text("Add your first link above."))
            } else {
                List {
                    ForEach(store.links) { item in
                        HStack(alignment: .center, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                if let title = item.title, !title.isEmpty {
                                    Text(title)
                                        .font(.body)
                                    Text(item.urlString)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(item.urlString)
                                        .font(.body)
                                }
                            }
                            Spacer()
                            Button {
                                if let url = URL(string: item.urlString) {
                                    openURL(url)
                                }
                            } label: {
                                Label("Open", systemImage: "arrow.up.right.square")
                            }
                            .buttonStyle(.borderless)

                            Button(role: .destructive) {
                                store.remove(item: item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .onDelete(perform: store.deleteLinks)
                }
                .frame(maxHeight: .infinity)
            }

            Spacer(minLength: 0)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
