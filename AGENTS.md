# Breeze 项目速览（Codex 记忆用）

语言规则
1. 只允许使用简体中文回答 - 所有思考、分析、解释和回答都必须使用简体中文
2. 简体中文优先 - 优先使用中文术语、表达方式和命名规范
3. 简体中文注释 - 生成的代码注释和文档都应使用简体中文
4. 中文思维 - 思考过程和逻辑分析都使用简体中文进行

互动式交流

1. 提问引导：通过提问帮助用户深入理解问题
2. 思路验证：帮助用户验证自己的思路是否正确
3. 代码审查：提供详细的代码审查和改进建议
4. 持续跟进：关注问题解决后的效果和用户反馈

## 项目初始化检查清单
- 分析项目结构和技术栈
- 理解依赖关系和配置文件
- 识别主要模块和功能
- 检查代码质量和规范
- 提供优化建议

## 当前状态
- Flutter 3.35.7；Android：AGP 8.9.1，Kotlin 2.1.0，Gradle 包：`https://mirrors.aliyun.com/macports/distfiles/gradle/gradle-8.9-all.zip`。
- 主要依赖：file_picker 8.0.0，permission_handler 12.0.1，qr_code_scanner_plus 2.0.14，device_info_plus 12.2.0，image_picker 1.2.0，camera 0.11.3，image_gallery_saver_plus 4.0.1，share_plus 12.0.1，provider 6.1.2，sqflite 2.3.3+1，shared_preferences 2.3.3，path_provider 2.1.4，mime 2.0.0，open_filex 4.4.0。
- **新增依赖 (ML Kit)**: google_mlkit_text_recognition 0.15.0 (含离线中文包 text-recognition-chinese 16.0.0), google_mlkit_barcode_scanning 0.14.1, google_mlkit_commons 0.9.0+。

## 目录速览（lib）
- main.dart：入口，直接进入 HomeScreen，初始化 Storage/DB。
- screens/home：home_screen.dart（消息列表、发送、附件）、home_controller.dart（本地消息/文件 CRUD、搜索、扫码结果处理）。
- screens/qr_scan：scan_screen.dart（**统一相机流**：扫码/识字切换、Google ML Kit 识别）、qr_screen.dart（生成/保存/分享 QR）、scan_result_screen.dart（扫码结果展示）。
- widgets/messages：text_message_item.dart、file_message_item.dart、message_action_menu.dart（长按菜单）。
- widgets/home：settings_menu.dart；widgets/common：toast/loading/dialog。
- services/local：db_service.dart（sqflite 三表：messages/files/devices）、storage_service.dart（设备信息、文件存取）。
- utils：permission_util.dart（权限封装），logger.dart，**mlkit_utils.dart** (相机图像流转 InputImage)。

## 已实现要点
- 本地消息/文件存储与展示，搜索框（文本内容）、长按菜单（复制/编辑/删除/生成二维码），消息列表默认最新在底部，发送后无跳动。
- 消息：左滑快捷二维码（松手触发）、右滑删除确认；文件消息可直接打开本地文件并提供确认；文本消息支持识别链接并保持自定义长按菜单；启动耗时日志记录。
- **智能扫码/识字**：
    - **统一相机架构**：使用 `camera` 插件底座 + `Google ML Kit` 算法，实现“扫码”与“识字”模式无缝瞬间切换（无黑屏）。
    - **二维码扫描**：后台实时流检测 (`google_mlkit_barcode_scanning`)，支持相册识别。
    - **OCR 识字**：支持**离线中文/英文识别** (`google_mlkit_text_recognition` + 中文模型包)，全屏取景，拍照后识别。
    - **交互优化**：左右滑动手势切换模式，独立的状态锁防止 UI 卡死，全屏预览（无黑边）。
- 二维码生成/保存/分享，二维码展示与保存 UI 美化。
- 权限申请封装（相机/存储/相册），withValues 避免过时 API。
- Android 桌面快捷方式：长按应用图标可直接唤起“扫一扫”页面并回传结果。
- Android 依赖：因启用 R8 + Flutter deferred components，默认引入 `com.google.android.play:core/core-ktx` 以满足 SplitCompat；**修复 Manifest 合并冲突** (tools:replace)。
- APK 体积：AGP 8.9.1 默认将 so 以未压缩方式打包，已启用 packaging.jniLibs.useLegacyPackaging = true 保持历史体积。

## 待开发/完善（由易到难，含前端/本地为主，后端待建）
1) 消息：多选批量操作/转发完善；文件消息 UI（图片/视频预览、普通文件气泡优化）；真实网络下载与进度、二维码内容改为下载链接；附件选择器需进一步支持分类与预览。
2) 设备/文件管理（本地）：设备列表与删除；清空消息；文件管理入口及列表。
3) 登录认证（本地占位）：主密码登录页、设备初始化与记录；后端建好后接入验证。
4) UI/提示：文件发送/下载进度；网络/权限/同步等关键错误提示与日志；启动耗时、关键流程性能日志细化。
5) 后端/同步（待 Cloudflare/Supabase 项目）：登录/设备/消息同步、WebSocket、文件云存储，提供 API 规范后接入。
6) 其他：退出登录、运行日志扩展（网络/文件/DB/扫码失败等）。

## 近期变更
- **重构扫码模块**：移除 `mobile_scanner`，统一使用 `camera` + `ML Kit`。
- **OCR 增强**：修复中文乱码（引入 `text-recognition-chinese`），实现离线中文识别；修复点击拍照无限 Loading 问题（分离流与拍照状态）。
- **体验优化**：扫码页左右滑动切换模式；修复相机预览比例导致的黑边问题。
- **Android 构建修复**：解决 `AndroidManifest` 中权限声明冲突与 SDK 版本合并错误。
- 消息列表默认展示最新消息在底部（ListView reverse），长按文本编辑能正确更新提示。
- 消息：左滑快捷二维码（松手触发）、右滑删除确认；文件消息支持本地打开；文本链接可点击且菜单保持。

## 运行/调试提示
- 常用命令：`flutter clean`、`flutter pub get`、`flutter run -v`。
- 本地真机权限需重新安装应用测试；Gradle 包使用阿里镜像。
- **注意**：修改了原生依赖（Manifest/Gradle），需 Stop 后重新 Run，热重载无效。

## 约定
- 异步后使用 `context.mounted` 再操作 UI/Navigator。
- UI 透明度用 `withValues(alpha: …)`，避免过时 API。
- 消息列表按时间升序存储，展示时反转 + reverse，默认停留最新。***
- 在完成一个较为完整的任务之后，给出git commit的信息，使用中文信息，内容简洁涵盖本次修改的主要信息，参考以往git提交的记录格式，选取不同的类型：如 fix/feat/build/ci/pref等：xxx。同时继续对AGENTS.md文档进行修改更新，确保记忆正确。

## 文档规范
- 代码注释使用简体中文
- API 文档用简体中文编写
- 技术文档用简体中文撰写
- 用户指南用简体中文说明