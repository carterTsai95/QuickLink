import SwiftUI

struct LinkRowView: View {
    let item: QuickLinkItem
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
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
            Button(action: onOpen) {
                Label("Open", systemImage: "arrow.up.right.square")
            }
            .buttonStyle(.borderless)

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .buttonStyle(.borderless)
        }
    }
}


