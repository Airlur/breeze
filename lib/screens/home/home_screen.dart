import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'home_controller.dart';
import '../../models/message.dart';
import '../../models/text_message.dart';
import '../../models/file_message.dart';
import '../../widgets/messages/text_message_item.dart';
import '../../widgets/messages/file_message_item.dart';
import '../../widgets/input/message_input.dart';
import '../../widgets/common/loading_indicator.dart';
import '../qr/qr_scanner_screen.dart';
import '../qr/qr_result_dialog.dart';
import '../qr/qr_code_widget.dart';
import '../../widgets/common/toast.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mounted) {
        context.read<HomeController>().init();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mounted = false;
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '搜索消息...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                context.read<HomeController>().searchMessages(value);
              },
              textInputAction: TextInputAction.search,
            )
          : const Text('消息列表'),
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
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: _handleScan,
        ),
      ],
    );
  }

  // 处理二维码扫描
  Future<void> _handleScan() async {
    final BuildContext currentContext = context;

    final result = await Navigator.push<String>(
      currentContext,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (!mounted) return;

    if (result != null) {
      QRResultDialog.show(context, result);
    }
  }

  // 处理文件选择
  Future<void> _handleFilePick() async {
    final homeController = context.read<HomeController>();

    final result = await FilePicker.platform.pickFiles();

    if (!mounted) return;

    if (result != null && result.files.isNotEmpty) {
      await homeController.sendFileMessage(result.files.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // 设置整体背景色
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Consumer<HomeController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return const LoadingIndicator();
                }

                if (controller.messages.isEmpty) {
                  return const Center(
                    child: Text('暂无消息'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = controller
                        .messages[controller.messages.length - 1 - index];
                    return _buildMessageItem(message);
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            child: SafeArea(
              child: MessageInput(
                onSend: (text) =>
                    context.read<HomeController>().sendTextMessage(text),
                onPickFile: _handleFilePick,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    if (message is TextMessage) {
      return TextMessageItem(
        message: message,
        onDelete: () =>
            context.read<HomeController>().deleteMessage(message.id),
        onShowQr: () => _showQRCode(message.toQrData()),
        onShowToast: (msg) => Toast.show(context, msg),
        onEdit: (newContent) => context.read<HomeController>().editTextMessage(
              message.id,
              newContent,
            ),
      );
    } else if (message is FileMessage) {
      return FileMessageItem(
        message: message,
        onDelete: () =>
            context.read<HomeController>().deleteMessage(message.id),
        onShowQr: () => _showQRCode(message.toQrData()),
        onShowToast: (msg) => Toast.show(context, msg),
        onDownload: (path) async {
          // TODO: 集成文件下载服务
        },
      );
    }
    return const SizedBox.shrink();
  }

  void _showQRCode(String data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 使用最小所需空间
            children: [
              SizedBox(
                width: 280, // 增加宽度
                height: 250, // 增加高度
                child: QRCodeWidget(data: data),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
