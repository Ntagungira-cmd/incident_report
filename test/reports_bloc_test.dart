import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incident_report/bloc/reports_bloc.dart';
import 'package:incident_report/data/report_repository.dart';
import 'package:incident_report/models/app_user.dart';
import 'package:incident_report/models/report.dart';

class FakeReportRepository implements ReportRepository {
  final reports = StreamController<List<Report>>();
  Object? updateError;
  final updates = <(String, ReportStatus)>[];
  final assignees = <(String, String)>[];

  @override
  Stream<List<Report>> watch(AppUser user) => reports.stream;

  @override
  Future<void> updateStatus(Report report, ReportStatus status) async {
    if (updateError != null) throw updateError!;
    updates.add((report.id, status));
  }

  @override
  Future<void> setAssignee(Report report, AppUser assignee) async {
    if (updateError != null) throw updateError!;
    assignees.add((report.id, assignee.uid));
  }

  @override
  Future<void> submit({
    required AppUser user,
    required String title,
    required ReportCategory category,
    required String location,
    required String description,
    Uint8List? photo,
  }) async {}
}

Report report(String id, ReportStatus status) => Report(
  id: id,
  title: 'Report $id',
  category: ReportCategory.water,
  location: 'Block B',
  description: 'No water since morning',
  status: status,
  history: [StatusChange(ReportStatus.submitted, DateTime(2026, 10, 15))],
  reporterId: 'u1',
  reporterName: 'Amina Hassan',
  createdAt: DateTime(2026, 10, 15),
);

const staff = AppUser(
  uid: 'staff1',
  name: 'Jean Habimana',
  email: 'j@b.c',
  department: 'Facilities',
  location: 'Kigali',
  role: UserRole.staff,
);

const user = AppUser(
  uid: 'u1',
  name: 'Amina Hassan',
  email: 'a@b.c',
  department: 'CS',
  location: 'Kigali',
);

void main() {
  late FakeReportRepository repo;
  setUp(() => repo = FakeReportRepository());

  blocTest<ReportsBloc, ReportsState>(
    'emits reports streamed from the repository',
    build: () => ReportsBloc(repo),
    act: (bloc) {
      bloc.add(const ReportsSubscribed(user));
      repo.reports.add([
        report('1', ReportStatus.submitted),
        report('2', ReportStatus.resolved),
      ]);
    },
    expect: () => [
      isA<ReportsState>()
          .having((s) => s.status, 'status', ReportsStatus.ready)
          .having((s) => s.reports.length, 'count', 2),
    ],
  );

  blocTest<ReportsBloc, ReportsState>(
    'emits failure when the stream errors',
    build: () => ReportsBloc(repo),
    act: (bloc) {
      bloc.add(const ReportsSubscribed(user));
      repo.reports.addError('permission-denied');
    },
    expect: () => [
      isA<ReportsState>()
          .having((s) => s.status, 'status', ReportsStatus.failure)
          .having((s) => s.error, 'error', 'permission-denied'),
    ],
  );

  blocTest<ReportsBloc, ReportsState>(
    'forwards status updates to the repository',
    build: () => ReportsBloc(repo),
    act: (bloc) => bloc.add(
      StatusUpdateRequested(
        report('1', ReportStatus.submitted),
        ReportStatus.inProgress,
      ),
    ),
    expect: () => <ReportsState>[],
    verify: (_) => expect(repo.updates, [('1', ReportStatus.inProgress)]),
  );

  blocTest<ReportsBloc, ReportsState>(
    'forwards assignee updates to the repository',
    build: () => ReportsBloc(repo),
    act: (bloc) =>
        bloc.add(AssigneeSet(report('1', ReportStatus.submitted), staff)),
    expect: () => <ReportsState>[],
    verify: (_) => expect(repo.assignees, [('1', 'staff1')]),
  );

  blocTest<ReportsBloc, ReportsState>(
    'surfaces status update errors',
    build: () => ReportsBloc(repo..updateError = 'denied'),
    act: (bloc) => bloc.add(
      StatusUpdateRequested(
        report('1', ReportStatus.submitted),
        ReportStatus.resolved,
      ),
    ),
    expect: () => [
      isA<ReportsState>().having((s) => s.error, 'error', 'denied'),
    ],
  );

  test('counts and lookup by id', () {
    final state = ReportsState(
      status: ReportsStatus.ready,
      reports: [
        report('1', ReportStatus.submitted),
        report('2', ReportStatus.inProgress),
        report('3', ReportStatus.inProgress),
      ],
    );
    expect(state.count(ReportStatus.inProgress), 2);
    expect(state.count(ReportStatus.resolved), 0);
    expect(state.byId('3')?.status, ReportStatus.inProgress);
    expect(state.byId('missing'), isNull);
  });
}
