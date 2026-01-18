import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback onAttachmentTap;

  const MessageInput({
    super.key,
    required this.onSend,
    required this.onAttachmentTap,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showExpandButton = false;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_checkLineCount);
  }

  @override
  void dispose() {
    _controller.removeListener(_checkLineCount);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _checkLineCount() {
    final text = _controller.text;
    
    // 保持与 TextField 一致的字体样式
    const style = TextStyle(fontSize: 16, height: 1.25);
    
    final span = TextSpan(text: text, style: style);
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    );
    
    // 屏幕宽度 - (16+16 outer) - (48 attach) - (12 gap) - (12 gap) - (48 right col) - (32 inner) ≈ 屏幕宽度 - 184
    // 为了更早触发展开按钮，我们多减去一些，假设宽度更窄
    final textContentWidth = MediaQuery.of(context).size.width - 200;
    
    tp.layout(maxWidth: textContentWidth > 0 ? textContentWidth : 0);
    final lineMetrics = tp.computeLineMetrics();
    final lineCount = lineMetrics.length;
    
    // 逻辑：只有当视觉行数 > 3 (即第4行) 时显示
    // 同时如果包含了3个以上的回车符，也视为多行
    final hasEnoughNewlines = '\n'.allMatches(text).length >= 3;
    final isLong = lineCount > 3 || hasEnoughNewlines;
    
    final canSendNow = text.trim().isNotEmpty;

    if (_showExpandButton != isLong || _canSend != canSendNow) {
      setState(() {
        _showExpandButton = isLong;
        _canSend = canSendNow;
      });
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
      setState(() {
        _showExpandButton = false;
        _canSend = false;
      });
    }
  }

  void _openExpandedPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        // 顶部留出状态栏 + 导航栏的高度
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _ExpandedInputContent(
            initialText: _controller.text,
            onSend: (text) {
              widget.onSend(text);
              _controller.clear();
              Navigator.pop(context);
            },
            onSyncBack: (text) {
              _controller.text = text;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: text.length),
              );
            },
          ),
        ),
      ),
    ).then((_) {
      _checkLineCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 附件按钮 (底部对齐)
              Padding(
                padding: const EdgeInsets.only(bottom: 0),
                child: IconButton(
                  icon: const Icon(
                    Icons.attach_file,
                    color: Colors.grey,
                  ),
                  onPressed: widget.onAttachmentTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 12),
              // 输入框区域
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4), // 添加底部间距实现视觉居中
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(fontSize: 16, height: 1.25),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: const InputDecoration(
                      hintText: '输入消息...', // Corrected: Removed unnecessary escaping
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.fromLTRB(16, 10, 16, 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 右侧操作区
              Column(
                mainAxisSize: MainAxisSize.min, // 确保 Column 包裹内容
                mainAxisAlignment: _showExpandButton 
                    ? MainAxisAlignment.spaceBetween 
                    : MainAxisAlignment.end,
                children: [
                    // 上方：展开按钮
                    if (_showExpandButton)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: IconButton(
                          icon: const Icon(Icons.keyboard_arrow_up, color: Colors.black87),
                          tooltip: '展开',
                          onPressed: _openExpandedPanel,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 28,
                        ),
                      ),
                    
                    // 下方：发送按钮
                    Padding(
                      padding: const EdgeInsets.only(bottom: 0),
                      child: IconButton(
                        icon: Icon(
                          Icons.send,
                          color: _canSend ? Colors.black : Colors.grey[400],
                        ),
                        onPressed: _canSend ? _handleSend : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _ExpandedInputContent extends StatefulWidget {
  final String initialText;
  final Function(String) onSend;
  final Function(String) onSyncBack;

  const _ExpandedInputContent({
    required this.initialText,
    required this.onSend,
    required this.onSyncBack,
  });

  @override
  State<_ExpandedInputContent> createState() => _ExpandedInputContentState();
}

class _ExpandedInputContentState extends State<_ExpandedInputContent> {
  late TextEditingController _textController;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _canSend = widget.initialText.trim().isNotEmpty;
    _textController.addListener(() {
      setState(() {
        _canSend = _textController.text.trim().isNotEmpty;
      });
      widget.onSyncBack(_textController.text);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部装饰条
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 内容区域
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  autofocus: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 16, height: 1.25),
                  decoration: const InputDecoration(
                    hintText: '输入消息内容...', // Corrected: Removed unnecessary escaping
                    border: InputBorder.none,
                  ),
                ),
              ),
              // 右侧按钮栏
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 收起按钮
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                    tooltip: '收起',
                    iconSize: 28,
                  ),
                  // 发送按钮（底部）
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: _canSend ? Colors.black : Colors.grey[400],
                      ),
                      onPressed: _canSend 
                          ? () => widget.onSend(_textController.text.trim())
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}