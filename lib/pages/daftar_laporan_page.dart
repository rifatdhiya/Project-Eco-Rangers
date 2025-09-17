// lib/pages/daftar_laporan_page.dart
import 'package:flutter/material.dart';
import '../services/report_api.dart';

class DaftarLaporanPage extends StatefulWidget {
  const DaftarLaporanPage({super.key});

  @override
  State<DaftarLaporanPage> createState() => _DaftarLaporanPageState();
}

class _DaftarLaporanPageState extends State<DaftarLaporanPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = ReportApi.fetchReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Laporan')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Belum ada laporan'));

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = items[i];
              return ListTile(
                title: Text(r['judul'] ?? '(tanpa judul)'),
                subtitle: Text('Status: ${r['status'] ?? '-'}'),
                trailing: Text((r['created_at'] ?? '').toString().split('T').first),
              );
            },
          );
        },
      ),
    );
  }
}
