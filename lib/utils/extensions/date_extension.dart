import 'package:intl/intl.dart';
import '../../config/constants.dart';

extension DateExtension on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  bool shouldShowTime(DateTime? previousMessageTime) {
    if (previousMessageTime == null) return true;

    final timeDiff = difference(previousMessageTime).inMinutes;
    return timeDiff.abs() >= AppConstants.messageTimeThreshold;
  }

  String toMessageTime() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(year, month, day);
    final daysDiff = messageDay.difference(today).inDays;

    if (daysDiff == 0) {
      return DateFormat('HH:mm').format(this);
    } else if (daysDiff == -1) {
      return '昨天 ${DateFormat('HH:mm').format(this)}';
    } else if (daysDiff > -7) {
      return DateFormat('EEEE HH:mm', 'zh_CN').format(this);
    } else {
      return DateFormat('yyyy年MM月dd日 HH:mm', 'zh_CN').format(this);
    }
  }
}
