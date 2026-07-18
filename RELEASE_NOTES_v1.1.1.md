# 屏幕十字标尺 1.1.1 / Screen Cross Ruler 1.1.1

发布日期 / Release date: 2026-07-18

## 中文

本次更新完善颜色选择，并按用户确认的视觉定义修正透明中心：

- 新增黄色（默认）、绿色、红色、青色、黑色、白色六种颜色预设。
- 选择“自选色…”会立即打开 macOS 原生选色窗口，颜色实时应用并自动保存。
- 中心透明开启时，横轴和纵轴在圆内断开，不穿过透明区域。
- 透明中心保留黑色外环和正中心的小黑色原点。
- 中心透明关闭时，圆内使用当前标尺颜色填充，小黑色原点仍保留。
- 新增中英文颜色名称及颜色预设持久化测试。

## English

This release expands color selection and corrects the transparent-center rendering to match the confirmed design:

- Adds yellow (default), green, red, cyan, black, and white color presets.
- Selecting **Custom Color…** immediately opens the native macOS color panel; changes apply live and persist locally.
- With transparent center enabled, the horizontal and vertical axes stop inside the center circle instead of crossing it.
- The transparent center retains the black outer ring and a small black origin dot at the exact center.
- With transparency disabled, the center uses the current ruler color while retaining the black origin dot.
- Adds bilingual preset labels and persistence coverage for color presets.

## Compatibility / 兼容性

- macOS 12 or later / macOS 12 及以上
- Universal binary: Apple Silicon and Intel / 通用架构：Apple Silicon 与 Intel
- Ad-hoc app signature; unsigned and unnotarized PKG / 应用为 ad-hoc 签名，PKG 未签名且未公证

## License / 许可

Creative Commons Attribution 4.0 International (CC BY 4.0).
作者 / Author: **wenshuishi0528**

## SHA-256

Checksums are included in the attached `SHA256SUMS.txt`. / 校验值见附件 `SHA256SUMS.txt`。
