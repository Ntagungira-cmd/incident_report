import 'package:flutter/material.dart';

import '../../models/report.dart';
import '../format.dart';
import '../pages/incident_details_page.dart';
import 'status_chip.dart';

class ReportThumb extends StatelessWidget {
  const ReportThumb(this.report, {super.key, this.size = 64});

  final Report report;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        report.category.icon,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: report.photoUrl == null
          ? fallback
          : Image.network(
              report.photoUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

class ReportTile extends StatelessWidget {
  const ReportTile(this.report, {super.key});

  final Report report;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => IncidentDetailsPage.open(context, report),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ReportThumb(report),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.location,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo(report.createdAt),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            StatusChip(report.status),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    ),
  );
}
