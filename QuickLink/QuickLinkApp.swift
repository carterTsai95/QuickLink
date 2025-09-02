//
//  QuickLinkApp.swift
//  QuickLink
//
//  Created by Hung-Chun Tsai on 2025-09-01.
//

import SwiftUI
import AppKit

@main
struct QuickLinkApp: App {
    var body: some Scene {
        MenuBarExtra("QuickLink", systemImage: "link") {
            ContentView()
                .overlay(alignment: .topTrailing) {
                    Button("Quit", systemImage: "xmark.circle.fill") {
                        NSApplication.shared.terminate(nil)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .padding(6)
                }
                .frame(width: 360, height: 420)
        }
        .menuBarExtraStyle(.window)
    }
}
