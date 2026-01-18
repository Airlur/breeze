1. 项目概述
目标
实现一个轻量级的跨平台即时通讯应用，支持消息和文件传输。

支持多种部署方式：
- Serverless（优先，基于Cloudflare Workers/Vercel + PostgreSQL + R2/B2/S3）
- 有服务器（Node.js + PostgreSQL）
- Docker自托管

客户端代码统一，能够根据部署方式动态切换后端 API。

2. 核心功能
- 设备认证（主设备+邀请码）
- 消息收发（文本+文件）
- 多设备实时同步
- 二维码生成与扫描
- 文件传输（支持200MB以内）

3. 认证机制
简化后的认证方案：
1. 主密码直接配置在环境变量 MASTER_PASSWORD
2. 用户只需输入这个密码即可登录
3. 首次登录的设备记录到设备表
4. 可以查看和管理设备列表


核心流程：
1. 用户输入主密码
2. 基于主密码生成user_id（保证相同密码生成相同ID）
3. 获取当前设备信息（类型、名称等）
4. 检查并记录设备信息
5. 返回认证token

4. API 接口设计
认证相关:
POST /auth/login
- 用户输入主密码登录

GET /auth/devices
- 获取当前用户的设备列表

DELETE /auth/devices/:id
- 删除指定设备记录

消息相关:
WebSocket /ws/message - 实时消息
- 消息发送接收
- 设备同步
- 心跳检测

POST /messages - 发送消息
GET /messages - 获取消息历史
  - 支持分页
  - 支持时间范围增量同步
DELETE /messages/:id - 删除消息
PUT /messages/:id - 编辑消息
POST /messages/search - 搜索消息

文件相关:
POST /files/presigned - 获取预签名上传URL
POST /files/upload - 上传文件
GET /files/download/:id - 下载文件

二维码相关:
POST /qr/generate - 生成二维码
POST /qr/parse - 解析二维码内容

5. 数据结构
设备表:
```sql
CREATE TABLE devices (
  id SERIAL PRIMARY KEY,
  device_id TEXT NOT NULL UNIQUE,      -- 设备唯一标识
  device_name TEXT NOT NULL,    -- 设备名称
  device_type TEXT NOT NULL,    -- mobile/desktop/web
  is_master BOOLEAN DEFAULT false,  -- 是否为首次登录的设备
  last_active TIMESTAMP,        -- 最后活跃时间
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 创建时间
);
```

消息表:
```sql
CREATE TABLE messages (
  id SERIAL PRIMARY KEY,
  content TEXT NOT NULL, -- 消息内容
  type TEXT NOT NULL, -- 文本消息/文件消息
  sender_device_id TEXT NOT NULL, -- 发送设备ID
  timestamp BIGINT NOT NULL, -- 发送时间戳  
  is_encrypted BOOLEAN DEFAULT false, -- 是否加密   
  is_edited BOOLEAN DEFAULT false, -- 是否编辑过
  is_deleted BOOLEAN DEFAULT false, -- 是否删除
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- 创建时间
);
```

文件表:
```sql
CREATE TABLE files (
  id SERIAL PRIMARY KEY,
  url TEXT NOT NULL, -- 文件URL
  filename TEXT NOT NULL, -- 文件名
  size BIGINT NOT NULL, -- 文件大小
  mime_type TEXT NOT NULL, -- 文件类型
  uploaded_by TEXT NOT NULL, -- 上传设备ID
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- 创建时间
);
```


6. 技术栈
Flutter客户端:
- Flutter 3.x
- Provider (状态管理)
- SQLite (本地数据库)
- dio (网络请求)
- web_socket_channel (WebSocket)
- shared_preferences (本地存储)
- file_picker (文件选择)
- flutter_local_notifications (本地通知)
- qr_flutter (二维码生成)
- camera (二维码扫描)
- flutter_secure_storage (安全存储)
- json_serializable (JSON序列化)
- flutter_i18n (国际化)
- package_info_plus (应用信息)
- device_info_plus (设备信息)
- path_provider (文件路径)
- permission_handler (权限处理)

Serverless后端:
- Vercel/Cloudflare Workers
- Edge Functions
- WebSocket API
- Cloudflare R2/S3 (文件存储)
- PostgreSQL (Neon/Supabase)
- JWT (认证)
- zod (数据验证)
- TypeScript

传统后端:
- Node.js
- Express
- TypeScript
- JWT

7. 开发步骤建议

基础架构搭建:
- 创建Flutter项目
- 配置开发环境
- 搭建基础项目结构
- 配置代码规范和CI/CD

后端开发:
- 认证系统
- WebSocket服务
- 文件上传
- 数据库集成

客户端开发:
- UI框架
- 本地存储
- 网络层
- 消息处理
- 文件处理
- 二维码功能

测试与优化:
- 单元测试
- 集成测试
- 性能优化

后续优化
- 文件支持扩展到2GB+
- 添加断点续传
- 文件压缩
- 端到端加密


