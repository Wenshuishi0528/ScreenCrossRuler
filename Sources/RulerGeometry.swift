import CoreGraphics
import Foundation

enum RulerResizeMode: String, CaseIterable, Codable, Identifiable {
    case symmetric
    case independent

    var id: String { rawValue }
}

enum RulerHandle: String, CaseIterable {
    case center
    case left
    case right
    case up
    case down
}

struct RulerArms: Codable, Equatable {
    static let minimumArmLengthCM: CGFloat = 0.5
    static let maximumArmLengthCM: CGFloat = 500

    var leftCM: CGFloat
    var rightCM: CGFloat
    var upCM: CGFloat
    var downCM: CGFloat

    static let `default` = RulerArms(leftCM: 10, rightCM: 10, upCM: 6, downCM: 6)

    var horizontalTotalCM: CGFloat { leftCM + rightCM }
    var verticalTotalCM: CGFloat { upCM + downCM }

    mutating func resize(_ handle: RulerHandle, distanceCM: CGFloat, mode: RulerResizeMode) {
        let length = Self.clampArm(distanceCM)

        switch (handle, mode) {
        case (.left, .symmetric), (.right, .symmetric):
            leftCM = length
            rightCM = length
        case (.up, .symmetric), (.down, .symmetric):
            upCM = length
            downCM = length
        case (.left, .independent):
            leftCM = length
        case (.right, .independent):
            rightCM = length
        case (.up, .independent):
            upCM = length
        case (.down, .independent):
            downCM = length
        case (.center, _):
            break
        }
    }

    mutating func setHorizontalTotal(_ totalCM: CGFloat) {
        let half = Self.clampArm(totalCM / 2)
        leftCM = half
        rightCM = half
    }

    mutating func setVerticalTotal(_ totalCM: CGFloat) {
        let half = Self.clampArm(totalCM / 2)
        upCM = half
        downCM = half
    }

    mutating func makeSymmetricPreservingTotals() {
        setHorizontalTotal(horizontalTotalCM)
        setVerticalTotal(verticalTotalCM)
    }

    mutating func sanitize() {
        leftCM = Self.clampArm(leftCM)
        rightCM = Self.clampArm(rightCM)
        upCM = Self.clampArm(upCM)
        downCM = Self.clampArm(downCM)
    }

    static func clampArm(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return minimumArmLengthCM }
        return min(max(value, minimumArmLengthCM), maximumArmLengthCM)
    }
}

struct DisplayMeasurement: Equatable {
    let frame: CGRect
    let physicalWidthCM: CGFloat
    let physicalHeightCM: CGFloat
    let usesReportedPhysicalSize: Bool

    init(frame: CGRect, physicalWidthMM: CGFloat?, physicalHeightMM: CGFloat?) {
        self.frame = frame

        if let widthMM = physicalWidthMM,
           let heightMM = physicalHeightMM,
           widthMM >= 50, widthMM <= 2_000,
           heightMM >= 30, heightMM <= 1_500 {
            physicalWidthCM = widthMM / 10
            physicalHeightCM = heightMM / 10
            usesReportedPhysicalSize = true
        } else {
            physicalWidthCM = frame.width / (72 / 2.54)
            physicalHeightCM = frame.height / (72 / 2.54)
            usesReportedPhysicalSize = false
        }
    }

    var pointsPerCentimeterX: CGFloat {
        frame.width / max(physicalWidthCM, 0.01)
    }

    var pointsPerCentimeterY: CGFloat {
        frame.height / max(physicalHeightCM, 0.01)
    }

    func screenPoint(xFromLeftCM: CGFloat, yFromTopCM: CGFloat) -> CGPoint {
        CGPoint(
            x: frame.minX + xFromLeftCM * pointsPerCentimeterX,
            y: frame.maxY - yFromTopCM * pointsPerCentimeterY
        )
    }

    func centimeterPosition(for point: CGPoint) -> CGPoint {
        CGPoint(
            x: (point.x - frame.minX) / pointsPerCentimeterX,
            y: (frame.maxY - point.y) / pointsPerCentimeterY
        )
    }

    func clampedScreenPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, frame.minX), frame.maxX),
            y: min(max(point.y, frame.minY), frame.maxY)
        )
    }
}

struct RulerRenderGeometry {
    let center: CGPoint
    let left: CGPoint
    let right: CGPoint
    let up: CGPoint
    let down: CGPoint
    let pointsPerCentimeterX: CGFloat
    let pointsPerCentimeterY: CGFloat
}
