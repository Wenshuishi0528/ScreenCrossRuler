import AppKit
import Combine
import CoreGraphics
import Foundation

private enum RulerDefaultsKey {
    static let prefix = "ScreenCrossRuler."
    static let resizeMode = prefix + "resizeMode"
    static let leftCM = prefix + "leftCM"
    static let rightCM = prefix + "rightCM"
    static let upCM = prefix + "upCM"
    static let downCM = prefix + "downCM"
    static let displayID = prefix + "displayID"
    static let positionXCM = prefix + "positionXCM"
    static let positionYCM = prefix + "positionYCM"
    static let isVisible = prefix + "isVisible"
    static let language = prefix + "language"
    static let showsMillimeterTicks = prefix + "showsMillimeterTicks"
    static let showsNumbers = prefix + "showsNumbers"
    static let transparentCenter = prefix + "transparentCenter"
    static let isLocked = prefix + "isLocked"
    static let colorPreset = prefix + "colorPreset"
    static let colorRed = prefix + "colorRed"
    static let colorGreen = prefix + "colorGreen"
    static let colorBlue = prefix + "colorBlue"
}

enum RulerColorPreset: String, CaseIterable, Identifiable {
    case yellow
    case green
    case red
    case cyan
    case black
    case white
    case custom

    var id: String { rawValue }

    var localizedKey: RulerStringKey {
        switch self {
        case .yellow: return .yellow
        case .green: return .green
        case .red: return .red
        case .cyan: return .cyan
        case .black: return .black
        case .white: return .white
        case .custom: return .customColor
        }
    }

    var fixedColor: NSColor? {
        switch self {
        case .yellow: return NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.12, alpha: 1)
        case .green: return NSColor(calibratedRed: 0.20, green: 0.80, blue: 0.30, alpha: 1)
        case .red: return NSColor(calibratedRed: 1.0, green: 0.24, blue: 0.20, alpha: 1)
        case .cyan: return NSColor(calibratedRed: 0.0, green: 0.78, blue: 1.0, alpha: 1)
        case .black: return NSColor(calibratedRed: 0.04, green: 0.04, blue: 0.04, alpha: 1)
        case .white: return NSColor(calibratedWhite: 1.0, alpha: 1)
        case .custom: return nil
        }
    }
}

struct RulerDisplayMetric: Equatable {
    let id: CGDirectDisplayID
    let name: String
    let measurement: DisplayMeasurement

    init?(screen: NSScreen) {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }

        id = CGDirectDisplayID(number.uint32Value)
        name = screen.localizedName
        let sizeMM = CGDisplayScreenSize(id)
        measurement = DisplayMeasurement(
            frame: screen.frame,
            physicalWidthMM: sizeMM.width > 0 ? sizeMM.width : nil,
            physicalHeightMM: sizeMM.height > 0 ? sizeMM.height : nil
        )
    }
}

final class RulerState: ObservableObject {
    @Published private(set) var mode: RulerResizeMode
    @Published private(set) var arms: RulerArms
    @Published private(set) var centerScreenPoint: CGPoint = .zero
    @Published private(set) var currentDisplayID: CGDirectDisplayID = 0
    @Published private(set) var positionXCM: CGFloat = 0
    @Published private(set) var positionYCM: CGFloat = 0
    @Published private(set) var isVisible: Bool
    @Published private(set) var language: RulerLanguage
    @Published private(set) var showsMillimeterTicks: Bool
    @Published private(set) var showsNumbers: Bool
    @Published private(set) var transparentCenter: Bool
    @Published private(set) var isLocked: Bool
    @Published private(set) var colorPreset: RulerColorPreset
    @Published private(set) var rulerColor: NSColor

    private let defaults: UserDefaults
    private var displays: [RulerDisplayMetric] = []
    private var hasBootstrapped = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        func storedBool(_ key: String, default defaultValue: Bool) -> Bool {
            defaults.object(forKey: key) == nil ? defaultValue : defaults.bool(forKey: key)
        }

        language = RulerLanguage(rawValue: defaults.string(forKey: RulerDefaultsKey.language) ?? "") ?? .zh
        showsMillimeterTicks = storedBool(RulerDefaultsKey.showsMillimeterTicks, default: false)
        showsNumbers = storedBool(RulerDefaultsKey.showsNumbers, default: true)
        transparentCenter = storedBool(RulerDefaultsKey.transparentCenter, default: true)
        isLocked = storedBool(RulerDefaultsKey.isLocked, default: false)

