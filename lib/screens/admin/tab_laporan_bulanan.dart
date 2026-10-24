import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class TabLaporanBulanan extends StatefulWidget {
  final String adminEmail;
  const TabLaporanBulanan({super.key, required this.adminEmail});

  @override
  State<TabLaporanBulanan> createState() => _TabLaporanBulananState();
}

class _TabLaporanBulananState extends State<TabLaporanBulanan> {
  int bulan = DateTime.now().month;
  int tahun = DateTime.now().year;
  List<dynamic> data = [];
  bool loading = false;
  bool loaded = false;

  final bulanNames = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.getLaporanBulanan(
        email: widget.adminEmail,
        bulan: bulan,
        tahun: tahun,
      );
      setState(() {
        data = res;
        loaded = true;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: bulan,
                  decoration: const InputDecoration(isDense: true),
                  items: List.generate(12, (i) {
                    return DropdownMenuItem(
                      value: i + 1,
                      child: Text(bulanNames[i + 1]),
                    );
                  }),
                  onChanged: (v) {
                    if (v != null) setState(() => bulan = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: tahun,
                  decoration: const InputDecoration(isDense: true),
                  items: [2025, 2026, 2027, 2028]
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => tahun = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: loading ? null : _load,
                child: const Text('Tampilkan'),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : !loaded
                  ? const Center(
                      child: Text(
                        'Pilih bulan & tahun lalu klik Tampilkan',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  : data.isEmpty
                      ? const Center(child: Text('Tidak ada data'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: data.length,
                          itemBuilder: (_, i) {
                            final u = data[i];
                            final detail = (u['detail'] as List?) ?? [];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
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
                                      '${u['sekolah'] ?? ''} • ${u['email'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (detail.isEmpty)
                                      const Text(
                                        'Belum ada data absensi di bulan ini',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      )
                                    else
                                      ...detail.map((d) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 90,
                                                child: Text(
                                                  d['tanggalTampil'] ??
                                                      d['tanggal'] ??
                                                      '-',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 55,
                                                child: Text(
                                                  d['clockIn'] ?? '-',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 55,
                                                child: Text(
                                                  d['clockOut'] ?? '-',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  d['note'] ?? '-',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
