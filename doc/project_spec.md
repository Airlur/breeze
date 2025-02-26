# Breeze 项目规划文档

## 1. 功能概述

### 1.1 核心功能
- **消息管理**
  - 支持文本消息和文件发送
  - 消息操作：
    - 点击：复制(文本)/下载(文件)
    - 长按：编辑(文本)
    - 左滑：显示二维码
    - 右滑：删除(带确认)
  - 消息时间显示：
    - 每天第一条消息显示完整日期
    - 同一天内相隔30分钟以上显示时间
    - 相隔30分钟以内不显示时间
    - 采用半透明小字体设计

- **顶部功能区**
  - 搜索功能
    - 支持文本消息搜索
    - 支持文件名称搜索
  - 二维码扫描
    - 支持各类二维码识别
    - 识别结果弹窗显示
    - 一键复制功能
    - 操作成功提示

- **底部功能区**
  - 消息输入框
  - 发送按钮
  - 文件选择功能

### 1.2 用户界面
- 采用现代简约设计
- 黑白主色调
- 关键操作需要适当的反馈提示
- 提示信息显示时间适中

## 2. 项目架构

### 2.1 目录结构
```
lib/
├── main.dart
├── config/
│   ├── theme.dart          # 主题配置
│   └── constants.dart      # 常量定义
├── models/
│   ├── message.dart        # 消息模型
│   └── file_message.dart   # 文件消息模型
├── screens/
│   ├── home_screen.dart    # 主页面
│   └── qr_scanner_screen.dart  # 扫描页面
├── widgets/
│   ├── message_item.dart   # 消息项组件
│   ├── file_item.dart      # 文件项组件
│   ├── message_input.dart  # 输入框组件
│   └── custom_dialog.dart  # 自定义弹窗
├── services/
│   ├── storage_service.dart  # 本地存储服务
│   ├── qr_service.dart       # 二维码服务
│   └── network_service.dart  # 网络服务(预留)
└── utils/
    ├── file_helper.dart    # 文件处理工具
    └── message_helper.dart  # 消息处理工具
```

### 2.2 技术选型

#### 依赖清单
- **状态管理**
  - `provider: ^6.1.1` - 轻量级状态管理
  - `flutter_riverpod: ^2.5.1` - 响应式状态管理（备选）

- **存储相关**
  - `sqflite: ^2.3.2` - SQLite数据库
  - `shared_preferences: ^2.2.2` - 键值对存储
  - `path_provider: ^2.1.2` - 文件路径管理
  - `file_picker: ^6.1.1` - 文件选择
  - `permission_handler: ^11.3.0` - 权限管理

- **网络相关**
  - `supabase_flutter: ^2.3.1` - Supabase客户端
  - `connectivity_plus: ^6.0.1` - 网络连接检测
  - `http: ^1.2.1` - HTTP请求

- **UI组件**
  - `flutter_slidable: ^3.0.1` - 滑动操作
  - `qr_code_scanner: ^1.0.1` - 二维码扫描
  - `qr_flutter: ^4.1.0` - 二维码生成
  - `flutter_markdown: ^0.6.20` - Markdown渲染
  - `cached_network_image: ^3.3.1` - 图片缓存

- **工具类**
  - `logger: ^2.0.2+1` - 日志工具
  - `intl: ^0.19.0` - 国际化和日期格式化
  - `uuid: ^4.3.3` - 唯一标识符生成
  - `crypto: ^3.0.3` - 加密工具

- **开发工具**
  - `flutter_lints: ^3.0.1` - 代码规范
  - `build_runner: ^2.4.8` - 代码生成
  - `mockito: ^5.4.4` - 单元测试

#### 权限配置
**Android (android/app/src/main/AndroidManifest.xml)**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/> <!-- 二维码扫描 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

**iOS (ios/Runner/Info.plist)**
```xml
<key>NSCameraUsageDescription</key>
<string>需要使用相机进行二维码扫描</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以选择文件</string>
```

## 3. 开发路线

### 3.1 第一阶段：本地功能
1. 基础UI框架搭建
2. 本地消息收发功能
3. 文件管理功能
4. 二维码功能
5. 搜索功能

### 3.2 第二阶段：在线功能
1. Supabase集成
2. 用户系统
3. 消息同步
4. 文件云存储
5. 多设备支持

## 4. 注意事项

### 4.1 性能考虑
- 消息列表采用懒加载
- 大文件处理需要进度提示
- 图片缓存机制
- 本地数据定期清理

### 4.2 用户体验
- 操作反馈及时
- 错误提示友好
- 加载状态明确
- 动画过渡自然

### 4.3 代码规范
- 遵循Flutter代码规范
- 注重代码复用性
- 保持良好的注释
- 单元测试覆盖

## 5. 后续扩展
- 消息加密
- 群组功能
- 消息提醒
- 主题定制
- 国际化支持 