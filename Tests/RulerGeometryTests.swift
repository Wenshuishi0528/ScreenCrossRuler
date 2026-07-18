import CoreGraphics
import Foundation

private enum TestFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message): return message
        }
    }
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw TestFailure.failed(message) }
}

private func approximatelyEqual(_ lhs: CGFloat, _ rhs: CGFloat, tolerance: CGFloat = 0.0001) -> Bool {
    abs(lhs - rhs) <= tolerance
}

@main
private struct RulerGeometryTests {
    static func main() throws {
        var symmetric = RulerArms(leftCM: 3, rightCM: 8, upCM: 2, downCM: 7)
        symmetric.resize(.left, distanceCM: 6.25, mode: .symmetric)
        try require(approximatelyEqual(symmetric.leftCM, 6.25), "symmetric left arm did not resize")
        try require(approximatelyEqual(symmetric.rightCM, 6.25), "symmetric opposite arm did not mirror")
        try require(approximatelyEqual(symmetric.upCM, 2), "horizontal resize changed vertical geometry")

        var independent = RulerArms.default
        independent.resize(.down, distanceCM: 9.5, mode: .independent)
        try require(approximatelyEqual(independent.downCM, 9.5), "independent target arm did not resize")
        try require(approximatelyEqual(independent.upCM, 6), "independent resize changed opposite arm")

        var normalized = RulerArms(leftCM: 2, rightCM: 8, upCM: 3, downCM: 9)
        normalized.makeSymmetricPreservingTotals()
        try require(approximatelyEqual(normalized.leftCM, 5), "horizontal normalization lost total length")
        try require(approximatelyEqual(normalized.rightCM, 5), "horizontal normalization is not symmetric")
        try require(approximatelyEqual(normalized.upCM, 6), "vertical normalization lost total length")
        try require(approximatelyEqual(normalized.downCM, 6), "vertical normalization is not symmetric")

        var clamped = RulerArms.default
        clamped.resize(.right, distanceCM: -12, mode: .independent)
        try require(
            approximatelyEqual(clamped.rightCM, RulerArms.minimumArmLengthCM),
            "endpoint was allowed to cross the center"
        )

        let measurement = DisplayMeasurement(
            frame: CGRect(x: -100, y: 50, width: 1_000, height: 500),
            physicalWidthMM: 500,
            physicalHeightMM: 250
        )
        try require(approximatelyEqual(measurement.pointsPerCentimeterX, 20), "incorrect horizontal cm scale")
        try require(approximatelyEqual(measurement.pointsPerCentimeterY, 20), "incorrect vertical cm scale")

        let point = measurement.screenPoint(xFromLeftCM: 10, yFromTopCM: 5)
        try require(approximatelyEqual(point.x, 100), "X position did not use the screen's left edge")
        try require(approximatelyEqual(point.y, 450), "Y position did not use the screen's top edge")
        let roundTrip = measurement.centimeterPosition(for: point)
        try require(approximatelyEqual(roundTrip.x, 10), "X cm position did not round-trip")
        try require(approximatelyEqual(roundTrip.y, 5), "Y cm position did not round-trip")

        let fallback = DisplayMeasurement(
            frame: CGRect(x: 0, y: 0, width: 720, height: 360),
            physicalWidthMM: nil,
            physicalHeightMM: nil
        )
        try require(!fallback.usesReportedPhysicalSize, "missing display size did not use fallback")
        try require(approximatelyEqual(fallback.pointsPerCentimeterX, 72 / 2.54), "fallback cm scale is incorrect")

        print("RULER_GEOMETRY_TESTS_PASSED")
    }
}
