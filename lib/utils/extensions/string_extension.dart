extension StringExtension on String {
  String get fileExtension {
    return split('.').last.toLowerCase();
  }

  String get fileName {
    return split('/').last;
  }

  String get fileNameWithoutExtension {
    final name = fileName;
    final lastDot = name.lastIndexOf('.');
    return lastDot != -1 ? name.substring(0, lastDot) : name;
  }

  String formatFileSize() {
    try {
      final size = double.parse(this);
      if (size < 1024) return '${size.toStringAsFixed(2)}B';
      if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)}KB';
      if (size < 1024 * 1024 * 1024) {
        return '${(size / (1024 * 1024)).toStringAsFixed(2)}MB';
      }
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
    } catch (e) {
      return this;
    }
  }
}
