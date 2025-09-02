//
//  ContentView.swift
//  QuickLink
//
//  Created by Hung-Chun Tsai on 2025-09-01.
//

import SwiftUI
import Combine
import AppKit

// MARK: - Models

struct QuickLinkItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var urlString: String
}

// MARK: - Store

final class LinkStore: ObservableObject {
    @Published var links: [QuickLinkItem] = [] {
        didSet { saveLinks() }
    }

    private let userDefaultsKey = "quicklink.links"

    init() {
        loadLinks()
        seedIfNeeded()
    }

    func addLink(title: String, urlInput: String) {
        guard let normalized = normalizeURLString(urlInput) else { return }
        let newItem = QuickLinkItem(id: UUID(), title: title.isEmpty ? normalized : title, urlString: normalized)
        links.append(newItem)
    }

    func deleteLinks(at offsets: IndexSet) {
        links.remove(atOffsets: offsets)
    }

    func open(_ item: QuickLinkItem) {
        guard let url = URL(string: item.urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Persistence

    private func saveLinks() {
        do {
            let data = try JSONEncoder().encode(links)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            // In a first draft, silently ignore; could add logging later
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("QuickLink", systemImage: "link")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Add a new link")
                    .foregroundStyle(.secondary)
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
            }

            Divider()

            if store.links.isEmpty {
                ContentUnavailableView("No links yet", systemImage: "tray", description: Text("Add your first link above."))
            } else {
                List {
                    ForEach(store.links) { item in
                        HStack(alignment: .center, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.body)
                                Text(item.urlString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                store.open(item)
                            } label: {
                                Label("Open", systemImage: "arrow.up.right.square")
                            }
                            .buttonStyle(.borderless)

                            Button(role: .destructive) {
                                if let index = store.links.firstIndex(of: item) {
                                    store.links.remove(at: index)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .onDelete(perform: store.deleteLinks)
                }
                .listStyle(.inset)
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
