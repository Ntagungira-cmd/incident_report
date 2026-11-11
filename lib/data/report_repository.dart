import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/app_user.dart';
import '../models/report.dart';

class ReportRepository {
  ReportRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  /// Staff see every report, students only their own. Newest first.
  Stream<List<Report>> watch(AppUser user) {
    Query<Map<String, dynamic>> query = _reports;
    if (!user.isStaff) query = query.where('reporterId', isEqualTo: user.uid);
    // Sorted client-side so the student query needs no composite index.
    return query.snapshots().map(
      (snap) =>
          snap.docs.map(Report.fromDoc).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  Future<void> submit({
    required AppUser user,
    required String title,
    required ReportCategory category,
    required String location,
    required String description,
    Uint8List? photo,
  }) async {
    final doc = _reports.doc();
    final photoUrl = photo == null
        ? null
        : await uploadReportPhoto(photo, doc.id);
    final now = DateTime.now();
    final report = Report(
      id: doc.id,
      title: title,
      category: category,
      location: location,
      description: description,
      photoUrl: photoUrl,
      status: ReportStatus.submitted,
      history: [StatusChange(ReportStatus.submitted, now)],
      reporterId: user.uid,
      reporterName: user.name,
      createdAt: now,
    );
    await doc.set(report.toMap());
  }

  Future<void> updateStatus(Report report, ReportStatus status) =>
      _reports.doc(report.id).update({
        'status': status.name,
        'statusHistory': FieldValue.arrayUnion([
          StatusChange(status, DateTime.now()).toMap(),
        ]),
      });

  /// Take or hand an unclaimed report to [assignee]. Starting work moves it
  /// to in progress.
  Future<void> setAssignee(Report report, AppUser assignee) {
    final data = <String, dynamic>{
      'assigneeId': assignee.uid,
      'assigneeName': assignee.name,
    };
    if (report.status == ReportStatus.submitted) {
      data['status'] = ReportStatus.inProgress.name;
      data['statusHistory'] = FieldValue.arrayUnion([
        StatusChange(ReportStatus.inProgress, DateTime.now()).toMap(),
      ]);
    }
    return _reports.doc(report.id).update(data);
  }
}

/// Unsigned upload. The API secret stays out of the app.
/// Run with `--dart-define=CLOUDINARY_CLOUD_NAME=...` and
/// `--dart-define=CLOUDINARY_UPLOAD_PRESET=...` (preset folder: reports).
Future<String> uploadReportPhoto(
  Uint8List bytes,
  String reportId, {
  http.Client? client,
  String cloudName = const String.fromEnvironment('CLOUDINARY_CLOUD_NAME'),
  String uploadPreset = const String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  ),
}) async {
  if (cloudName.isEmpty || uploadPreset.isEmpty) {
    throw StateError(
      'Set CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET with --dart-define.',
    );
  }
  final httpClient = client ?? http.Client();
  try {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(
              'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
            ),
          )
          ..fields['upload_preset'] = uploadPreset
          ..fields['folder'] = 'reports'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: '$reportId.jpg',
            ),
          );
    final response = await httpClient.send(request);
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw StateError('Photo upload failed (${response.statusCode}): $body');
    }
    final data = jsonDecode(body);
    final url = data is Map ? data['secure_url'] : null;
    if (url is! String || url.isEmpty) {
      throw StateError('Photo upload did not return a URL');
    }
    return url;
  } finally {
    if (client == null) httpClient.close();
  }
}
