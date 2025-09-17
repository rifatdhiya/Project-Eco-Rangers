// lib/services/report_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ReportApi {
  static Future<List<Map<String, dynamic>>> fetchReports() async {
    final res = await http.get(api('/api/reports'));
    if (res.statusCode != 200) {
      throw Exception('Gagal load: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body);
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
