String formatRelativeTime(dynamic value, {DateTime? now}) {
  if (value == null) return '';

  final date = value is DateTime ? value : DateTime.tryParse(value.toString());
  if (date == null) return '';

  final difference = (now ?? DateTime.now()).difference(date);
  if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
  if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
  return 'Hace ${difference.inDays} días';
}
