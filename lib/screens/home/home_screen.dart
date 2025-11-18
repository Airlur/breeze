import 'dart:io';

import 'package:breeze/widgets/common/toast.dart';
import 'package:breeze/widgets/home/settings_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/file.dart';
import '../../models/message.dart';
import '../../utils/permission_util.dart';
import '../debug/log_screen.dart';
import '../qr_scan/scan_screen.dart';
import 'home_controller.dart';
import '../../widgets/messages/file_message_item.dart';
import '../../widgets/messages/text_message_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _canSend = false;
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _canSend = _messageController.text.trim().isNotEmpty;
      });
    });

    // 初始化消息列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.98),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '搜索消息...',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                context.read<HomeController>().searchMessages(value);
              },
            )
          : const Text(
              'Breeze',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
        if (_isSearching)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                context.read<HomeController>().clearSearch();
              });
            },
          ),
        if (!_isSearching) ...[
          IconButton(
            icon: const Icon(Icons.center_focus_weak),
            onPressed: () async {
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScanScreen(),
                ),
              );
              if (!mounted) return;
              if (result != null) {
                await context
                    .read<HomeController>()
                    .handleScanResult(result, context);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LogScreen(),
                ),
              );
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showSettingsMenu(context),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessageList() {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 最新消息在底部，进入页面即看到最新
        final messages = controller.messages.reversed.toList();
        if (messages.isEmpty) {
          return Center(
            child: Text(
              '暂无消息',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            if (message.type == 'text') {
              return TextMessageItem(
                message: message,
                onShowToast: _showToast,
                onDelete: (message) => _deleteMessage(message.id),
                onShowQr: (message) => _showQrCode(message),
              );
            } else {
              return FutureBuilder<FileModel?>(
                future:
                    context.read<HomeController>().getFileInfo(message.content),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  return FileMessageItem(
                    message: message,
                    fileInfo: snapshot.data!,
                    onShowToast: _showToast,
                    onDelete: (message) => _deleteMessage(message.id),
                    onShowQr: (message) => _showQrCode(message),
                    onDownload: (url) => _handleFileDownload(url),
                  );
                },
              );
            }
          },
        );
      },
    );
  }

  void _showToast(String message) {
    if (!mounted) return;
    Toast.success(context, message);
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await context.read<HomeController>().deleteMessage(messageId);
      _showToast('消息已删除');
    } catch (e) {
      _showToast('删除失败：$e');
    }
  }

  void _showQrCode(Message message) {
    // TODO: 实现二维码显示
  }

  Future<void> _handleFileDownload(String url) async {
    // TODO: 实现文件下载
    _showToast('开始下载文件...');
  }

  Future<void> _pickFile(List<String> allowedExtensions) async {
    try {
      Navigator.pop(context); // 关闭底部菜单

      final granted =
          await PermissionUtil().requestStoragePermission(context);
      if (!mounted) return;
      if (!granted) {
        Toast.warning(context, '需要存储权限才能选择文件');
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        if (!mounted) return;

        if (fileSize > 100 * 1024 * 1024) {
          Toast.warning(context, '文件大小不能超过100MB');
          return;
        }

        await context.read<HomeController>().sendFileMessage(file.path);

        if (!mounted) return;
        Toast.success(context, '文件发送成功');
      }
    } catch (e) {
      if (!mounted) return;
      Toast.error(context, '文件发送失败：$e');
    }
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo,
                    label: '图片',
                    onTap: () => _pickFile(['jpg', 'jpeg', 'png', 'gif']),
                  ),
                  _buildAttachmentOption(
                    icon: Icons.folder,
                    label: '文件',
                    onTap: () => _pickFile(
                        ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt']),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDeviceManage(BuildContext context) {
    Navigator.pop(context);
    // TODO: 实现设备管理
  }

  void _handleClearMessages(BuildContext context) {
    Navigator.pop(context);
    // TODO: 实现清空消息
  }

  void _handleFileManage(BuildContext context) {
    Navigator.pop(context);
    // TODO: 实现文件管理
  }

  void _handleLogout(BuildContext context) {
    Navigator.pop(context);
    // TODO: 实现退出登录
  }

  void _showSettingsMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) => Stack(
        children: [
          ModalBarrier(
            color: Colors.transparent,
            dismissible: true,
            onDismiss: () {
              Navigator.pop(context);
            },
          ),
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top,
            right: 8,
            child: SettingsMenu(
              onDeviceManage: () => _handleDeviceManage(context),
              onClearMessages: () => _handleClearMessages(context),
              onFileManage: () => _handleFileManage(context),
              onLogout: () => _handleLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: _buildMessageList(),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.98),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -1),
                    blurRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.attach_file,
                        color: Colors.grey,
                      ),
                      onPressed: _showAttachmentOptions,
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _messageFocusNode,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: '输入消息...',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            isCollapsed: true,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color: _canSend ? Colors.black : Colors.grey[400],
                      ),
                      onPressed: _canSend
                          ? () {
                              final message = _messageController.text.trim();
                              if (message.isNotEmpty) {
                                context
                                    .read<HomeController>()
                                    .sendTextMessage(message);
                                _messageController.clear();
                                FocusScope.of(context).unfocus();
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