        let hasStoredCustomColor = defaults.object(forKey: RulerDefaultsKey.colorRed) != nil
            && defaults.object(forKey: RulerDefaultsKey.colorGreen) != nil
            && defaults.object(forKey: RulerDefaultsKey.colorBlue) != nil
        let initialColorPreset = RulerColorPreset(
            rawValue: defaults.string(forKey: RulerDefaultsKey.colorPreset) ?? ""
        ) ?? (hasStoredCustomColor ? .custom : .yellow)
        colorPreset = initialColorPreset

        func storedColorComponent(_ key: String, fallback: CGFloat) -> CGFloat {
            guard defaults.object(forKey: key) != nil else { return fallback }
            return min(max(CGFloat(defaults.double(forKey: key)), 0), 1)
        }
        if let presetColor = initialColorPreset.fixedColor {
            rulerColor = presetColor
        } else {
            rulerColor = NSColor(
                calibratedRed: storedColorComponent(RulerDefaultsKey.colorRed, fallback: 1.0),
                green: storedColorComponent(RulerDefaultsKey.colorGreen, fallback: 0.78),
                blue: storedColorComponent(RulerDefaultsKey.colorBlue, fallback: 0.12),
                alpha: 1
            )
        }

        let loadedMode = RulerResizeMode(
            rawValue: defaults.string(forKey: RulerDefaultsKey.resizeMode) ?? ""
        ) ?? .symmetric
        mode = loadedMode

        func storedLength(_ key: String, fallback: CGFloat) -> CGFloat {
            guard defaults.object(forKey: key) != nil else { return fallback }
            return CGFloat(defaults.double(forKey: key))
        }

        var loadedArms = RulerArms(
            leftCM: storedLength(RulerDefaultsKey.leftCM, fallback: RulerArms.default.leftCM),
            rightCM: storedLength(RulerDefaultsKey.rightCM, fallback: RulerArms.default.rightCM),
            upCM: storedLength(RulerDefaultsKey.upCM, fallback: RulerArms.default.upCM),
            downCM: storedLength(RulerDefaultsKey.downCM, fallback: RulerArms.default.downCM)
        )
        loadedArms.sanitize()
        if loadedMode == .symmetric {
            loadedArms.makeSymmetricPreservingTotals()
        }
        arms = loadedArms

