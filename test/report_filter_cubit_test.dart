import 'package:flutter_test/flutter_test.dart';
import 'package:incident_report/cubit/report_filter_cubit.dart';
import 'package:incident_report/models/report.dart';

Report report(
  String title,
  ReportStatus status,
  ReportCategory category, {
  String location = 'Block B',
}) => Report(
  id: title,
  title: title,
  category: category,
  location: location,
  description: 'details',
  status: status,
  history: const [],
  reporterId: 'u1',
  reporterName: 'Amina',
  createdAt: DateTime(2026),
);

void main() {
  final reports = [
    report(
      'Water shortage',
      ReportStatus.submitted,
      ReportCategory.water,
      location: 'Student Residence',
    ),
    report(
      'Broken projector',
      ReportStatus.inProgress,
      ReportCategory.facilities,
    ),
    report(
      'Overflowing bin',
      ReportStatus.resolved,
      ReportCategory.sanitation,
      location: 'Cafeteria',
    ),
  ];
  List<String> titles(ReportFilterCubit c) =>
      c.state.apply(reports).map((r) => r.title).toList();

  test('no filter returns everything', () {
    expect(titles(ReportFilterCubit()), hasLength(3));
  });

  test(
    'filters by status, category and case-insensitive search, and combines them',
    () {
      final cubit = ReportFilterCubit()..setStatus(ReportStatus.inProgress);
      expect(titles(cubit), ['Broken projector']);

      cubit
        ..setStatus(null)
        ..setCategory(ReportCategory.sanitation);
      expect(titles(cubit), ['Overflowing bin']);

      cubit
        ..setCategory(null)
        ..setQuery('  RESIDENCE ');
      expect(titles(cubit), ['Water shortage']);

      cubit.setStatus(ReportStatus.resolved);
      expect(titles(cubit), isEmpty);
    },
  );
}
