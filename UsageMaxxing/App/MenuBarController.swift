import AppKit

enum MenuBarController {
    @MainActor
    static func configureAccessoryActivation() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    @MainActor
    static func openSettings() {
        NSApplication.shared.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
