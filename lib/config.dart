// lib/config.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

// Kalau pakai HP fisik, ISI IP KOMPUTER kamu di sini, contoh: 'http://192.168.0.107:8000'
// Kalau pakai emulator Android Studio, ubah ke null (biar pakai 10.0.2.2)
const String? FORCE_BASE = 'http://192.168.0.107:8000';

late String baseUrl;

Future<void> ensureBaseUrl() async {
  if (FORCE_BASE != null) {
    baseUrl = FORCE_BASE!;
    return;
  }
  if (kIsWeb) {
    baseUrl = 'http://127.0.0.1:8000';
    return;
  }
  if (Platform.isAndroid) {
    // emulator Android
    baseUrl = 'http://10.0.2.2:8000';
  } else {
    // iOS sim / desktop
    baseUrl = 'http://127.0.0.1:8000';
  }
}

Uri api(String path, [Map<String, dynamic>? query]) {
  final uri = Uri.parse(baseUrl + path);
  return (query == null || query.isEmpty)
      ? uri
      : uri.replace(queryParameters: {
    ...uri.queryParameters,
    ...query.map((k, v) => MapEntry(k, '$v')),
  });
}
