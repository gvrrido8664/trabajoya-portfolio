import 'package:flutter/material.dart';
import 'package:trabajoya_app/shared/widgets/ticket_card.dart';

class TicketDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double? minWidth;
  final Widget? emptyState;

  const TicketDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty && emptyState != null) {
      return TicketCard(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: emptyState!,
        ),
      );
    }

    final table = DataTable(
      headingTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontFamily: 'IBMPlexMono',
        fontWeight: FontWeight.w600,
        letterSpacing: 1.54,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      headingRowColor: WidgetStateProperty.all(
        Theme.of(context).colorScheme.surface,
      ),
      dataTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      dividerThickness: 1,
      columns: columns,
      rows: rows,
    );

    return TicketCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minWidth ?? constraints.maxWidth,
              ),
              child: table,
            ),
          );
        },
      ),
    );
  }
}
