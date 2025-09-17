import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// ======================================================
// GANTI IP di bawah ini dengan IP laptop/PC di jaringanmu
// Contoh: http://192.168.0.109:8000
// ======================================================
const String baseUrl = 'http://192.168.0.109:8000';
Uri api(String path) => Uri.parse('$baseUrl$path');
// Bangun URL gambar yang aman dipakai di HP (ganti host 127.0.0.1/localhost → baseUrl)
String? imageUrlFrom(Map<String, dynamic> r) {
  final raw = (r['foto_url'] as String?)?.trim();
  final path = (r['foto_path'] as String?)?.trim();

  if (raw != null && raw.isNotEmpty) {
    try {
      final u = Uri.parse(raw);
      // jika API mengembalikan 127.0.0.1 / localhost, ganti host-nya dengan host dari baseUrl
      if (u.host == '127.0.0.1' || u.host == 'localhost') {
        return '$baseUrl${u.path}';
      }
      return raw; // sudah benar
    } catch (_) {/* ignore parse error */}
  }

  // fallback ke path storage
  if (path != null && path.isNotEmpty) {
    return '$baseUrl/storage/$path';
  }
  return null;
}


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EcoRangersApp());
}

/// ======= Client API sederhana
class ApiClient {
  Future<List<dynamic>> getReports() async {
    final res = await http.get(
      api('/api/reports'),
      headers: {'Accept': 'application/json'},
    );
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
    String? imagePath, // path file lokal (Android)
  }) async {
    final req = http.MultipartRequest('POST', api('/api/reports'))
      ..headers['Accept'] = 'application/json'
      ..fields.addAll({
        'judul': judul,
        'deskripsi': deskripsi,
        if (lat != null) 'lat': '$lat',
        if (lng != null) 'lng': '$lng',
        if (lokasiText != null) 'lokasi_text': lokasiText,
      });

    if (imagePath != null && imagePath.isNotEmpty) {
      req.files.add(await http.MultipartFile.fromPath('foto', imagePath));
    }

    final sent = await req.send();
    final res = await http.Response.fromStream(sent);

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('POST /api/reports gagal: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ===== Perbaikan baru untuk Admin =====

  /// Ambil list laporan dan langsung dipetakan ke model [Laporan]
  Future<List<Laporan>> fetchReportsAsModel() async {
    final list = await getReports();
    return list.map<Laporan>((e) {
      final m = e as Map<String, dynamic>;
      return Laporan(
        id: m['id'] as int,
        judul: m['judul'] as String? ?? '-',
        deskripsi: m['deskripsi'] as String? ?? '-',
        lokasi: (m['lokasi_text'] as String?) ??
            ((m['lat'] != null && m['lng'] != null)
                ? '${m['lat']}, ${m['lng']}'
                : '-'),
        fotoPath: m['foto_path'] as String? ?? '',
        fotoUrl: imageUrlFrom(m),                          // <— ini yang baru
        status: m['status'] as String? ?? 'Pending',
        tanggal: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }


  /// Ubah status laporan (Pending/Diproses/Selesai)
  Future<Map<String, dynamic>> updateStatus(int id, String status) async {
    final res = await http.patch(
      api('/api/reports/$id/status'),
      headers: {'Accept': 'application/json'},
      body: {'status': status},
    );
    if (res.statusCode != 200) {
      throw Exception('PATCH status gagal: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Hapus laporan
  Future<void> deleteReport(int id) async {
    final res = await http.delete(api('/api/reports/$id'));
    if (res.statusCode != 200) {
      throw Exception('DELETE gagal: ${res.statusCode} ${res.body}');
    }
  }
}

// ==================== MODEL ====================
class Laporan {
  int id;
  String judul;
  String deskripsi;
  String lokasi;
  String fotoPath;
  String? fotoUrl;
  String status;
  DateTime tanggal;

  Laporan({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.lokasi,
    required this.fotoPath,
    this.fotoUrl,
    required this.status,
    required this.tanggal,
  });
}

// ==================== APP ====================
class EcoRangersApp extends StatelessWidget {
  const EcoRangersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco Rangers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ==================== SPLASH ====================
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.lightGreen],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "Eco Rangers",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Selamat Datang di Eco Rangers!",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginSelectionPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text("Mulai"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== LOGIN SELECTION ====================
class LoginSelectionPage extends StatelessWidget {
  const LoginSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Login"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserLoginPage()),
                );
              },
              child: const Text(
                "Login User / Pelapor",
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                );
              },
              child: const Text("Login Admin", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== USER LOGIN ====================
class UserLoginPage extends StatefulWidget {
  const UserLoginPage({super.key});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final usernameController = TextEditingController();

  void _login() {
    if (usernameController.text.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardUserPage()),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Masukkan username")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco, size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    "Eco Rangers",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: "Username",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _login,
                      child: const Text(
                        "Login",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== ADMIN LOGIN ====================
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String _error = '';

  void _login() {
    if (usernameController.text == 'admin' &&
        passwordController.text == 'admin123') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardAdminPage()),
      );
    } else {
      setState(() {
        _error = 'Username atau password salah';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: SizedBox(
          width: 350,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Login Admin',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: _login, child: const Text('Login')),
                  const SizedBox(height: 12),
                  Text(_error, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== DASHBOARD USER ====================
class DashboardUserPage extends StatelessWidget {
  const DashboardUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard User"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _menuCard(Icons.cloud_download, "Cek Laporan (API)", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApiReportsPage()),
              );
            }),
            _menuCard(Icons.report_problem, "Buat Laporan", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BuatLaporanPage()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.green),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== CEK LAPORAN (API) ====================
class ApiReportsPage extends StatelessWidget {
  const ApiReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan (API)'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: apiClient.getReports(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final data = snap.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('Belum ada laporan'));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, i) {
              final r = data[i] as Map<String, dynamic>;
              final imgUrl = imageUrlFrom(r);
              final deskripsi = (r['deskripsi'] as String?) ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  isThreeLine: true,
                  leading: imgUrl != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      imgUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  )
                      : const Icon(Icons.image_not_supported, color: Colors.grey),
                  title: Text(r['judul']?.toString() ?? '-'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (deskripsi.isNotEmpty)
                        Text(
                          deskripsi,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text('Status: ${r['status'] ?? '-'}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


// ==================== BUAT LAPORAN ====================
class BuatLaporanPage extends StatefulWidget {
  const BuatLaporanPage({super.key});

  @override
  State<BuatLaporanPage> createState() => _BuatLaporanPageState();
}

class _BuatLaporanPageState extends State<BuatLaporanPage> {
  final TextEditingController deskripsiController = TextEditingController();
  File? _image;
  String? _lokasi; // "lat, lng"

  Future<void> _ambilFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? xfile = await picker.pickImage(
      source: ImageSource.camera, // WAJIB pakai named parameter
      maxWidth: 1600, // opsional, batasi resolusi
      imageQuality: 85, // opsional, kompresi 0-100
    );

    if (xfile != null) {
      setState(() {
        _image = File(xfile.path);
      });
    }
  }

  Future<void> _ambilLokasi() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Lokasi tidak aktif")));
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _lokasi = "${pos.latitude}, ${pos.longitude}";
    });
  }

  Future<void> _kirimLaporan() async {
    if (deskripsiController.text.isEmpty || _image == null || _lokasi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi semua data terlebih dahulu")),
      );
      return;
    }

    try {
      double? lat;
      double? lng;
      if (_lokasi != null && _lokasi!.contains(',')) {
        final parts = _lokasi!.split(',');
        lat = double.tryParse(parts[0].trim());
        lng = double.tryParse(parts[1].trim());
      }

      await ApiClient().createReport(
        judul: 'Laporan dari Aplikasi',
        deskripsi: deskripsiController.text,
        lokasiText: _lokasi,
        lat: lat,
        lng: lng,
        imagePath: _image!.path,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Laporan berhasil dikirim!")),
      );
      deskripsiController.clear();
      setState(() {
        _image = null;
        _lokasi = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal kirim: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Laporan"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: deskripsiController,
              decoration: const InputDecoration(
                labelText: "Deskripsi",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _image != null
                ? Image.file(_image!, height: 150)
                : const Text("Belum ada foto"),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _ambilFoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Ambil Foto"),
            ),
            const SizedBox(height: 16),
            _lokasi != null
                ? Text("Lokasi: $_lokasi")
                : const Text("Belum ada lokasi"),
            ElevatedButton.icon(
              onPressed: _ambilLokasi,
              icon: const Icon(Icons.location_on),
              label: const Text("Ambil Lokasi"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _kirimLaporan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("Kirim Laporan"),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DASHBOARD ADMIN ====================
class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  List<Laporan> laporanList = [];
  final _api = ApiClient();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchReportsAsModel();
      setState(() {
        laporanList = data;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _updateLaporan(Laporan laporan, String status) {
    setState(() {
      laporan.status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDesktop ? 'Dashboard Admin (Desktop)' : 'Dashboard Admin (Mobile)',
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      )
          : (isDesktop
          ? SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor:
          WidgetStateProperty.all(Colors.green[100]),
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Judul')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Tanggal')),
            DataColumn(label: Text('Action')),
          ],
          rows: laporanList.map((laporan) {
            return DataRow(
              cells: [
                DataCell(Text(laporan.id.toString())),
                DataCell(Text(laporan.judul)),
                DataCell(Text(laporan.status)),
                DataCell(Text(
                    '${laporan.tanggal.day}/${laporan.tanggal.month}/${laporan.tanggal.year}')),
                DataCell(
                  Row(
                    children: [
                      ElevatedButton(
                        child: const Text('Detail'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailLaporanAdminPage(
                                    laporan: laporan,
                                    onUpdate: _updateLaporan,
                                  ),
                            ),
                          ).then((_) => _load());
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title:
                              const Text('Hapus laporan?'),
                              content: Text(laporan.judul),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(
                                          context, false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(
                                          context, true),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            try {
                              await _api
                                  .deleteReport(laporan.id);
                              _load();
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                  content: Text(
                                      'Gagal hapus: $e')));
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      )
          : ListView.builder(
        itemCount: laporanList.length,
        itemBuilder: (_, index) {
          final laporan = laporanList[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(laporan.judul),
              subtitle: Text('Status: ${laporan.status}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailLaporanAdminPage(
                            laporan: laporan,
                            onUpdate: _updateLaporan,
                          ),
                        ),
                      ).then((_) => _load());
                    },
                    child: const Text('Detail'),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        color: Colors.red),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Hapus laporan?'),
                          content: Text(laporan.judul),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        try {
                          await _api.deleteReport(laporan.id);
                          _load();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                              content:
                              Text('Gagal hapus: $e')));
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      )),
    );
  }
}

// ==================== DETAIL LAPORAN ADMIN ====================
// ==================== DETAIL LAPORAN ADMIN ====================
class DetailLaporanAdminPage extends StatefulWidget {
  final Laporan laporan;
  final Function(Laporan, String) onUpdate;
  const DetailLaporanAdminPage({
    super.key,
    required this.laporan,
    required this.onUpdate,
  });

  @override
  State<DetailLaporanAdminPage> createState() => _DetailLaporanAdminPageState();
}

class _DetailLaporanAdminPageState extends State<DetailLaporanAdminPage> {
  late String _status;
  final _api = ApiClient();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.laporan.status;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.updateStatus(widget.laporan.id, _status);
      widget.onUpdate(widget.laporan, _status);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal update: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // HITUNG URL GAMBAR DI SINI (BUKAN DI DALAM children)
    final String? imgUrl = widget.laporan.fotoUrl ??
        (widget.laporan.fotoPath.isNotEmpty
            ? '$baseUrl/storage/${widget.laporan.fotoPath}'
            : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan Admin'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Judul: ${widget.laporan.judul}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Deskripsi: ${widget.laporan.deskripsi}'),
            const SizedBox(height: 8),
            Text('Lokasi: ${widget.laporan.lokasi}'),
            const SizedBox(height: 8),

            // TAMPILKAN GAMBAR DARI SERVER
            if (imgUrl != null)
              Image.network(
                imgUrl,
                width: 300,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, color: Colors.grey),
              ),

            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _status,
              items: ['Pending', 'Diproses', 'Selesai']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => _status = val!),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Update Status'),
            ),
          ],
        ),
      ),
    );
  }
}

