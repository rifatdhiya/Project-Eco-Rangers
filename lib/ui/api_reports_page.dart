import 'package:flutter/material.dart';
import '../services/api_client.dart';

class ApiReportsPage extends StatelessWidget {
  const ApiReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient();
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan (API)'), backgroundColor: Colors.green),
      body: FutureBuilder<List<dynamic>>(
        future: api.getReports(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final data = snap.data ?? [];
          if (data.isEmpty) return const Center(child: Text('Belum ada laporan'));
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, i) {
              final r = data[i] as Map<String, dynamic>;
              return ListTile(
                title: Text(r['judul'] ?? '-'),
                subtitle: Text('Status: ${r['status']}'),
                onTap: () {
                  final foto = r['foto_path'] as String?;
                  if (foto != null && foto.isNotEmpty) {
                    final url = '$baseUrl/storage/$foto';
                    // buka gambar di browser
                    // (atau pakai Image.network di detail page)
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
