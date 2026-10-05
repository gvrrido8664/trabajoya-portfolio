import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:trabajoya_app/utils/colors.dart';

Future<void> exportCsv(
  BuildContext context,
  String fileName,
  List<String> headers,
  List<List<String>> rows,
) async {
  final buffer = StringBuffer();
  buffer.writeln(headers.map((h) => _escapeCsv(h)).join(','));
  for (final row in rows) {
    buffer.writeln(row.map((c) => _escapeCsv(c)).join(','));
  }

  await Clipboard.setData(ClipboardData(text: buffer.toString()));

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fileName copiado al portapapeles'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

String _escapeCsv(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
