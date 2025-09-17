import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

Uri api(String path) => Uri.parse('$baseUrl$path');

class ApiClient {
  Future<List<dynamic>> getReports() async {
    final res = await http.get(api('/api/reports'));
    if (res.statusCode != 200) {
      throw Exception('GET /api/reports gagal: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as List;
  }

  Future<Map<String, dynamic>> createReport({
    required String judul,
    required String deskripsi,
    double? lat,
    double? lng,
    String? lokasiText,
    String? imagePath, // path file lokal dari ImagePicker
  }) async {
    final req = http.MultipartRequest('POST', api('/api/reports'));
    req.fields.addAll({
      'judul': judul,
      'deskripsi': deskripsi,
      if (lat != null) 'lat': '$lat',
      if (lng != null) 'lng': '$lng',
      if (lokasiText != null) 'lokasi_text': lokasiText,
    });
    if (imagePath != null) {
      req.files.add(await http.MultipartFile.fromPath('foto', imagePath));
    }
    final sent = await req.send();
    final res = await http.Response.fromStream(sent);
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('POST /api/reports gagal: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
