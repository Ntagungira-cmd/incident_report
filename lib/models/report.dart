import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ReportStatus {
  submitted('Submitted', Color(0xFFE59400), Icons.error_outline),
  inProgress('In Progress', Color(0xFF6D4AFF), Icons.schedule),
  resolved('Resolved', Color(0xFF1E9E5A), Icons.check_circle_outline);

  const ReportStatus(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

enum ReportCategory {
  facilities('Broken facilities', Icons.build_outlined),
  water('Water shortage', Icons.water_drop_outlined),
  electricity('Electricity outage', Icons.bolt_outlined),
  furniture('Damaged furniture', Icons.chair_outlined),
  sanitation('Sanitation', Icons.cleaning_services_outlined),
  safety('Safety concern', Icons.health_and_safety_outlined);

  const ReportCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

class StatusChange {
  const StatusChange(this.status, this.at);
  final ReportStatus status;
  final DateTime at;

  Map<String, dynamic> toMap() => {
    'status': status.name,
    'at': Timestamp.fromDate(at),
  };
}

class Report {
  const Report({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.description,
    required this.status,
    required this.history,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    this.photoUrl,
    this.assigneeId,
    this.assigneeName,
  });

  final String id;
  final String title;
  final ReportCategory category;
  final String location;
  final String description;
  final String? photoUrl;
  final ReportStatus status;
  final List<StatusChange> history;
  final String reporterId;
  final String reporterName;
  final DateTime createdAt;
  final String? assigneeId;
  final String? assigneeName;

  /// Name of the person working on it, or "Unassigned" once work has started.
  String? get assigneeLabel {
    final name = assigneeName;
    if (name != null && name.isNotEmpty) return name;
    if (status == ReportStatus.inProgress) return 'Unassigned';
    return null;
  }

  factory Report.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Report(
      id: doc.id,
      title: d['title'] as String,
      category: ReportCategory.values.byName(d['category'] as String),
      location: d['location'] as String,
      description: d['description'] as String,
      photoUrl: d['photoUrl'] as String?,
      status: ReportStatus.values.byName(d['status'] as String),
      history: [
        for (final h in d['statusHistory'] as List? ?? const [])
          StatusChange(
            ReportStatus.values.byName(h['status'] as String),
            (h['at'] as Timestamp).toDate(),
          ),
      ],
      reporterId: d['reporterId'] as String,
      reporterName: d['reporterName'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      assigneeId: d['assigneeId'] as String?,
      assigneeName: d['assigneeName'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'category': category.name,
    'location': location,
    'description': description,
    'photoUrl': photoUrl,
    'status': status.name,
    'statusHistory': [for (final h in history) h.toMap()],
    'reporterId': reporterId,
    'reporterName': reporterName,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
