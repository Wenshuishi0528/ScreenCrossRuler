import AppKit
import Combine

final class RulerOverlayView: NSView {
    private let state: RulerState
    private var cancellables = Set<AnyCancellable>()
    private(set) var activeDragHandle: RulerHandle?

    init(frame frameRect: NSRect, state: RulerState) {
        self.state = state
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        state.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.needsDisplay = true
                    self.window?.invalidateCursorRects(for: self)
                }
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let geometry = localGeometry(), let context = NSGraphicsContext.current?.cgContext else { return }

        context.saveGState()
        context.setLineCap(.round)
        context.setLineJoin(.round)

        drawAxisLines(geometry, in: context, color: NSColor.black.withAlphaComponent(0.82), width: 4.5)
        drawTicks(geometry, in: context, color: NSColor.black.withAlphaComponent(0.82), width: 3.2)

        let rulerColor = state.rulerColor
        drawAxisLines(geometry, in: context, color: rulerColor, width: 1.8)
        drawTicks(geometry, in: context, color: rulerColor, width: 1.2)
        if state.showsNumbers {
            drawLabels(geometry)
        }
        drawHandles(geometry, in: context, color: rulerColor)
        context.restoreGState()
    }

    func hitTarget(atGlobalPoint point: CGPoint) -> RulerHandle? {
        guard !state.isLocked, let geometry = state.renderGeometry() else { return nil }
        let targets: [(RulerHandle, CGPoint, CGFloat)] = [
            (.center, geometry.center, 14),
            (.left, geometry.left, 12),
            (.right, geometry.right, 12),
            (.up, geometry.up, 12),
            (.down, geometry.down, 12)
        ]

        return targets.first(where: { _, targetPoint, tolerance in
            hypot(point.x - targetPoint.x, point.y - targetPoint.y) <= tolerance
        })?.0
    }

    override func mouseDown(with event: NSEvent) {
        let point = NSEvent.mouseLocation
        guard let handle = hitTarget(atGlobalPoint: point) else { return }
        activeDragHandle = handle
        if handle == .center {
            NSCursor.closedHand.set()
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let handle = activeDragHandle else { return }
        let point = NSEvent.mouseLocation
        if handle == .center {
            state.moveCenter(to: point)
        } else {
            state.resize(handle, toward: point)
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let handle = activeDragHandle else { return }
        if handle == .center {
            state.finishMove()
        } else {
            state.finishResize()
        }
        activeDragHandle = nil
        window?.invalidateCursorRects(for: self)
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        guard !state.isLocked, let geometry = localGeometry() else { return }
        addCursorRect(rect(around: geometry.center, radius: 14), cursor: .openHand)
        addCursorRect(rect(around: geometry.left, radius: 12), cursor: .resizeLeftRight)
        addCursorRect(rect(around: geometry.right, radius: 12), cursor: .resizeLeftRight)
        addCursorRect(rect(around: geometry.up, radius: 12), cursor: .resizeUpDown)
        addCursorRect(rect(around: geometry.down, radius: 12), cursor: .resizeUpDown)
    }

    private func localGeometry() -> RulerRenderGeometry? {
        guard let geometry = state.renderGeometry(), let window else { return nil }
        let origin = window.frame.origin
        func local(_ point: CGPoint) -> CGPoint {
            CGPoint(x: point.x - origin.x, y: point.y - origin.y)
        }
        return RulerRenderGeometry(
            center: local(geometry.center),
            left: local(geometry.left),
            right: local(geometry.right),
            up: local(geometry.up),
            down: local(geometry.down),
            pointsPerCentimeterX: geometry.pointsPerCentimeterX,
            pointsPerCentimeterY: geometry.pointsPerCentimeterY
        )
    }

    private func drawAxisLines(
        _ geometry: RulerRenderGeometry,
        in context: CGContext,
        color: NSColor,
        width: CGFloat
    ) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(width)
        context.beginPath()
        context.move(to: geometry.left)
        context.addLine(to: geometry.right)
        context.move(to: geometry.down)
        context.addLine(to: geometry.up)
        context.strokePath()
    }

    private func drawTicks(
        _ geometry: RulerRenderGeometry,
        in context: CGContext,
        color: NSColor,
        width: CGFloat
    ) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(width)
        context.beginPath()

        let horizontalStart = Int(ceil((geometry.left.x - geometry.center.x) / geometry.pointsPerCentimeterX * 10))
        let horizontalEnd = Int(floor((geometry.right.x - geometry.center.x) / geometry.pointsPerCentimeterX * 10))
        if horizontalStart <= horizontalEnd {
            for tenth in horizontalStart...horizontalEnd {
                if !state.showsMillimeterTicks, tenth % 10 != 0 { continue }
                let x = geometry.center.x + CGFloat(tenth) / 10 * geometry.pointsPerCentimeterX
                let tick = tickLength(for: tenth)
                context.move(to: CGPoint(x: x, y: geometry.center.y - tick))
                context.addLine(to: CGPoint(x: x, y: geometry.center.y + tick))
            }
        }

        let verticalStart = Int(ceil((geometry.down.y - geometry.center.y) / geometry.pointsPerCentimeterY * 10))
        let verticalEnd = Int(floor((geometry.up.y - geometry.center.y) / geometry.pointsPerCentimeterY * 10))
        if verticalStart <= verticalEnd {
            for tenth in verticalStart...verticalEnd {
                if !state.showsMillimeterTicks, tenth % 10 != 0 { continue }
                let y = geometry.center.y + CGFloat(tenth) / 10 * geometry.pointsPerCentimeterY
                let tick = tickLength(for: tenth)
                context.move(to: CGPoint(x: geometry.center.x - tick, y: y))
                context.addLine(to: CGPoint(x: geometry.center.x + tick, y: y))
            }
        }
        context.strokePath()
    }

    private func drawLabels(_ geometry: RulerRenderGeometry) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: NSColor.white,
            .strokeColor: NSColor.black.withAlphaComponent(0.95),
            .strokeWidth: -3.2
        ]

        let horizontalStart = Int(ceil((geometry.left.x - geometry.center.x) / geometry.pointsPerCentimeterX))
        let horizontalEnd = Int(floor((geometry.right.x - geometry.center.x) / geometry.pointsPerCentimeterX))
        if horizontalStart <= horizontalEnd {
            for centimeter in horizontalStart...horizontalEnd where centimeter != 0 {
                let text = NSAttributedString(string: coordinateText(centimeter), attributes: attributes)
                let size = text.size()
                let x = geometry.center.x + CGFloat(centimeter) * geometry.pointsPerCentimeterX
                text.draw(at: CGPoint(x: x - size.width / 2, y: geometry.center.y - 22))
            }
        }

        let verticalStart = Int(ceil((geometry.down.y - geometry.center.y) / geometry.pointsPerCentimeterY))
        let verticalEnd = Int(floor((geometry.up.y - geometry.center.y) / geometry.pointsPerCentimeterY))
        if verticalStart <= verticalEnd {
            for centimeter in verticalStart...verticalEnd where centimeter != 0 {
                let text = NSAttributedString(string: coordinateText(centimeter), attributes: attributes)
                let size = text.size()
                let y = geometry.center.y + CGFloat(centimeter) * geometry.pointsPerCentimeterY
                text.draw(at: CGPoint(x: geometry.center.x + 10, y: y - size.height / 2))
            }
        }

        let zero = NSAttributedString(string: "0", attributes: attributes)
        zero.draw(at: CGPoint(x: geometry.center.x + 9, y: geometry.center.y - 22))
    }

    private func drawHandles(_ geometry: RulerRenderGeometry, in context: CGContext, color: NSColor) {
        let endpoints = [geometry.left, geometry.right, geometry.up, geometry.down]
        for point in endpoints {
            context.setFillColor(NSColor.black.withAlphaComponent(0.86).cgColor)
            context.fillEllipse(in: rect(around: point, radius: 7))
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: rect(around: point, radius: 4.5))
        }

        context.setFillColor(NSColor.black.withAlphaComponent(0.9).cgColor)
        context.fillEllipse(in: rect(around: geometry.center, radius: 10))
        if state.transparentCenter {
            context.saveGState()
            context.setBlendMode(.clear)
            context.fillEllipse(in: rect(around: geometry.center, radius: 6.5))
            context.restoreGState()
        } else {
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: rect(around: geometry.center, radius: 6.5))
        }
        context.setFillColor(NSColor.black.withAlphaComponent(0.95).cgColor)
        context.fillEllipse(in: rect(around: geometry.center, radius: 2.2))
    }

    private func tickLength(for tenth: Int) -> CGFloat {
        if tenth % 10 == 0 { return 8 }
        if tenth % 5 == 0 { return 5.5 }
        return 3
    }

    private func coordinateText(_ value: Int) -> String {
        value < 0 ? "−\(-value)" : "\(value)"
    }

    private func rect(around point: CGPoint, radius: CGFloat) -> CGRect {
        CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
    }
}

