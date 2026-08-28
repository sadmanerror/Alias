import 'package:intl/intl.dart';

class DateFormatter {
  static String formatMessageTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  static String format(DateTime dt) => formatChatListTime(dt);

  static String formatChatListTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(dt.year, dt.month, dt.day);

    if (dateToCheck == today) {
      return DateFormat('HH:mm').format(dt);
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (dateToCheck == yesterday) {
      return 'Yesterday';
    }

    final difference = today.difference(dateToCheck).inDays;
    if (difference < 7) {
      return DateFormat('EEEE').format(dt);
    }

    return DateFormat('dd/MM/yyyy').format(dt);
  }

  static String formatLastSeen(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inSeconds < 60) {
      return 'last seen just now';
    } else if (difference.inMinutes < 60) {
      final min = difference.inMinutes;
      return 'last seen $min minute${min > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'last seen $hours hour${hours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'last seen $days day${days > 1 ? 's' : ''} ago';
    } else {
      return 'last seen on ${DateFormat('dd MMM').format(dt)}';
    }
  }
}
