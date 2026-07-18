import Foundation

enum RulerLanguage: String, CaseIterable, Identifiable {
    case zh
    case en

    var id: String { rawValue }
    var displayName: String { self == .zh ? "中文" : "English" }
}

enum RulerStringKey {
    case appName
    case settingsTitle
    case subtitle
    case language
    case appearance
    case rulerColor
    case millimeterTicks
    case millimeterHelp
    case showNumbers
    case transparentCenter
    case lockRuler
    case lockHelp
    case adjustMode
    case symmetric
    case independent
    case symmetricHelp
    case independentHelp
    case lengthCM
    case horizontalTotal
    case verticalTotal
    case centerToLeft
    case centerToRight
    case centerToUp
    case centerToDown
    case currentTotal
    case horizontalShort
    case verticalShort
    case centerPosition
    case fromLeft
    case fromTop
    case positionHelp
    case moveToCursorScreen
    case centimeterConversion
    case systemSize
    case reportedPhysicalSize
    case fallbackPhysicalSize
    case noDisplay
    case about
    case author
    case license
    case showRuler
    case hideRuler
    case modeSymmetricMenu
    case modeIndependentMenu
    case lock
    case unlock
    case moveCurrentScreen
    case settings
    case quit
}

func rulerText(_ key: RulerStringKey, language: RulerLanguage) -> String {
    let text: (zh: String, en: String)
    switch key {
    case .appName: text = ("屏幕十字标尺", "Screen Cross Ruler")
    case .settingsTitle: text = ("屏幕十字标尺设置", "Screen Cross Ruler Settings")
    case .subtitle: text = ("拖中心移动，拖四个圆形端点调整长度", "Drag the center to move; drag endpoints to resize")
    case .language: text = ("界面语言", "Language")
    case .appearance: text = ("外观与显示", "Appearance & Display")
    case .rulerColor: text = ("标尺颜色", "Ruler color")
    case .millimeterTicks: text = ("显示毫米刻度", "Show millimeter ticks")
    case .millimeterHelp: text = ("关闭时仅显示厘米主刻度。", "When off, only centimeter ticks are shown.")
    case .showNumbers: text = ("显示坐标数字", "Show coordinate numbers")
    case .transparentCenter: text = ("中心圆透明", "Transparent center")
    case .lockRuler: text = ("锁定标尺", "Lock ruler")
    case .lockHelp: text = ("锁定后中心和端点完全穿透鼠标，防止误拖。", "Locked handles pass clicks through to prevent accidental dragging.")
    case .adjustMode: text = ("调整方式", "Resize Mode")
    case .symmetric: text = ("中心对称", "Symmetric")
    case .independent: text = ("四边独立", "Independent")
    case .symmetricHelp: text = ("拖动任一端点时，对侧同步变化，中心保持不动。", "Dragging one endpoint mirrors the opposite side while the center stays fixed.")
    case .independentHelp: text = ("左、右、上、下四段分别调整，其他端点保持不动。", "Left, right, up, and down arms resize independently.")
    case .lengthCM: text = ("长度（厘米）", "Length (centimeters)")
    case .horizontalTotal: text = ("横轴总长度", "Horizontal total")
    case .verticalTotal: text = ("纵轴总长度", "Vertical total")
    case .centerToLeft: text = ("中心到左端", "Center to left")
    case .centerToRight: text = ("中心到右端", "Center to right")
    case .centerToUp: text = ("中心到上端", "Center to top")
    case .centerToDown: text = ("中心到下端", "Center to bottom")
    case .currentTotal: text = ("当前总长度", "Current totals")
    case .horizontalShort: text = ("横", "H")
    case .verticalShort: text = ("纵", "V")
    case .centerPosition: text = ("中心位置（厘米）", "Center Position (centimeters)")
    case .fromLeft: text = ("距屏幕左边 X", "X from left edge")
    case .fromTop: text = ("距屏幕上边 Y", "Y from top edge")
    case .positionHelp: text = ("左上角为原点；数值会限制在当前显示器范围内。", "Origin is the top-left; values are clamped to the current display.")
    case .moveToCursorScreen: text = ("把标尺移到鼠标所在屏幕中央", "Move ruler to cursor screen center")
    case .centimeterConversion: text = ("厘米换算", "Centimeter Conversion")
    case .systemSize: text = ("系统尺寸", "System size")
    case .reportedPhysicalSize: text = ("使用系统报告的显示器物理尺寸换算", "Using the physical display size reported by macOS")
    case .fallbackPhysicalSize: text = ("显示器未报告物理尺寸，暂按 macOS 标准点换算", "No physical size reported; using standard macOS point conversion")
    case .noDisplay: text = ("暂时无法换算厘米", "No display available for centimeter conversion")
    case .about: text = ("关于", "About")
    case .author: text = ("作者", "Author")
    case .license: text = ("许可", "License")
    case .showRuler: text = ("显示标尺", "Show Ruler")
    case .hideRuler: text = ("隐藏标尺", "Hide Ruler")
    case .modeSymmetricMenu: text = ("调整方式：中心对称", "Resize Mode: Symmetric")
    case .modeIndependentMenu: text = ("调整方式：四边独立", "Resize Mode: Independent")
    case .lock: text = ("锁定标尺", "Lock Ruler")
    case .unlock: text = ("解锁标尺", "Unlock Ruler")
    case .moveCurrentScreen: text = ("移到当前屏幕中央", "Move to Current Screen Center")
    case .settings: text = ("设置…", "Settings…")
    case .quit: text = ("退出屏幕十字标尺", "Quit Screen Cross Ruler")
    }
    return language == .zh ? text.zh : text.en
}

enum RulerProduct {
    static let author = "wenshuishi0528"
    static let license = "CC BY 4.0"

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.0"
    }
}
