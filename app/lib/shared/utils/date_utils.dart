import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatShort(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatFull(DateTime date) {
    return DateFormat('dd/MM/yyyy - hh:mm a').format(date);
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return DateFormat('dd MMM').format(date);
  }
}
