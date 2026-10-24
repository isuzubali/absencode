import 'package:flutter/material.dart';
import 'tab_status_hari_ini.dart';
import 'tab_pengajuan.dart';
import 'tab_kelola_user.dart';
import 'tab_kelola_admin.dart';
import 'tab_laporan_bulanan.dart';

class AdminHomeScreen extends StatefulWidget {
  final String adminEmail;
  const AdminHomeScreen({super.key, required this.adminEmail});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF7C3AED),
          tabs: const [
            Tab(text: 'Status Hari Ini'),
            Tab(text: 'Pengajuan'),
            Tab(text: 'Kelola User'),
            Tab(text: 'Kelola Admin'),
            Tab(text: 'Laporan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          TabStatusHariIni(adminEmail: widget.adminEmail),
          TabPengajuan(adminEmail: widget.adminEmail),
          TabKelolaUser(adminEmail: widget.adminEmail),
          TabKelolaAdmin(adminEmail: widget.adminEmail),
          TabLaporanBulanan(adminEmail: widget.adminEmail),
        ],
      ),
    );
  }
}
