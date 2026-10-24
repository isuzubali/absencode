import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class TabPengajuan extends StatefulWidget {
  final String adminEmail;
  const TabPengajuan({super.key, required this.adminEmail});

  @override
  State<TabPengajuan> createState() => _TabPengajuanState();
}

class _TabPengajuanState extends State<TabPengajuan> {
  List<dynamic> list = [];
  bool loading = true;
  String filter = 'PENDING';
  String? error;

  final filters = ['PENDING', 'DISETUJUI', 'DITOLAK', 'SEMUA'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await ApiService.getDaftarPengajuan(
        widget.adminEmail,
        statusFilter: filter,
      );
      setState(() => list = res);
    } catch (e) {
      setState(() => error = e.toString());
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _proses(String id, String aksi) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Konfirmasi $aksi'),
        content: Text('Yakin $aksi pengajuan $id?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(aksi),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await ApiService.prosesPersetujuanAdmin(
        email: widget.adminEmail,
        idPengajuan: id,
        aksi: aksi,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Selesai')),
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _statusColor(String st) {
    switch (st) {
      case 'PENDING':
        return const Color(0xFFCA8A04);
      case 'DISETUJUI':
        return const Color(0xFF16A34A);
      case 'DITOLAK':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
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
                child: DropdownButtonFormField<String>(
                  value: filter,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  items: filters
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => filter = v);
                      _load();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
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
              : error != null
                  ? Center(
                      child:
                          Text(error!, style: const TextStyle(color: Colors.red)))
                  : list.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada pengajuan',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final p = list[i];
                              final status =
                                  (p['status'] ?? 'PENDING').toString();
                              final file = p['file']?.toString();

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              p['nama'] ?? '-',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _statusColor(status)
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: _statusColor(status),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        p['email'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tanggal: ${p['tanggalTampil'] ?? p['tanggal'] ?? '-'}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        'Jenis: ${p['jenis'] ?? '-'}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        'Keterangan: ${p['keterangan'] ?? '-'}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        'ID: ${p['id'] ?? ''} • ${p['timestamp'] ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                      if (file != null &&
                                          file.isNotEmpty &&
                                          file != '-')
                                        TextButton(
                                          onPressed: () async {
                                            final uri = Uri.parse(file);
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri,
                                                  mode: LaunchMode
                                                      .externalApplication);
                                            }
                                          },
                                          child: const Text('Lihat File'),
                                        ),
                                      if (status == 'PENDING') ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () => _proses(
                                                    p['id'].toString(),
                                                    'SETUJU'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFF16A34A),
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 10),
                                                ),
                                                child: const Text('Setuju'),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () => _proses(
                                                    p['id'].toString(),
                                                    'TOLAK'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFFDC2626),
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 10),
                                                ),
                                                child: const Text('Tolak'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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
