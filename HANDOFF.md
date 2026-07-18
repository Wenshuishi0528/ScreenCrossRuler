# HANDOFF — 屏幕十字标尺 / Screen Cross Ruler

## 当前状态

- 版本：1.1.0（build 3）
- 作者：wenshuishi0528
- 许可：Creative Commons Attribution 4.0 International（CC BY 4.0）
- 平台：macOS 12 及以上
- 架构：arm64 + x86_64 通用应用
- 工程边界：当前 `屏幕十字标尺` 独立仓库根目录
- Bundle ID：`local.codex.screen-cross-ruler`
- GitHub 目标：`Wenshuishi0528/ScreenCrossRuler`（Public）

## 1.1.0 已实现

- 无边框透明悬浮层，窗口级别为 `screenSaver`，可加入所有 Space 和全屏空间。
- 中心拖动整套标尺；四个端点拖动长度。
- “中心对称”和“四边独立”两种缩放模式。
- 设置窗口按厘米输入长度及中心位置；位置以显示器左上角为原点。
- 自定义标尺颜色。
- 中文 / English 设置与菜单即时切换。
- 毫米刻度显示开关；关闭时只绘制厘米主刻度。
- 坐标数字显示开关。
- 中心圆颜色填充透明开关。
- 锁定标尺；锁定后中心和四端点不再接收鼠标，悬浮层完全穿透操作区域。
- 优先使用 `CGDisplayScreenSize` 的物理毫米尺寸换算；跨显示器时重新换算。
- 首次启动主动显示设置；运行中再次打开应用时，将标尺移到鼠标所在屏幕中央。
- 设置窗口与菜单栏均提供“移到当前屏幕中央”。
- 设置通过 `UserDefaults` 持久化。
- 设置窗口显示版本、作者和 CC BY 4.0 许可。

## 新选项默认值

- 界面语言：中文。
- 毫米刻度：关闭。
- 坐标数字：打开。
- 中心圆透明：打开。
- 标尺锁定：关闭。
- 标尺颜色：黄色（RGB 1.00 / 0.78 / 0.12）。

## 设计决定

- “横轴/纵轴长度”指整条轴总长度。
- 对称模式中，两端到中心的距离相等；从独立模式切回时保留总长度再平均分配。
- 独立模式的设置面板显示左、右、上、下四段长度。
- 单段最短 0.5 cm、最长 500 cm；端点不能穿过中心。
- 黑色外描边保留，不随用户颜色改变，以确保浅色背景下仍可辨认。
- “中心透明”会清除中心孔内的轴线和填充，只保留黑色外环。
- “锁定”只禁用拖拽命中，不影响设置窗口精确输入或跨屏找回。
- CC BY 4.0 按用户明确要求应用于整个公开项目；`ATTRIBUTION.md` 给出中英文署名方式。

## 代码结构

- `Sources/RulerGeometry.swift`：纯几何、缩放规则和厘米换算。
- `Sources/Localization.swift`：中英文字符串、作者和版本信息。
- `Sources/RulerState.swift`：显示器、颜色、开关、位置及持久化。
- `Sources/RulerOverlayView.swift`：绘制、命中、拖拽、始终置顶和鼠标穿透。
- `Sources/SettingsView.swift`：双语设置界面。
- `Sources/main.swift`：应用生命周期、双语菜单栏和设置窗口。
- `Tests/RulerGeometryTests.swift`：缩放、限制和厘米坐标测试。
- `Tests/RulerPreferencesTests.swift`：新选项默认值、持久化、颜色和本地化测试。

## 验证命令

```bash
cd /path/to/ScreenCrossRuler
./test.sh
./package.sh
```

`test.sh` 执行：

- 几何单元测试。
- 设置默认值与持久化测试。
- arm64 + x86_64 通用构建。
- 悬浮层与设置窗口真实启动/退出冒烟。
- 严格代码签名验证。
- 双架构检查。

## 1.1.0 已完成的界面验证

- 中文默认界面：毫米关闭、数字打开、中心透明、未锁定。
- 英文组合界面：青色、毫米打开、数字关闭、中心不透明、锁定。
- 英文窗口标题为 `Screen Cross Ruler Settings`，中文标题为 `屏幕十字标尺设置`。
- 两种组合下，设置窗口 `layer=0`、悬浮层 `layer=1000`，均处于屏幕上。

## 1.1.0 最终质量门

- `RULER_GEOMETRY_TESTS_PASSED`。
- `RULER_PREFERENCES_TESTS_PASSED`。
- `APP_SMOKE_TEST_PASSED`。
- `codesign --verify --deep --strict`：通过，签名类型为 ad-hoc。
- `lipo -archs`：`x86_64 arm64`。
- ZIP `unzip -t`：无压缩数据错误。
- PKG `pkgutil --check-signature`：按预期为 `no signature`。
- ZIP SHA-256：`88790df55e9b8e02b2c851a4e44e05da4f9da831f7bb0f387515bc7656224d78`。
- PKG SHA-256：`8d555382bc8a6206269b090239c111873d574c1acc9c614cf9205af5e8d40927`。

## 发布产物

- `dist/ScreenCrossRuler-1.1.0-macOS-universal.zip`
- `dist/ScreenCrossRuler-1.1.0-unsigned.pkg`

发布产物采用本机 ad-hoc 应用签名；PKG 未签名；均未经过 Apple Developer ID 公证。

## 已知边界

- 实物厘米精度依赖显示器向 macOS 报告的物理尺寸；电视、投影仪、虚拟显示器和部分转接设备可能报告不准。
- 当前没有每台显示器独立的手工校准系数，不属于计量认证工具。
- 应用是菜单栏工具，默认不显示 Dock 图标。
- 锁定后无法直接拖动，需在设置或菜单栏中解锁。
