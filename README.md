# BurnGuard - Android 防烧屏工具

一款基于 Flutter 开发的 Android 防烧屏应用，通过在屏幕上叠加可调节的半透明遮罩来防止 OLED 屏幕烧屏。

## 功能特性

### 核心功能

- **全局悬浮遮罩**: 覆盖在其他应用之上的透明遮罩层
- **多模式防烧屏**:
  - 静态模式: 固定遮罩
  - 漂移模式: 每隔 N 秒微移几个像素
  - 呼吸模式: 透明度缓慢变化
  - 随机模式: 随机位置和透明度微调

### 遮罩配置

- **尺寸调节**: 宽度、高度自定义
- **透明度调节**: 0~100% 可调
- **颜色选择**: 黑色、深灰、灰色、深蓝、深紫
- **圆角设置**: 0-50 像素可调
- **触摸穿透**: 可选允许触摸事件穿透遮罩

### 系统功能

- **悬浮窗权限管理**: 自动检测和请求权限
- **前台服务**: 保证遮罩不被系统杀死
- **开机自启**: 可选开机自动启动
- **设置持久化**: 自动保存用户配置

## 技术架构

### Flutter 层

- **状态管理**: Riverpod
- **本地存储**: SharedPreferences
- **UI 框架**: Material 3

### Android 原生层

- **OverlayService**: 前台服务，管理悬浮窗
- **MainActivity**: Platform Channel 通信桥接
- **BootReceiver**: 开机广播接收器

## 项目结构

```
lib/
├── main.dart
├── models/
│   └── overlay_config.dart      # 遮罩配置模型
├── providers/
│   └── overlay_provider.dart    # Riverpod 状态管理
├── screens/
│   ├── home_screen.dart         # 主页面
│   └── settings_screen.dart     # 设置页面
└── services/
    ├── overlay_service.dart     # Flutter 端服务
    └── storage_service.dart     # 本地存储服务

android/app/src/main/kotlin/com/burnguard/burn_guard/
├── MainActivity.kt              # 主 Activity
├── OverlayService.kt            # 悬浮窗服务
└── BootReceiver.kt              # 开机接收器
```

## 使用说明

1. **授予权限**: 首次启动需要授予悬浮窗权限
2. **开启防烧屏**: 在主页点击开关启用
3. **调整透明度**: 使用滑块调节遮罩透明度
4. **选择模式**: 选择适合的防烧屏模式
5. **高级设置**: 点击右上角设置图标进入详细配置

## 权限说明

- `SYSTEM_ALERT_WINDOW`: 悬浮窗权限，必需
- `FOREGROUND_SERVICE`: 前台服务，保证后台运行
- `FOREGROUND_SERVICE_SPECIAL_USE`: Android 14+ 前台服务类型
- `RECEIVE_BOOT_COMPLETED`: 开机自启
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`: 忽略电池优化

## 编译运行

```bash
# 安装依赖
flutter pub get

# 运行调试版本
flutter run

# 编译 APK
flutter build apk --release
```

## 注意事项

- Android 6.0+ 需要手动授予悬浮窗权限
- Android 14+ 需要声明前台服务类型
- 建议将应用加入电池优化白名单
- 部分厂商 ROM 可能需要额外设置后台运行权限

## 许可证

MIT License
