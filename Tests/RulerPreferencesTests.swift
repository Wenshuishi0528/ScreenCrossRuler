import AppKit
import Foundation

private enum PreferenceTestFailure: Error {
    case failed(String)
}

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw PreferenceTestFailure.failed(message) }
}

@main
private struct RulerPreferencesTests {
    static func main() throws {
        let suiteName = "ScreenCrossRulerTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw PreferenceTestFailure.failed("could not create isolated UserDefaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let state = RulerState(defaults: defaults)
        try expect(state.language == .zh, "default language must be Chinese")
        try expect(!state.showsMillimeterTicks, "millimeter ticks must default to off")
        try expect(state.showsNumbers, "coordinate numbers must default to on")
        try expect(state.transparentCenter, "transparent center must default to on")
        try expect(!state.isLocked, "ruler must default to unlocked")
        try expect(state.colorPreset == .yellow, "ruler color must default to yellow")

        state.setLanguage(.en)
        state.setShowsMillimeterTicks(true)
        state.setShowsNumbers(false)
        state.setTransparentCenter(false)
        state.setLocked(true)
        state.setRulerColor(NSColor(calibratedRed: 0.2, green: 0.4, blue: 0.6, alpha: 1))
        try expect(state.colorPreset == .custom, "custom color did not select the custom preset")

        guard let expectedRGB = state.rulerColor.usingColorSpace(.deviceRGB) else {
            throw PreferenceTestFailure.failed("saved color is not RGB")
        }

        let restored = RulerState(defaults: defaults)
        try expect(restored.language == .en, "language did not persist")
        try expect(restored.showsMillimeterTicks, "millimeter setting did not persist")
        try expect(!restored.showsNumbers, "number visibility did not persist")
        try expect(!restored.transparentCenter, "center transparency did not persist")
        try expect(restored.isLocked, "lock setting did not persist")
        try expect(restored.colorPreset == .custom, "custom color preset did not persist")

        guard let rgb = restored.rulerColor.usingColorSpace(.deviceRGB) else {
            throw PreferenceTestFailure.failed("restored color is not RGB")
        }
        try expect(abs(rgb.redComponent - expectedRGB.redComponent) < 0.001, "red component did not persist")
        try expect(abs(rgb.greenComponent - expectedRGB.greenComponent) < 0.001, "green component did not persist")
        try expect(abs(rgb.blueComponent - expectedRGB.blueComponent) < 0.001, "blue component did not persist")

        restored.setColorPreset(.green)
        let greenRestored = RulerState(defaults: defaults)
        try expect(greenRestored.colorPreset == .green, "green preset did not persist")
        guard let expectedGreen = RulerColorPreset.green.fixedColor?.usingColorSpace(.deviceRGB),
              let actualGreen = greenRestored.rulerColor.usingColorSpace(.deviceRGB) else {
            throw PreferenceTestFailure.failed("green preset is not RGB")
        }
        try expect(abs(actualGreen.greenComponent - expectedGreen.greenComponent) < 0.001, "green preset color is incorrect")
        try expect(rulerText(.settings, language: .zh) == "设置…", "Chinese localization is incorrect")
        try expect(rulerText(.settings, language: .en) == "Settings…", "English localization is incorrect")

        print("RULER_PREFERENCES_TESTS_PASSED")
    }
}
