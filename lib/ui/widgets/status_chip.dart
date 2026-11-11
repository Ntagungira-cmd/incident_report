import 'package:flutter/material.dart';

import '../../models/report.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: status.color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      status.label,
      style: TextStyle(
        color: status.color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
