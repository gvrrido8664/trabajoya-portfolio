import 'package:flutter_test/flutter_test.dart';
import 'package:trabajoya_app/core/utils/relative_time.dart';

void main() {
  test('formats relative minutes, hours and days', () {
    final now = DateTime.utc(2026, 8, 5, 12);

    expect(
      formatRelativeTime(now.subtract(const Duration(minutes: 12)), now: now),
      'Hace 12 min',
    );
    expect(
      formatRelativeTime(now.subtract(const Duration(hours: 3)), now: now),
      'Hace 3 h',
    );
    expect(
      formatRelativeTime(now.subtract(const Duration(days: 2)), now: now),
      'Hace 2 días',
    );
    expect(formatRelativeTime('invalid', now: now), isEmpty);
  });
}
