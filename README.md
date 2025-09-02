# QuickLink

A minimal macOS Menu Bar utility built with SwiftUI `MenuBarExtra` to quickly add and open links.

## Features
- Add links with optional title and URL normalization (auto-prepend https://).
- Open links via NSWorkspace.
- Delete links.
- Persistence via UserDefaults (JSON encoded).
- Quit button inside the menu bar window.

## Hide Dock Icon
For a menu-bar-only experience, set the app as an agent so it doesn’t appear in the Dock or app switcher.

1. Open your target > Info tab.
2. Add key: Application is agent (UIElement) (`LSUIElement`) and set value to YES.

## References
- Build a macOS menu bar utility in SwiftUI — [nilcoalescing.com](https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI/)
- Create a mac menu bar app in SwiftUI with MenuBarExtra — [sarunw.com](https://sarunw.com/posts/swiftui-menu-bar-app/)
