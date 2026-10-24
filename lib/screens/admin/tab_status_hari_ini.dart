import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class TabStatusHariIni extends StatefulWidget {
  final String adminEmail;
  const TabStatusHariIni({super.key, required this.adminEmail});

  @override
  State<TabStatusHariIni> createState() => _TabStatusHariIniState();
}

class _TabStatusHariIniState extends State<TabStatusHariIni> {
  List<dynamic> data = [];
  List<dynamic> belumAbsen = [];
  bool loading = true;
  String? error;

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
      final res = await ApiService.getAdminDashboard(widget.adminEmail);
      setState(() {
        data = (res['data'] as List?) ?? [];
        belumAbsen = (res['belumAbsen'] as List?) ?? [];
      });
    } catch (e) {
      setState(() => error = e.toString());
    }
    if (mounted) setState(() => loading = false);
  }

  Color _badgeColor(String status) {
    if (status.contains('Clock In')) return const Color(0xFF16A34A);
    if (status.contains('Clock Out')) return const Color(0xFF2563EB);
    if (status.contains('Sakit') || status.contains('Izin')) {
      return const Color(0xFFCA8A04);
    }
    if (status.contains('Alpha')) return const Color(0xFFDC2626);
    if (status.contains('Lupa')) return const Color(0xFF7C3AED);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Status Hari Ini',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada data user aktif',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            ...data.map((u) {
              final status = (u['status'] ?? '-').toString();
              final note = (u['note'] ?? '-').toString();
              final file = u['file']?.toString();

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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                              color: _badgeColor(status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _badgeColor(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (note != '-' && note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Note: $note',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                      if (file != null && file.isNotEmpty && file != '-')
                        TextButton(
                          onPressed: () async {
                            final uri = Uri.parse(file);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          child: const Text('Lihat Surat'),
                        ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
          const Text(
            'Belum Pernah Absen',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (belumAbsen.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Semua user sudah pernah absen',
                  style: TextStyle(color: Color(0xFF16A34A)),
                ),
              ),
            )
          else
            ...belumAbsen.map((u) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    u['nama'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${u['sekolah'] ?? ''}\n${u['email'] ?? ''}\n${u['mulai'] ?? '-'} s/d ${u['akhir'] ?? '-'}',
                  ),
                  isThreeLine: true,
                ),
              );
            }),
        ],
      ),
    );
  }
}
