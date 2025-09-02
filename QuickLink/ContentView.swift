//
//  ContentView.swift
//  QuickLink
//
//  Created by Hung-Chun Tsai on 2025-09-01.
//

import SwiftUI

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
                        LinkRowView(
                            item: item,
                            onOpen: {
                                if let url = URL(string: item.urlString) {
                                    openURL(url)
                                }
                            },
                            onDelete: {
                                store.remove(item: item)
                            }
                        )
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
