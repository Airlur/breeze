import '../../models/message.dart';
import '../../config/constants.dart';
import '../extensions/date_extension.dart';

class MessageHelper {
  static bool shouldShowTime(Message? current, Message? previous) {
    if (previous == null) return true;

    final currentTime = current!.timestamp;
    final previousTime = previous.timestamp;

    if (!currentTime.isSameDay(previousTime)) return true;

    final timeDiff = currentTime.difference(previousTime).inMinutes;
    return timeDiff.abs() >= AppConstants.messageTimeThreshold;
  }

  static String getDisplayTime(DateTime time) {
    return time.toMessageTime();
  }

  static String formatMessagePreview(Message message, {int maxLength = 50}) {
    final content = message.toQrData();
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }
}