final class RulerOverlayController {
    private let state: RulerState
    private let panel: NSPanel
    private let overlayView: RulerOverlayView
    private var pointerTimer: Timer?
    private var screenObserver: NSObjectProtocol?

    init(state: RulerState) {
        self.state = state
        let frame = Self.combinedScreenFrame()
        panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        overlayView = RulerOverlayView(frame: CGRect(origin: .zero, size: frame.size), state: state)

        panel.contentView = overlayView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.acceptsMouseMovedEvents = true
        panel.ignoresMouseEvents = true

        pointerTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.refreshMousePassThrough()
        }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.screenParametersChanged()
        }
    }

    deinit {
        pointerTimer?.invalidate()
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    func show() {
        state.setVisible(true)
        panel.orderFrontRegardless()
    }

    func hide() {
        state.setVisible(false)
        panel.orderOut(nil)
    }

    func stop() {
        pointerTimer?.invalidate()
        pointerTimer = nil
        panel.orderOut(nil)
    }

    private func refreshMousePassThrough() {
        guard state.isVisible else { return }
        let shouldReceiveMouse = overlayView.activeDragHandle != nil
            || overlayView.hitTarget(atGlobalPoint: NSEvent.mouseLocation) != nil
        if panel.ignoresMouseEvents == shouldReceiveMouse {
            panel.ignoresMouseEvents = !shouldReceiveMouse
        }
    }

    private func screenParametersChanged() {
        let frame = Self.combinedScreenFrame()
        panel.setFrame(frame, display: true)
        overlayView.frame = CGRect(origin: .zero, size: frame.size)
        state.refreshScreens()
        overlayView.needsDisplay = true
    }

    private static func combinedScreenFrame() -> CGRect {
        NSScreen.screens.map(\.frame).reduce(CGRect.null) { $0.union($1) }
    }
}
