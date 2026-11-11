import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:incident_report/data/report_repository.dart';

void main() {
  test('upload stores the Cloudinary secure_url', () async {
    const url =
        'https://res.cloudinary.com/demo/image/upload/v1/reports/abc.jpg';
    final client = MockClient((request) async {
      expect(request.url.path, '/v1_1/demo/image/upload');
      expect(request.body, contains('name="upload_preset"'));
      expect(request.body, contains('campus_reports'));
      return http.Response(jsonEncode({'secure_url': url}), 200);
    });

    final saved = await uploadReportPhoto(
      Uint8List.fromList([1, 2, 3]),
      'abc',
      client: client,
      cloudName: 'demo',
      uploadPreset: 'campus_reports',
    );

    expect(saved, url);
  });
}
