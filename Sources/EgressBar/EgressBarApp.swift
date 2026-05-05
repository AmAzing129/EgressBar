import AppKit
import SwiftUI

@main
struct EgressBarApp: App {
    @StateObject private var model = IPStatusModel()
    private let settingsWindow = SettingsWindowController()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            StatusMenu(model: model, settingsWindow: settingsWindow)
        } label: {
            Text(model.menuTitle)
        }
        .menuBarExtraStyle(.menu)
    }
}
