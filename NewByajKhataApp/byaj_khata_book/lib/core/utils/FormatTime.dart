String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  // Less than a minute
  if (difference.inMinutes < 1) {
    return "Just now";
  }
  // Less than an hour
  else if (difference.inHours < 1) {
    final minutes = difference.inMinutes;
    return "$minutes ${minutes == 1 ? 'min' : 'min'} ago";
  }
  // Less than a day
  else if (difference.inDays < 1) {
    final hours = difference.inHours;
    return "$hours ${hours == 1 ? 'hr' : 'hrs'} ago";
  }
  // Less than a month
  else if (difference.inDays < 30) {
    final days = difference.inDays;
    return "$days ${days == 1 ? 'day' : 'days'} ago";
  }
  // Months
  else {
    final months = (difference.inDays / 30).floor();
    return "$months ${months == 1 ? 'mo' : 'mos'} ago";
  }
}