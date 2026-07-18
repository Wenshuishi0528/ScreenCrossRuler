import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let state = RulerState()
    private var overlayController: RulerOverlayController!
    private var settingsWindow: NSWindow?
    private var statusItem: NSStatusItem!
    private var toggleMenuItem: NSMenuItem!
    private var modeMenuItem: NSMenuItem!
    private var lockMenuItem: NSMenuItem!
    private var revealMenuItem: NSMenuItem!
    private var settingsMenuItem: NSMenuItem!
    private var quitMenuItem: NSMenuItem!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        state.bootstrapScreens()
        overlayController = RulerOverlayController(state: state)
        createStatusItem()
        observeState()

        if state.isVisible {
            overlayController.show()
        }

        if CommandLine.arguments.contains("--smoke-test") {
            showSettings()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                NSApp.terminate(nil)
            }
        } else {
            showSettings()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        overlayController?.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        revealRulerOnCurrentScreen()
        return true
    }

    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "scope",
            accessibilityDescription: rulerText(.appName, language: state.language)
        )

        let menu = NSMenu()
        toggleMenuItem = menuItem(action: #selector(toggleRuler))
        modeMenuItem = menuItem(action: #selector(toggleResizeMode))
        lockMenuItem = menuItem(action: #selector(toggleLock))
        revealMenuItem = menuItem(action: #selector(revealRulerOnCurrentScreen))
        settingsMenuItem = menuItem(action: #selector(showSettings), keyEquivalent: ",")
        quitMenuItem = menuItem(action: #selector(quit), keyEquivalent: "q")

        menu.addItem(toggleMenuItem)
        menu.addItem(modeMenuItem)
        menu.addItem(lockMenuItem)
        menu.addItem(revealMenuItem)
        menu.addItem(settingsMenuItem)
        menu.addItem(.separator())
        menu.addItem(quitMenuItem)
        statusItem.menu = menu
        refreshLocalizedUI()
    }

    private func menuItem(action: Selector, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: "", action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private func observeState() {
        state.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.refreshLocalizedUI() }
            }
            .store(in: &cancellables)
    }

    private func refreshLocalizedUI() {
        let language = state.language
        statusItem?.button?.toolTip = rulerText(.appName, language: language)
        toggleMenuItem?.title = rulerText(state.isVisible ? .hideRuler : .showRuler, language: language)
        modeMenuItem?.title = rulerText(
            state.mode == .symmetric ? .modeSymmetricMenu : .modeIndependentMenu,
            language: language
        )
        lockMenuItem?.title = rulerText(state.isLocked ? .unlock : .lock, language: language)
        revealMenuItem?.title = rulerText(.moveCurrentScreen, language: language)
        settingsMenuItem?.title = rulerText(.settings, language: language)
        quitMenuItem?.title = rulerText(.quit, language: language)
        settingsWindow?.title = rulerText(.settingsTitle, language: language)
    }

    @objc private func toggleRuler() {
        if state.isVisible {
            overlayController.hide()
        } else {
            overlayController.show()
        }
        refreshLocalizedUI()
    }

    @objc private func toggleResizeMode() {
        state.setMode(state.mode == .symmetric ? .independent : .symmetric)
        refreshLocalizedUI()
    }

    @objc private func toggleLock() {
        state.setLocked(!state.isLocked)
        refreshLocalizedUI()
    }

    @objc private func revealRulerOnCurrentScreen() {
        state.centerOnScreen(containing: NSEvent.mouseLocation)
        overlayController.show()
        showSettings()
        refreshLocalizedUI()
    }

    @objc private func showSettings() {
        if settingsWindow == nil {
            let hostingView = NSHostingView(rootView: RulerSettingsView(state: state))
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 780),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.contentView = hostingView
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }

        refreshLocalizedUI()
        positionSettingsWindowOnMouseScreen()
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    private func positionSettingsWindowOnMouseScreen() {
        guard let window = settingsWindow else { return }
        let mousePoint = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mousePoint) }) ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else {
            window.center()
            return
        }
        let origin = NSPoint(
            x: visibleFrame.midX - window.frame.width / 2,
            y: visibleFrame.midY - window.frame.height / 2
        )
        window.setFrameOrigin(origin)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

@main
struct ScreenCrossRulerApp {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.run()
    }
}
