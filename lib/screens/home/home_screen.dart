import 'dart:async';
import 'dart:io';

import 'package:breeze/utils/shortcut_handler.dart';
import 'package:breeze/widgets/common/toast.dart';
import 'package:breeze/widgets/home/settings_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:open_filex/open_filex.dart';

import 'package:breeze/widgets/messages/message_input.dart';
import '../../models/file.dart';
import '../../models/message.dart';
import '../../utils/logger.dart';
import '../../utils/permission_util.dart';
import '../debug/log_screen.dart';
import '../qr_scan/qr_screen.dart';
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
  final Stopwatch _startupWatch = Stopwatch();
  bool _isOpeningScan = false;

  @override
  void initState() {
    super.initState();
    _startupWatch.start();

    // 初始化消息列表并记录首帧耗时
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().init();
      _startupWatch.stop();
      AppLogger.info(
          'Home 首帧渲染完成，耗时: ${_startupWatch.elapsedMilliseconds}ms');
    });

    // 监听桌面快捷方式
    ShortcutHandler.instance.init(() {
      if (!mounted) return;
      unawaited(_openScanScreen());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            onPressed: _openScanScreen,
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
              return Slidable(
                key: ValueKey(message.id),
                startActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.28,
                  dismissible: DismissiblePane(
                    closeOnCancel: true,
                    onDismissed: () {},
                    confirmDismiss: () async {
                      await _showQrCode(message);
                      return false; // 不移除 item
                    },
                  ),
                  children: [
                    SlidableAction(
                      onPressed: (_) => _showQrCode(message),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      icon: Icons.qr_code_2,
                      label: '二维码',
                    ),
                  ],
                ),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    extentRatio: 0.28,
                    dismissible: DismissiblePane(
                      closeOnCancel: true,
                      onDismissed: () {},
                      confirmDismiss: () => _confirmDelete(message.id),
                    ),
                    children: [
                      SlidableAction(
                        onPressed: (_) => _confirmDelete(message.id),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: '删除',
                    ),
                  ],
                ),
                child: TextMessageItem(
                  message: message,
                  onShowToast: _showToast,
                  onDelete: (message) => _deleteMessage(message.id),
                  onShowQr: (message) => _showQrCode(message),
                ),
              );
            } else {
              return FutureBuilder<FileModel?>(
                future:
                    context.read<HomeController>().getFileInfo(message.content),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  return Slidable(
                    key: ValueKey(message.id),
                    startActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.28,
                      dismissible: DismissiblePane(
                        closeOnCancel: true,
                        onDismissed: () {},
                        confirmDismiss: () async {
                          await _showQrCode(message);
                          return false;
                        },
                      ),
                      children: [
                        SlidableAction(
                          onPressed: (_) => _showQrCode(message),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          icon: Icons.qr_code_2,
                          label: '二维码',
                        ),
                      ],
                    ),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.28,
                      dismissible: DismissiblePane(
                        closeOnCancel: true,
                        onDismissed: () {},
                        confirmDismiss: () => _confirmDelete(message.id),
                      ),
                      children: [
                        SlidableAction(
                          onPressed: (_) => _confirmDelete(message.id),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: '删除',
                        ),
                      ],
                    ),
                    child: FileMessageItem(
                      message: message,
                      fileInfo: snapshot.data!,
                      onShowToast: _showToast,
                      onDelete: (message) => _deleteMessage(message.id),
                      onShowQr: (message) => _showQrCode(message),
                      onDownload: (url) => _handleFileDownload(url),
                    ),
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

  Future<void> _showQrCode(Message message) async {
    String content = message.content;
    if (message.type == 'file') {
      final fileInfo =
          await context.read<HomeController>().getFileInfo(message.content);
      if (fileInfo != null) {
        content = 'file://${fileInfo.url}';
      }
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrScreen(content: content),
      ),
    );
  }

  Future<void> _openScanScreen() async {
    if (_isOpeningScan) return;
    _isOpeningScan = true;
    try {
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
    } finally {
      _isOpeningScan = false;
    }
  }

  Future<void> _handleFileDownload(String url) async {
    final file = File(url);
    if (!await file.exists()) {
      _showToast('文件不存在或已被删除，暂未实现网络下载');
      return;
    }
   if (!mounted) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('打开文件'),
            content: Text(
              '是否使用本机应用打开文件？\n$url',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('打开'),
              ),
            ],
          ),
        ) ??
        false;
 
    // 在打开文件前检查 mounted
    if (!mounted || !confirmed) return;
    final result = await OpenFilex.open(file.path);
    // 在显示结果前检查 mounted
    if (!mounted) return;
    if (result.type != ResultType.done && mounted) {
      _showToast(result.message);
    }
  }

  Future<bool> _confirmDelete(String messageId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await _deleteMessage(messageId);
      return true;
    }
    return false;
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

  Future<void> _pickMedia() async {
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
        type: FileType.media,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        if (!mounted) return;

        if (fileSize > 500 * 1024 * 1024) {
          Toast.warning(context, '文件大小不能超过500MB');
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
                    icon: Icons.photo_library,
                    label: '相册',
                    onTap: _pickMedia,
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
            MessageInput(
              onSend: (text) {
                context.read<HomeController>().sendTextMessage(text);
              },
              onAttachmentTap: _showAttachmentOptions,
            ),
          ],
        ),
      ),
    );
  }
}
