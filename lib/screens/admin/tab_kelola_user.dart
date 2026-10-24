import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class TabKelolaUser extends StatefulWidget {
  final String adminEmail;
  const TabKelolaUser({super.key, required this.adminEmail});

  @override
  State<TabKelolaUser> createState() => _TabKelolaUserState();
}

class _TabKelolaUserState extends State<TabKelolaUser> {
  List<dynamic> list = [];
  List<dynamic> filtered = [];
  bool loading = true;
  final _cariCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.getDaftarUser(widget.adminEmail);
      setState(() {
        list = res;
        filtered = res;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    if (mounted) setState(() => loading = false);
  }

  void _filter(String q) {
    q = q.toLowerCase();
    setState(() {
      filtered = list.where((u) {
        final nama = (u['nama'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final sekolah = (u['sekolah'] ?? '').toString().toLowerCase();
        return nama.contains(q) || email.contains(q) || sekolah.contains(q);
      }).toList();
    });
  }

  Future<void> _hapus(String email, String nama) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text(
          'Yakin hapus "$nama"?\n\nData absensi & pengajuan tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await ApiService.hapusUser(
        emailAdmin: widget.adminEmail,
        emailTarget: email,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Selesai')),
      );
      if (res['success'] == true) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _bukaForm({Map<String, dynamic>? edit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormUserSheet(
        adminEmail: widget.adminEmail,
        edit: edit,
        onSaved: () {
          Navigator.pop(context);
          _load();
        },
      ),
    );
  }

  Color _statusColor(bool aktif, String status) {
    if (aktif) return const Color(0xFF16A34A);
    if (status == 'belum_mulai') return const Color(0xFF2563EB);
    if (status == 'berakhir') return const Color(0xFFDC2626);
    return const Color(0xFFCA8A04);
  }

  String _statusLabel(bool aktif, String status) {
    if (aktif) return 'Aktif';
    if (status == 'belum_mulai') return 'Belum Mulai';
    if (status == 'berakhir') return 'Berakhir';
    return 'Periode Tidak Lengkap';
  }

  @override
  void dispose() {
    _cariCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cariCtrl,
                  onChanged: _filter,
                  decoration: const InputDecoration(
                    hintText: 'Cari nama / email / sekolah...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _bukaForm(),
                icon: const Icon(Icons.person_add, color: Color(0xFF059669)),
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(child: Text('Tidak ada user'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final u = filtered[i];
                          final aktif = u['aktif'] == true;
                          final status = (u['statusPeriode'] ?? '').toString();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              u['nama'] ?? '-',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              u['email'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                            Text(
                                              u['sekolah'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor(aktif, status)
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _statusLabel(aktif, status),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: _statusColor(aktif, status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Periode: ${u['mulai'] ?? '-'} s/d ${u['akhir'] ?? '-'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _bukaForm(edit: u),
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const Text('Edit'),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF7C3AED),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _hapus(
                                          u['email'].toString(),
                                          u['nama']?.toString() ?? '',
                                        ),
                                        icon: const Icon(Icons.delete, size: 18),
                                        label: const Text('Hapus'),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _FormUserSheet extends StatefulWidget {
  final String adminEmail;
  final Map<String, dynamic>? edit;
  final VoidCallback onSaved;

  const _FormUserSheet({
    required this.adminEmail,
    this.edit,
    required this.onSaved,
  });

  @override
  State<_FormUserSheet> createState() => _FormUserSheetState();
}

class _FormUserSheetState extends State<_FormUserSheet> {
  late TextEditingController emailCtrl;
  late TextEditingController namaCtrl;
  late TextEditingController sekolahCtrl;
  DateTime? mulai;
  DateTime? akhir;
  bool loading = false;
  bool get isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    emailCtrl = TextEditingController(text: e?['email']?.toString() ?? '');
    namaCtrl = TextEditingController(text: e?['nama']?.toString() ?? '');
    sekolahCtrl = TextEditingController(text: e?['sekolah']?.toString() ?? '');
    if (e?['mulai'] != null) {
      mulai = DateTime.tryParse(e!['mulai'].toString());
    }
    if (e?['akhir'] != null) {
      akhir = DateTime.tryParse(e!['akhir'].toString());
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pick(bool isMulai) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          isMulai ? (mulai ?? DateTime.now()) : (akhir ?? DateTime.now()),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          mulai = picked;
        } else {
          akhir = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    final email = emailCtrl.text.trim().toLowerCase();
    final nama = namaCtrl.text.trim();
    final sekolah = sekolahCtrl.text.trim();

    if (email.isEmpty ||
        nama.isEmpty ||
        sekolah.isEmpty ||
        mulai == null ||
        akhir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field wajib diisi')),
      );
      return;
    }
    if (akhir!.isBefore(mulai!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal akhir tidak valid')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      Map<String, dynamic> res;
      if (isEdit) {
        res = await ApiService.updateUser(
          emailAdmin: widget.adminEmail,
          emailLama: widget.edit!['email'].toString(),
          nama: nama,
          sekolah: sekolah,
          mulai: _fmt(mulai),
          akhir: _fmt(akhir),
          emailBaru: email,
        );
      } else {
        res = await ApiService.tambahUserAdmin(
          emailAdmin: widget.adminEmail,
          email: email,
          nama: nama,
          sekolah: sekolah,
          mulai: _fmt(mulai),
          akhir: _fmt(akhir),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Selesai')),
      );
      if (res['success'] == true) widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    namaCtrl.dispose();
    sekolahCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? '✏️ Edit User' : '➕ Tambah User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: namaCtrl,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sekolahCtrl,
              decoration: const InputDecoration(labelText: 'Nama Sekolah'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanggal Mulai'),
              subtitle: Text(mulai == null ? 'Pilih' : _fmt(mulai)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pick(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanggal Akhir'),
              subtitle: Text(akhir == null ? 'Pilih' : _fmt(akhir)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pick(false),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEdit ? 'Simpan Perubahan' : 'Simpan User'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
