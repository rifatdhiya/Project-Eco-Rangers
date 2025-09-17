// lib/pages/api_reports_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiReportsPage extends StatefulWidget {
  const ApiReportsPage({super.key});
  @override
  State<ApiReportsPage> createState() => _ApiReportsPageState();
}

class _ApiReportsPageState extends State<ApiReportsPage> {
  bool loading = true;
  String? error;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      await ensureBaseUrl();                // penting untuk set baseUrl otomatis
      final uri = api('/api/reports');
      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      items = (jsonDecode(res.body) as List);
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cek Laporan (API)')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text('Gagal memuat: $error'))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final r = items[i];
            final fotoUrl = r['foto_url'] as String?;
            final judul   = (r['judul'] ?? '-') as String;
            final status  = (r['status'] ?? '-') as String;
            final desk    = (r['deskripsi'] ?? '') as String;
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: fotoUrl != null
                    ? Image.network(
                    fotoUrl, width: 56, height: 56, fit: BoxFit.cover)
                    : const Icon(Icons.image_not_supported),
                title: Text(judul),
                subtitle: Text('$status • $desk',
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
