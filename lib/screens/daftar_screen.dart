import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';

class DaftarScreen extends StatefulWidget {
  final String email;
  const DaftarScreen({super.key, required this.email});

  @override
  State<DaftarScreen> createState() => _DaftarScreenState();
}

class _DaftarScreenState extends State<DaftarScreen> {
  final _namaCtrl = TextEditingController();
  final _sekolahCtrl = TextEditingController();
  DateTime? _mulai;
  DateTime? _akhir;
  bool _loading = false;

  Future<void> _pickDate(bool isMulai) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _mulai = picked;
        } else {
          _akhir = picked;
        }
      });
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    final nama = _namaCtrl.text.trim();
    final sekolah = _sekolahCtrl.text.trim();

    if (nama.isEmpty || sekolah.isEmpty || _mulai == null || _akhir == null) {
      _toast('Semua field wajib diisi');
      return;
    }
    if (_akhir!.isBefore(_mulai!)) {
      _toast('Tanggal akhir tidak boleh sebelum tanggal mulai');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await ApiService.daftarUser(
        email: widget.email,
        nama: nama,
        sekolah: sekolah,
        mulai: _fmt(_mulai),
        akhir: _fmt(_akhir),
      );

      if (res['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('absensi_email', widget.email);

        final loginRes = await ApiService.loginUser(widget.email);
        if (!mounted) return;

        final user = UserModel.fromJson(loginRes);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
        );
      } else {
        _toast(res['message'] ?? 'Pendaftaran gagal');
      }
    } catch (e) {
      _toast('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _sekolahCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pendaftaran Peserta'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: TextEditingController(text: widget.email),
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _namaCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                hintText: 'Masukkan nama lengkap',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sekolahCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Sekolah',
                hintText: 'Masukkan nama sekolah',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanggal Mulai'),
              subtitle: Text(_mulai == null ? 'Pilih tanggal' : _fmt(_mulai)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanggal Akhir'),
              subtitle: Text(_akhir == null ? 'Pilih tanggal' : _fmt(_akhir)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(false),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Daftar Sekarang'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
