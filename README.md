# LongScreenshot — 滚动长截图

从相册选取多张截图或录屏视频，自动拼接成一张无缝长图。

## 两种使用方式

### 方式一：图片拼接
1. 在任意 App 中手动截多张图（每张图有重叠部分）
2. 打开 LongScreenshot
3. 从相册中选中 2-20 张图
4. 点击「开始拼接」→ 自动生成长图

### 方式二：视频拼接
1. 用系统录屏功能录一段滚动操作的视频
2. 打开 LongScreenshot
3. 从相册中选中录屏视频
4. 自动提取帧 → 拼接 → 生成长图

## 安装到 iPhone

### 编译
GitHub Actions 自动编译，下载 IPA → Sideloadly 安装。

### 安装步骤
1. 从 Actions 下载 `LongScreenshot.ipa`
2. 用 Sideloadly 安装到 iPhone
3. 设置 → 通用 → VPN与设备管理 → 信任证书
4. 打开使用

## 功能

- 🖼️ 图片拼接：智能检测重叠，融合边界
- 🎬 视频拼接：自动提取关键帧
- ✏️ 标注工具：箭头、文字、马赛克
- 📐 裁剪：自定义裁剪区域
- 💾 自动保存到相册

## 技术栈

SwiftUI, Vision, Accelerate, Core Data, Photos
部署目标：iOS 16.0+
