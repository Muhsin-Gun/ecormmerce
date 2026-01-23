import 'package:intl/intl.dart';
import '../constants/constants.dart';

/// Date and time helper utilities for ProMarket
class DateHelpers {
  // Prevent instantiation
  DateHelpers._();

  // ==================== DATE FORMATTING ====================
  
  /// Formats date to short format (dd/MM/yyyy)
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormatShort).format(date);
  }

  /// Formats date to long format (MMMM dd, yyyy)
  static String formatDateLong(DateTime date) {
    return DateFormat(AppConstants.dateFormatLong).format(date);
  }

  /// Formats date to full format (EEEE, MMMM dd, yyyy)
  static String formatDateFull(DateTime date) {
    return DateFormat(AppConstants.dateFormatFull).format(date);
  }

  /// Formats time (HH:mm)
  static String formatTime(DateTime time) {
    return DateFormat(AppConstants.timeFormat).format(time);
  }

  /// Formats date and time (dd/MM/yyyy HH:mm)
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }

  // ==================== RELATIVE TIME ====================
  
  /// Formats date as relative time (e.g., "2 hours ago", "3 days ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Formats message timestamp (Today, Yesterday, or date)
  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return formatTime(dateTime);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEEE').format(dateTime); // Day name
    } else {
      return formatDate(dateTime);
    }
  }

  // ==================== TIME DIFFERENCE ====================
  
  /// Gets time difference in human-readable format
  static String getTimeDifference(DateTime start, DateTime end) {
    final difference = end.difference(start);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return '${difference.inSeconds} ${difference.inSeconds == 1 ? 'second' : 'seconds'}';
    }
  }

  /// Gets remaining time from now
  static String getRemainingTime(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h remaining';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m remaining';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m remaining';
    } else {
      return '${difference.inSeconds}s remaining';
    }
  }

  // ==================== DATE COMPARISONS ====================
  
  /// Checks if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Checks if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Checks if date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    return date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
        date.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  /// Checks if date is this month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Checks if date is this year
  static bool isThisYear(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }

  // ==================== DATE CALCULATIONS ====================
  
  /// Gets start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Gets end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Gets start of week
  static DateTime startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Gets end of week
  static DateTime endOfWeek(DateTime date) {
    return startOfWeek(date).add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }

  /// Gets start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Gets end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  /// Gets start of year
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Gets end of year
  static DateTime endOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59);
  }

  // ==================== AGE CALCULATION ====================
  
  /// Calculates age from birth date
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  // ==================== BUSINESS DAYS ====================
  
  /// Checks if date is a weekend
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Checks if date is a weekday
  static bool isWeekday(DateTime date) {
    return !isWeekend(date);
  }

  /// Adds business days to a date (excluding weekends)
  static DateTime addBusinessDays(DateTime date, int days) {
    DateTime result = date;
    int addedDays = 0;
    
    while (addedDays < days) {
      result = result.add(const Duration(days: 1));
      if (isWeekday(result)) {
        addedDays++;
      }
    }
    
    return result;
  }

  // ==================== DATE RANGES ====================
  
  /// Gets date range for "Last 7 days"
  static (DateTime, DateTime) getLast7Days() {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 7));
    return (startOfDay(start), endOfDay(end));
  }

  /// Gets date range for "Last 30 days"
  static (DateTime, DateTime) getLast30Days() {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 30));
    return (startOfDay(start), endOfDay(end));
  }

  /// Gets date range for "This month"
  static (DateTime, DateTime) getThisMonth() {
    final now = DateTime.now();
    return (startOfMonth(now), endOfMonth(now));
  }

  /// Gets date range for "Last month"
  static (DateTime, DateTime) getLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    return (startOfMonth(lastMonth), endOfMonth(lastMonth));
  }

  /// Gets date range for "This year"
  static (DateTime, DateTime) getThisYear() {
    final now = DateTime.now();
    return (startOfYear(now), endOfYear(now));
  }

  // ==================== PARSING ====================
  
  /// Safely parses ISO 8601 string to DateTime
  static DateTime? parseIso8601(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }
    
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parses timestamp (milliseconds since epoch) to DateTime
  static DateTime? parseTimestamp(int? timestamp) {
    if (timestamp == null) {
      return null;
    }
    
    try {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }

  // ==================== TIMESTAMPS ====================
  
  /// Gets current timestamp in milliseconds
  static int nowTimestamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Converts DateTime to timestamp
  static int toTimestamp(DateTime date) {
    return date.millisecondsSinceEpoch;
  }

  // ==================== DISPLAY HELPERS ====================
  
  /// Gets greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Gets time period label
  static String getTimePeriod(DateTime date) {
    final hour = date.hour;
    
    if (hour < 6) {
      return 'Night';
    } else if (hour < 12) {
      return 'Morning';
    } else if (hour < 17) {
      return 'Afternoon';
    } else if (hour < 21) {
      return 'Evening';
    } else {
      return 'Night';
    }
  }
}
