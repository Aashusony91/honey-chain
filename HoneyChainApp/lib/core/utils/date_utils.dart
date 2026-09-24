const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatDisplayDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${_months[date.month - 1]} ${date.year}';
}