        if defaults.object(forKey: RulerDefaultsKey.isVisible) == nil {
            isVisible = true
        } else {
            isVisible = defaults.bool(forKey: RulerDefaultsKey.isVisible)
        }
    }

    var horizontalTotalCM: CGFloat { arms.horizontalTotalCM }
    var verticalTotalCM: CGFloat { arms.verticalTotalCM }

    var currentDisplayName: String {
        currentDisplay?.name ?? rulerText(.noDisplay, language: language)
    }

    var currentDisplayWidthCM: CGFloat {
        currentDisplay?.measurement.physicalWidthCM ?? 0
    }

    var currentDisplayHeightCM: CGFloat {
        currentDisplay?.measurement.physicalHeightCM ?? 0
    }

    var conversionDescription: String {
        guard let display = currentDisplay else { return rulerText(.noDisplay, language: language) }
        return display.measurement.usesReportedPhysicalSize
            ? rulerText(.reportedPhysicalSize, language: language)
            : rulerText(.fallbackPhysicalSize, language: language)
    }

    var currentDisplay: RulerDisplayMetric? {
        displays.first(where: { $0.id == currentDisplayID }) ?? displays.first
    }

    func bootstrapScreens() {
        refreshScreens(preserveCenter: false)
    }

    func refreshScreens(preserveCenter: Bool = true) {
        let previousCenter = centerScreenPoint
        displays = NSScreen.screens.compactMap(RulerDisplayMetric.init(screen:))
        guard !displays.isEmpty else { return }

        if preserveCenter, hasBootstrapped {
            moveCenter(to: previousCenter)
            return
        }

        let storedID: CGDirectDisplayID?
        if defaults.object(forKey: RulerDefaultsKey.displayID) != nil {
            storedID = CGDirectDisplayID(defaults.integer(forKey: RulerDefaultsKey.displayID))
        } else {
            storedID = nil
        }

        let preferred = storedID.flatMap { id in displays.first(where: { $0.id == id }) }
            ?? NSScreen.main.flatMap(RulerDisplayMetric.init(screen:)).flatMap { main in
                displays.first(where: { $0.id == main.id })
            }
            ?? displays[0]

        currentDisplayID = preferred.id
        if let storedX = defaults.object(forKey: RulerDefaultsKey.positionXCM) as? NSNumber,
           let storedY = defaults.object(forKey: RulerDefaultsKey.positionYCM) as? NSNumber {
            positionXCM = min(max(CGFloat(storedX.doubleValue), 0), preferred.measurement.physicalWidthCM)
            positionYCM = min(max(CGFloat(storedY.doubleValue), 0), preferred.measurement.physicalHeightCM)
            centerScreenPoint = preferred.measurement.screenPoint(
                xFromLeftCM: positionXCM,
                yFromTopCM: positionYCM
            )
        } else {
            centerScreenPoint = CGPoint(x: preferred.measurement.frame.midX, y: preferred.measurement.frame.midY)
            updatePositionFromCenter(using: preferred)
        }
        hasBootstrapped = true
        savePosition()
    }

    func setMode(_ newMode: RulerResizeMode) {
        guard mode != newMode else { return }
        if newMode == .symmetric {
            arms.makeSymmetricPreservingTotals()
        }
        mode = newMode
        saveGeometry()
    }

    func setHorizontalTotalCM(_ value: CGFloat) {
        arms.setHorizontalTotal(value)
        saveGeometry()
    }

    func setVerticalTotalCM(_ value: CGFloat) {
        arms.setVerticalTotal(value)
        saveGeometry()
    }

    func setArm(_ handle: RulerHandle, centimeters: CGFloat) {
        arms.resize(handle, distanceCM: centimeters, mode: .independent)
        saveGeometry()
    }

    func resize(_ handle: RulerHandle, toward screenPoint: CGPoint) {
        guard let display = currentDisplay else { return }
        let measurement = display.measurement
        let distanceCM: CGFloat

        switch handle {
        case .left:
            distanceCM = (centerScreenPoint.x - screenPoint.x) / measurement.pointsPerCentimeterX
        case .right:
            distanceCM = (screenPoint.x - centerScreenPoint.x) / measurement.pointsPerCentimeterX
        case .up:
            distanceCM = (screenPoint.y - centerScreenPoint.y) / measurement.pointsPerCentimeterY
        case .down:
            distanceCM = (centerScreenPoint.y - screenPoint.y) / measurement.pointsPerCentimeterY
        case .center:
            return
        }

        arms.resize(handle, distanceCM: distanceCM, mode: mode)
    }

    func finishResize() {
        saveGeometry()
    }

    func moveCenter(to screenPoint: CGPoint) {
        guard let display = display(containing: screenPoint) ?? nearestDisplay(to: screenPoint) else { return }
        currentDisplayID = display.id
        centerScreenPoint = display.measurement.clampedScreenPoint(screenPoint)
        updatePositionFromCenter(using: display)
    }

    func finishMove() {
        savePosition()
    }

    func centerOnScreen(containing screenPoint: CGPoint) {
        guard let display = display(containing: screenPoint) ?? nearestDisplay(to: screenPoint) else { return }
        currentDisplayID = display.id
        centerScreenPoint = CGPoint(
            x: display.measurement.frame.midX,
            y: display.measurement.frame.midY
        )
        updatePositionFromCenter(using: display)
        savePosition()
    }

    func setPositionXCM(_ value: CGFloat) {
        guard let display = currentDisplay else { return }
        positionXCM = min(max(value.isFinite ? value : 0, 0), display.measurement.physicalWidthCM)
        centerScreenPoint = display.measurement.screenPoint(
            xFromLeftCM: positionXCM,
            yFromTopCM: positionYCM
        )
        savePosition()
    }

    func setPositionYCM(_ value: CGFloat) {
        guard let display = currentDisplay else { return }
        positionYCM = min(max(value.isFinite ? value : 0, 0), display.measurement.physicalHeightCM)
        centerScreenPoint = display.measurement.screenPoint(
            xFromLeftCM: positionXCM,
            yFromTopCM: positionYCM
        )
        savePosition()
    }

    func setVisible(_ visible: Bool) {
        isVisible = visible
        defaults.set(visible, forKey: RulerDefaultsKey.isVisible)
    }

    func setLanguage(_ newLanguage: RulerLanguage) {
        language = newLanguage
        defaults.set(newLanguage.rawValue, forKey: RulerDefaultsKey.language)
    }

    func setShowsMillimeterTicks(_ value: Bool) {
        showsMillimeterTicks = value
        defaults.set(value, forKey: RulerDefaultsKey.showsMillimeterTicks)
    }

    func setShowsNumbers(_ value: Bool) {
        showsNumbers = value
        defaults.set(value, forKey: RulerDefaultsKey.showsNumbers)
    }

    func setTransparentCenter(_ value: Bool) {
        transparentCenter = value
        defaults.set(value, forKey: RulerDefaultsKey.transparentCenter)
    }

    func setLocked(_ value: Bool) {
        isLocked = value
        defaults.set(value, forKey: RulerDefaultsKey.isLocked)
    }

    func setColorPreset(_ preset: RulerColorPreset) {
        colorPreset = preset
        defaults.set(preset.rawValue, forKey: RulerDefaultsKey.colorPreset)
        if let color = preset.fixedColor {
            applyRulerColor(color)
        }
    }

    func setCustomRulerColor(_ color: NSColor) {
        colorPreset = .custom
        defaults.set(RulerColorPreset.custom.rawValue, forKey: RulerDefaultsKey.colorPreset)
        applyRulerColor(color)
    }

    func setRulerColor(_ color: NSColor) {
        setCustomRulerColor(color)
    }

    private func applyRulerColor(_ color: NSColor) {
        guard let rgb = color.usingColorSpace(.deviceRGB) else { return }
        rulerColor = NSColor(
            calibratedRed: rgb.redComponent,
            green: rgb.greenComponent,
            blue: rgb.blueComponent,
            alpha: 1
        )
        defaults.set(Double(rgb.redComponent), forKey: RulerDefaultsKey.colorRed)
        defaults.set(Double(rgb.greenComponent), forKey: RulerDefaultsKey.colorGreen)
        defaults.set(Double(rgb.blueComponent), forKey: RulerDefaultsKey.colorBlue)
    }

    func renderGeometry() -> RulerRenderGeometry? {
        guard let display = currentDisplay else { return nil }
        let xScale = display.measurement.pointsPerCentimeterX
        let yScale = display.measurement.pointsPerCentimeterY
        return RulerRenderGeometry(
            center: centerScreenPoint,
            left: CGPoint(x: centerScreenPoint.x - arms.leftCM * xScale, y: centerScreenPoint.y),
            right: CGPoint(x: centerScreenPoint.x + arms.rightCM * xScale, y: centerScreenPoint.y),
            up: CGPoint(x: centerScreenPoint.x, y: centerScreenPoint.y + arms.upCM * yScale),
            down: CGPoint(x: centerScreenPoint.x, y: centerScreenPoint.y - arms.downCM * yScale),
            pointsPerCentimeterX: xScale,
            pointsPerCentimeterY: yScale
        )
    }

    private func display(containing point: CGPoint) -> RulerDisplayMetric? {
        displays.first(where: { $0.measurement.frame.contains(point) })
    }

    private func nearestDisplay(to point: CGPoint) -> RulerDisplayMetric? {
        displays.min { lhs, rhs in
            distanceSquared(from: point, to: lhs.measurement.frame) < distanceSquared(from: point, to: rhs.measurement.frame)
        }
    }

    private func distanceSquared(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let x = min(max(point.x, rect.minX), rect.maxX)
        let y = min(max(point.y, rect.minY), rect.maxY)
        let dx = point.x - x
        let dy = point.y - y
        return dx * dx + dy * dy
    }

    private func updatePositionFromCenter(using display: RulerDisplayMetric) {
        let position = display.measurement.centimeterPosition(for: centerScreenPoint)
        positionXCM = min(max(position.x, 0), display.measurement.physicalWidthCM)
        positionYCM = min(max(position.y, 0), display.measurement.physicalHeightCM)
    }

    private func saveGeometry() {
        defaults.set(mode.rawValue, forKey: RulerDefaultsKey.resizeMode)
        defaults.set(Double(arms.leftCM), forKey: RulerDefaultsKey.leftCM)
        defaults.set(Double(arms.rightCM), forKey: RulerDefaultsKey.rightCM)
        defaults.set(Double(arms.upCM), forKey: RulerDefaultsKey.upCM)
        defaults.set(Double(arms.downCM), forKey: RulerDefaultsKey.downCM)
    }

    private func savePosition() {
        defaults.set(Int(currentDisplayID), forKey: RulerDefaultsKey.displayID)
        defaults.set(Double(positionXCM), forKey: RulerDefaultsKey.positionXCM)
        defaults.set(Double(positionYCM), forKey: RulerDefaultsKey.positionYCM)
    }
}
