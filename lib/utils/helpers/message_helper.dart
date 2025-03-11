import '../../models/message.dart';
import '../../config/constants.dart';
import '../extensions/date_extension.dart';

class MessageHelper {
  static bool shouldShowTime(Message? current, Message? previous) {
    if (previous == null) return true;

    final currentTime = DateTime.fromMillisecondsSinceEpoch(current!.timestamp);
    final previousTime = DateTime.fromMillisecondsSinceEpoch(previous.timestamp);

    if (!currentTime.isSameDay(previousTime)) return true;

    final timeDiff = currentTime.difference(previousTime).inMinutes;
    return timeDiff.abs() >= AppConstants.messageTimeThreshold;
  }

  static String getDisplayTime(int timestamp) {
    final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return time.toMessageTime();
  }

  static String formatMessagePreview(Message message, {int maxLength = 50}) {
    String content = message.type == 'text' 
        ? message.content 
        : '[文件消息]';
    
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }
}
