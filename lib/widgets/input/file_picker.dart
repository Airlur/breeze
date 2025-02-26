import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../config/constants.dart';

class FilePickerWidget extends StatefulWidget {
  final Function(PlatformFile) onFileSelected;
  final Function(String) onError;  // 添加错误回调

  const FilePickerWidget({
    super.key,
    required this.onFileSelected,
    required this.onError,
  });

  @override
  State<FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<FilePickerWidget> {
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (!_mounted) return;

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // 检查文件大小
        if (file.size > AppConstants.maxFileSize) {
          if (_mounted) {
            widget.onError(AppConstants.errorFileTooBig);
          }
          return;
        }

        // 检查文件类型
        final fileType = file.extension?.toLowerCase() ?? '';
        if (!AppConstants.supportedFileTypes.contains(fileType)) {
          if (_mounted) {
            widget.onError(AppConstants.errorFileTypeNotSupported);
          }
          return;
        }

        widget.onFileSelected(file);
      }
    } catch (e) {
      if (_mounted) {
        widget.onError('选择文件失败：$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.attach_file),
      onPressed: _pickFile,
    );
  }
}
