import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incident_report/bloc/auth_bloc.dart';
import 'package:incident_report/bloc/reports_bloc.dart';
import 'package:incident_report/cubit/nav_cubit.dart';
import 'package:incident_report/cubit/report_form_cubit.dart';
import 'package:incident_report/data/auth_repository.dart';
import 'package:incident_report/data/report_repository.dart';
import 'package:incident_report/models/app_user.dart';
import 'package:incident_report/models/report.dart';
import 'package:incident_report/ui/pages/app_shell.dart';
import 'package:incident_report/ui/pages/incident_details_page.dart';
import 'package:incident_report/ui/pages/login_page.dart';
import 'package:incident_report/ui/pages/report_form_page.dart';
import 'package:incident_report/ui/theme.dart';

class _Auth implements AuthRepository {
  @override
  Stream<AppUser?> userChanges() => const Stream.empty();

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String department,
    required String location,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<List<AppUser>> listStaff() async => const [];

  @override
  Future<AppUser> updateProfile({
    required AppUser user,
    required String name,
    required String department,
    required String location,
    Uint8List? photo,
  }) async => user;
}

class _Reports implements ReportRepository {
  _Reports(this.items);

  final List<Report> items;

  @override
  Stream<List<Report>> watch(AppUser user) => Stream.value(items);

  @override
  Future<void> submit({
    required AppUser user,
    required String title,
    required ReportCategory category,
    required String location,
    required String description,
    Uint8List? photo,
  }) async {}

  @override
  Future<void> updateStatus(Report report, ReportStatus status) async {}

  @override
  Future<void> setAssignee(Report report, AppUser assignee) async {}
}

Report _report(
  String id,
  String title,
  ReportCategory category,
  String location,
  ReportStatus status, {
  String? assigneeName,
}) => Report(
  id: id,
  title: title,
  category: category,
  location: location,
  description:
      'Taps in the second-floor bathrooms have been dry since morning.',
  status: status,
  history: [
    StatusChange(ReportStatus.submitted, DateTime(2026, 11, 10, 8, 30)),
    if (status != ReportStatus.submitted)
      StatusChange(status, DateTime(2026, 11, 7, 11)),
  ],
  reporterId: 'student',
  reporterName: 'Amina Hassan',
  createdAt: DateTime(2026, 11, 10, 8, 30),
  assigneeName: assigneeName,
  assigneeId: assigneeName == null ? null : 'staff',
);

final _reports = [
  _report(
    'seed-1',
    'No water in Block B',
    ReportCategory.water,
    'Block B, Room 204',
    ReportStatus.submitted,
  ),
  _report(
    'seed-2',
    'Power outage in the library',
    ReportCategory.electricity,
    'Main library, 1st floor',
    ReportStatus.submitted,
  ),
  _report(
    'seed-3',
    'Broken window in Lab 2',
    ReportCategory.facilities,
    'Science block, Lab 2',
    ReportStatus.inProgress,
    assigneeName: 'Jean Habimana',
  ),
  _report(
    'seed-5',
    'Blocked toilets in Hostel A',
    ReportCategory.sanitation,
    'Hostel A, ground floor',
    ReportStatus.resolved,
    assigneeName: 'Jean Habimana',
  ),
];

const _student = AppUser(
  uid: 'student',
  name: 'Amina Hassan',
  email: 'amina.hassan@campus.edu',
  department: 'Computer Science',
  location: 'Kigali Campus',
);

const _admin = AppUser(
  uid: 'admin',
  name: 'Campus Admin',
  email: 'admin@campus.edu',
  department: 'Facilities',
  location: 'Kigali Campus',
  role: UserRole.admin,
);

Future<void> _loadFonts() async {
  const dir =
      '/Users/ntagungiraalirashid/flutter/bin/cache/artifacts/material_fonts';
  Future<ByteData> bytes(String name) async =>
      ByteData.sublistView(File('$dir/$name').readAsBytesSync());
  await (FontLoader('MaterialIcons')
        ..addFont(bytes('MaterialIcons-Regular.otf')))
      .load();
  await (FontLoader('Roboto')
        ..addFont(bytes('Roboto-Regular.ttf'))
        ..addFont(bytes('Roboto-Medium.ttf'))
        ..addFont(bytes('Roboto-Bold.ttf')))
      .load();
}

Widget _frame(Widget home) =>
    MaterialApp(debugShowCheckedModeBanner: false, theme: appTheme, home: home);

void _phone(WidgetTester tester) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(780, 1688);
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('doc_shots/$name.png'),
  );
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('login', (tester) async {
    _phone(tester);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _frame(
        RepositoryProvider<AuthRepository>(
          create: (_) => _Auth(),
          child: BlocProvider(
            create: (c) => AuthBloc(c.read<AuthRepository>()),
            child: const LoginPage(),
          ),
        ),
      ),
    );
    await _shot(tester, 'login');
  });

  testWidgets('home', (tester) async {
    _phone(tester);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _frame(
        RepositoryProvider<ReportRepository>(
          create: (_) => _Reports(_reports),
          child: AppShell(user: _student),
        ),
      ),
    );
    await _shot(tester, 'home');
  });

  testWidgets('reports', (tester) async {
    _phone(tester);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _frame(
        RepositoryProvider<ReportRepository>(
          create: (_) => _Reports(_reports),
          child: AppShell(user: _admin),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.element(find.text('Reports')).read<NavCubit>().select(1);
    await _shot(tester, 'reports');
  });

  testWidgets('details', (tester) async {
    _phone(tester);
    addTearDown(tester.view.reset);
    final repo = _Reports(_reports);
    final bloc = ReportsBloc(repo)..add(const ReportsSubscribed(_admin));
    await tester.pumpWidget(
      _frame(
        RepositoryProvider<AppUser>.value(
          value: _admin,
          child: BlocProvider.value(
            value: bloc,
            child: const IncidentDetailsPage(reportId: 'seed-1'),
          ),
        ),
      ),
    );
    await _shot(tester, 'details');
  });

  testWidgets('form', (tester) async {
    _phone(tester);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _frame(
        BlocProvider(
          create: (_) => ReportFormCubit(_Reports(const []), _student),
          child: const ReportFormPage(),
        ),
      ),
    );
    await _shot(tester, 'form');
  });
}
