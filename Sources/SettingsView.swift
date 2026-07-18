import AppKit
import SwiftUI

private let centimeterFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2
    formatter.minimum = 0
    formatter.maximum = 1_000
    formatter.generatesDecimalNumbers = true
    return formatter
}()

struct RulerSettingsView: View {
    @ObservedObject var state: RulerState

    private var language: RulerLanguage { state.language }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                languageSection
                appearanceSection
                resizeModeSection
                lengthSection
                positionSection
                displaySection
                aboutSection
            }
            .padding(22)
        }
        .frame(width: 500, height: 780)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "scope")
                .font(.system(size: 29, weight: .semibold))
                .foregroundColor(Color(nsColor: state.rulerColor))
            VStack(alignment: .leading, spacing: 2) {
                Text(t(.appName))
                    .font(.title2.bold())
                Text(t(.subtitle))
                    .font(.callout)
                    .foregroundColor(.secondary)
                Text("v\(RulerProduct.version) · \(RulerProduct.author)")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
        }
    }

    private var languageSection: some View {
        GroupBox(label: Label(t(.language), systemImage: "character.bubble")) {
            Picker(t(.language), selection: Binding(
                get: { state.language },
                set: { state.setLanguage($0) }
            )) {
                ForEach(RulerLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.vertical, 5)
        }
    }

    private var appearanceSection: some View {
        GroupBox(label: Label(t(.appearance), systemImage: "paintpalette")) {
            VStack(alignment: .leading, spacing: 10) {
                ColorPicker(
                    t(.rulerColor),
                    selection: Binding(
                        get: { Color(nsColor: state.rulerColor) },
                        set: { state.setRulerColor(NSColor($0)) }
                    ),
                    supportsOpacity: false
                )
                Divider()
                Toggle(t(.millimeterTicks), isOn: Binding(
                    get: { state.showsMillimeterTicks },
                    set: { state.setShowsMillimeterTicks($0) }
                ))
                Text(t(.millimeterHelp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Toggle(t(.showNumbers), isOn: Binding(
                    get: { state.showsNumbers },
                    set: { state.setShowsNumbers($0) }
                ))
                Toggle(t(.transparentCenter), isOn: Binding(
                    get: { state.transparentCenter },
                    set: { state.setTransparentCenter($0) }
                ))
                Toggle(t(.lockRuler), isOn: Binding(
                    get: { state.isLocked },
                    set: { state.setLocked($0) }
                ))
                Text(t(.lockHelp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 5)
        }
    }

    private var resizeModeSection: some View {
        GroupBox(label: Label(t(.adjustMode), systemImage: "arrow.left.and.right")) {
            VStack(alignment: .leading, spacing: 10) {
                Picker(t(.adjustMode), selection: Binding(
                    get: { state.mode },
                    set: { state.setMode($0) }
                )) {
                    Text(t(.symmetric)).tag(RulerResizeMode.symmetric)
                    Text(t(.independent)).tag(RulerResizeMode.independent)
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Text(state.mode == .symmetric ? t(.symmetricHelp) : t(.independentHelp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 5)
        }
    }

    private var lengthSection: some View {
        GroupBox(label: Label(t(.lengthCM), systemImage: "ruler")) {
            VStack(spacing: 9) {
                if state.mode == .symmetric {
                    NumericRow(
                        title: t(.horizontalTotal),
                        value: Binding(
                            get: { Double(state.horizontalTotalCM) },
                            set: { state.setHorizontalTotalCM(CGFloat($0)) }
                        )
                    )
                    NumericRow(
                        title: t(.verticalTotal),
                        value: Binding(
                            get: { Double(state.verticalTotalCM) },
                            set: { state.setVerticalTotalCM(CGFloat($0)) }
                        )
                    )
                } else {
                    NumericRow(title: t(.centerToLeft), value: armBinding(.left))
                    NumericRow(title: t(.centerToRight), value: armBinding(.right))
                    NumericRow(title: t(.centerToUp), value: armBinding(.up))
                    NumericRow(title: t(.centerToDown), value: armBinding(.down))
                    Divider()
                    HStack {
                        Text(t(.currentTotal))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(t(.horizontalShort)) \(format(state.horizontalTotalCM)) cm · \(t(.verticalShort)) \(format(state.verticalTotalCM)) cm")
                            .font(.callout.monospacedDigit())
                    }
                }
            }
            .padding(.vertical, 5)
        }
    }

    private var positionSection: some View {
        GroupBox(label: Label(t(.centerPosition), systemImage: "move.3d")) {
            VStack(alignment: .leading, spacing: 9) {
                NumericRow(
                    title: t(.fromLeft),
                    value: Binding(
                        get: { Double(state.positionXCM) },
                        set: { state.setPositionXCM(CGFloat($0)) }
                    )
                )
                NumericRow(
                    title: t(.fromTop),
                    value: Binding(
                        get: { Double(state.positionYCM) },
                        set: { state.setPositionYCM(CGFloat($0)) }
                    )
                )
                Text(t(.positionHelp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button {
                    state.centerOnScreen(containing: NSEvent.mouseLocation)
                } label: {
                    Label(t(.moveToCursorScreen), systemImage: "scope")
                }
                .padding(.top, 2)
            }
            .padding(.vertical, 5)
        }
    }

    private var displaySection: some View {
        GroupBox(label: Label(t(.centimeterConversion), systemImage: "display")) {
            VStack(alignment: .leading, spacing: 5) {
                Text(state.currentDisplayName)
                    .font(.headline)
                Text("\(t(.systemSize)): \(format(state.currentDisplayWidthCM)) × \(format(state.currentDisplayHeightCM)) cm")
                    .font(.callout.monospacedDigit())
                Text(state.conversionDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 5)
        }
    }

    private var aboutSection: some View {
        GroupBox(label: Label(t(.about), systemImage: "info.circle")) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(t(.author)): \(RulerProduct.author)")
                    Spacer()
                    Text("v\(RulerProduct.version)")
                        .monospacedDigit()
                }
                HStack {
                    Text("\(t(.license)): \(RulerProduct.license)")
                    Spacer()
                    Link("creativecommons.org", destination: URL(string: "https://creativecommons.org/licenses/by/4.0/")!)
                }
            }
            .font(.callout)
            .padding(.vertical, 5)
        }
    }

    private func armBinding(_ handle: RulerHandle) -> Binding<Double> {
        Binding(
            get: { Double(armValue(handle)) },
            set: { state.setArm(handle, centimeters: CGFloat($0)) }
        )
    }

    private func armValue(_ handle: RulerHandle) -> CGFloat {
        switch handle {
        case .left: return state.arms.leftCM
        case .right: return state.arms.rightCM
        case .up: return state.arms.upCM
        case .down: return state.arms.downCM
        case .center: return 0
        }
    }

    private func t(_ key: RulerStringKey) -> String {
        rulerText(key, language: language)
    }

    private func format(_ value: CGFloat) -> String {
        centimeterFormatter.string(from: NSNumber(value: Double(value))) ?? "0"
    }
}

private struct NumericRow: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("", value: $value, formatter: centimeterFormatter)
                .multilineTextAlignment(.trailing)
                .frame(width: 92)
            Text("cm")
                .foregroundColor(.secondary)
                .frame(width: 24, alignment: .leading)
        }
    }
}
