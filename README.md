# 屏幕十字标尺 / Screen Cross Ruler

[![macOS 12+](https://img.shields.io/badge/macOS-12%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Version 1.1.1](https://img.shields.io/badge/version-1.1.1-blue)](https://github.com/Wenshuishi0528/ScreenCrossRuler/releases/latest)
[![CC BY 4.0](https://img.shields.io/badge/license-CC%20BY%204.0-green)](https://creativecommons.org/licenses/by/4.0/)

作者 / Author: **wenshuishi0528**

## 中文介绍

屏幕十字标尺是一款原生 macOS 菜单栏工具。它在所有普通窗口上方显示可拖动的十字坐标标尺，按显示器物理尺寸把刻度换算成厘米，并让标尺以外的透明区域正常穿透鼠标。

### 主要功能

- 始终置顶的透明十字坐标标尺，支持多显示器和全屏空间。
- 拖动中心移动；拖动四个端点调整横轴、纵轴长度。
- 默认“中心对称”缩放，也可切换“四边独立”。
- 在设置中按厘米输入横纵长度和中心位置。
- 标尺颜色可选黄色（默认）、绿色、红色、青色、黑色、白色，也可打开系统选色窗口自选颜色。
- 中文 / English 界面切换，默认中文。
- 毫米刻度开关，默认关闭；关闭时仅显示厘米主刻度。
- 坐标数字开关，默认打开。
- 中心圆透明开关，默认打开；透明时横纵轴在中心断开，只保留黑色外环和原点小黑点。
- 锁定标尺：锁定后中心和端点完全穿透鼠标，避免误拖。
- 运行中再次双击应用，可把标尺找回到鼠标所在显示器中央。
- 所有选项自动保存在本机。

### 安装与使用

1. 从 [Releases](https://github.com/Wenshuishi0528/ScreenCrossRuler/releases/latest) 下载 `ScreenCrossRuler-1.1.1-macOS-universal.zip`。
2. 解压后打开 `屏幕十字标尺.app`。若 macOS 首次阻止打开，请在 Finder 中右键应用并选择“打开”。
3. 拖动中心圆移动整套标尺，拖动四个端点调整长度。
4. 通过菜单栏十字图标打开设置、锁定、隐藏或找回标尺。

应用同时提供未签名 PKG，方便本机测试安装。当前发布产物没有 Apple Developer ID 公证签名，macOS 可能显示安全提示。

### 厘米精度

应用优先读取 macOS 报告的显示器物理宽高，再把屏幕点换算为厘米。电视、投影仪、虚拟显示器或部分转接设备可能报告不准确；设置窗口会显示当前换算来源。当前版本不属于计量认证工具。

---

## English Introduction

Screen Cross Ruler is a native macOS menu bar utility that places a draggable crosshair coordinate ruler above regular windows. It converts ruler lengths to centimeters using each display's reported physical size while allowing mouse clicks to pass through transparent areas.

### Highlights

- Always-on-top transparent crosshair ruler with multi-display and full-screen Space support.
- Drag the center to move; drag four endpoints to resize horizontal and vertical axes.
- Symmetric resizing by default, with an independent four-arm mode.
- Enter axis lengths and center position directly in centimeters.
- Yellow (default), green, red, cyan, black, and white presets, plus a native macOS color panel for custom colors.
- Chinese / English interface, Chinese by default.
- Optional millimeter ticks, off by default; centimeter ticks remain visible.
- Coordinate number visibility, on by default.
- Transparent center toggle, on by default; the axes stop at the center, leaving the black outer ring and a small black origin dot.
- Ruler lock: locked handles become fully click-through to prevent accidental movement.
- Double-open the running app to bring the ruler to the display under the cursor.
- All preferences persist locally.

### Install and Use

1. Download `ScreenCrossRuler-1.1.1-macOS-universal.zip` from [Releases](https://github.com/Wenshuishi0528/ScreenCrossRuler/releases/latest).
2. Extract and open `屏幕十字标尺.app`. If macOS blocks the first launch, Control-click the app in Finder and choose **Open**.
3. Drag the center handle to move the ruler and drag endpoints to resize it.
4. Use the crosshair menu bar icon to open settings, lock, hide, or recover the ruler.

An unsigned PKG is also provided for local testing. Release artifacts are not notarized with an Apple Developer ID, so macOS may display a security warning.

### Centimeter Accuracy

The app uses the physical dimensions reported by macOS for each display. TVs, projectors, virtual displays, and some adapters may report inaccurate dimensions. The settings window shows which conversion source is active. This is not a certified metrology tool.

## Build / 构建

Requirements: Xcode Command Line Tools on macOS 12 or later.

```bash
git clone https://github.com/Wenshuishi0528/ScreenCrossRuler.git
cd ScreenCrossRuler
./test.sh
./package.sh
```

Build outputs / 构建产物：

- `build/屏幕十字标尺.app`
- `dist/ScreenCrossRuler-1.1.1-macOS-universal.zip`
- `dist/ScreenCrossRuler-1.1.1-unsigned.pkg`

## License / 许可

This project is licensed under [Creative Commons Attribution 4.0 International](LICENSE), as requested by the author. Reuse requires attribution.

本项目依照 [知识共享署名 4.0 国际许可协议](LICENSE) 发布，转载、修改或再发布时必须保留署名。

Recommended attribution / 推荐署名：

> Screen Cross Ruler / 屏幕十字标尺 by wenshuishi0528, licensed under CC BY 4.0.
> https://github.com/Wenshuishi0528/ScreenCrossRuler

See [ATTRIBUTION.md](ATTRIBUTION.md) for details.
