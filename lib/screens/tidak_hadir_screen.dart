import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class TidakHadirScreen extends StatefulWidget {
  final String email;
  final VoidCallback? onSuccess;

  const TidakHadirScreen({
    super.key,
    required this.email,
    this.onSuccess,
  });

  @override
  State<TidakHadirScreen> createState() => _TidakHadirScreenState();
}

class _TidakHadirScreenState extends State<TidakHadirScreen> {
  String? _jenis;
  final _ketCtrl = TextEditingController();
  DateTime _tanggal = DateTime.now();
  String? _fileBase64;
  String? _fileName;
  bool _loading = false;

  final _jenisList = ['Sakit', 'Izin', 'Alpha', 'Lupa'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1200,
    );
    if (x == null) return;

    final bytes = await x.readAsBytes();
    setState(() {
      _fileBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      _fileName = x.name;
    });
  }

  Future<void> _submit() async {
    if (_jenis == null) {
      _toast('Pilih jenis ketidakhadiran');
      return;
    }
    if (_ketCtrl.text.trim().isEmpty) {
      _toast('Isi keterangan');
      return;
    }
    if (_jenis == 'Sakit' && _fileBase64 == null) {
      _toast('Upload surat sakit wajib');
      return;
    }

    setState(() => _loading = true);
    try {
      final tgl = DateFormat('yyyy-MM-dd').format(_tanggal);
      final res = await ApiService.ajukanTidakHadir(
        email: widget.email,
        alasan: _jenis!,
        keterangan: _ketCtrl.text.trim(),
        tanggalTarget: tgl,
        fileBase64: _fileBase64,
        fileName: _fileName,
      );

      if (!mounted) return;
      _toast(res['message'] ?? 'Selesai');

      if (res['success'] == true) {
        widget.onSuccess?.call();
        Navigator.pop(context, true);
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
    _ketCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Tidak Hadir'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tanggal', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(DateFormat('dd/MM/yyyy').format(_tanggal)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _tanggal,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _tanggal = picked);
              },
            ),
            const SizedBox(height: 12),
            const Text('Jenis Ketidakhadiran',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _jenis,
              decoration: const InputDecoration(hintText: '-- Pilih --'),
              items: _jenisList
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _jenis = v),
            ),
            const SizedBox(height: 16),
            const Text('Keterangan',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _ketCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tuliskan alasan...',
              ),
            ),
            if (_jenis == 'Sakit') ...[
              const SizedBox(height: 16),
              const Text('Upload Surat Sakit',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _fileBase64 != null
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: _fileBase64 != null
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.camera_alt, size: 32, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        _fileName ?? 'Ambil foto / pilih dari galeri',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      if (kIsWeb)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            '(Web: pilih file dari komputer)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
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
                    : const Text('Kirim Pengajuan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
