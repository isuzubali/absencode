import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'absen_screen.dart';
import 'tidak_hadir_screen.dart';
import 'login_screen.dart';
import 'admin/admin_home_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late UserModel user;
  String clockIn = '--:--';
  String clockOut = '--:--';
  bool loading = true;
  bool sudahClockIn = false;
  bool sudahClockOut = false;
  bool adaPengajuanHariIni = false;
  String? jenisPengajuan;
  String? statusPengajuan;
  Timer? _timer;
  String _timeStr = '';
  String _dateStr = '';

  @override
  void initState() {
    super.initState();
    user = widget.user;
    _updateClock();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _loadStatus();
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _timeStr = DateFormat('HH:mm').format(now);
      _dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);
    });
  }

  Future<void> _loadStatus() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.getStatusHariIni(user.email);
      setState(() {
        clockIn = res['clockIn']?.toString() ?? '--:--';
        clockOut = res['clockOut']?.toString() ?? '--:--';
        sudahClockIn = res['sudahClockIn'] == true;
        sudahClockOut = res['sudahClockOut'] == true;
        adaPengajuanHariIni = res['adaPengajuanHariIni'] == true;
        jenisPengajuan = res['jenisPengajuanHariIni']?.toString();
        statusPengajuan = res['statusPengajuanHariIni']?.toString();
      });
    } catch (e) {
      debugPrint('loadStatus error: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('absensi_email');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _bukaAbsen() async {
    if (!user.aktif || sudahClockOut) return;

    String action = sudahClockIn ? 'Clock Out' : 'Clock In';

    if (action == 'Clock In') {
      try {
        final cek = await ApiService.cekPerluPengajuan(user.email);
        if (cek['perlu'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(cek['message'] ?? 'Ada hari belum lengkap')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TidakHadirScreen(
                email: user.email,
                onSuccess: _loadStatus,
              ),
            ),
          );
          return;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AbsenScreen(
          email: user.email,
          action: action,
        ),
      ),
    );
    if (result == true) _loadStatus();
  }

  Future<void> _bukaWa() async {
    final uri = Uri.parse(AppConstants.waGroupUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String btnText = 'Clock In';
    Color btnColor = const Color(0xFF2563EB);
    bool btnEnabled = user.aktif && !sudahClockOut && !adaPengajuanHariIni;

    if (adaPengajuanHariIni) {
      btnText = '${jenisPengajuan ?? 'Tidak Hadir'} (${statusPengajuan ?? ''})';
      btnEnabled = false;
    } else if (sudahClockOut) {
      btnText = 'Sudah Clock Out Hari Ini';
      btnEnabled = false;
    } else if (sudahClockIn) {
      btnText = 'Clock Out';
      btnColor = const Color(0xFFDC2626);
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStatus,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Dashboard Absensi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (user.isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminHomeScreen(adminEmail: user.email),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                        ),
                        child: const Text('Admin', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFFEF4444)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _timeStr,
                      style: const TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateStr,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nama.isEmpty ? '-' : user.nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      user.sekolah.isEmpty ? '-' : user.sekolah,
                      style: const TextStyle(
                        color: Color(0xFF1E40AF),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Periode: ${user.mulai ?? '-'} s/d ${user.akhir ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
              ),
              if (!user.aktif) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.statusPeriode == 'belum_mulai'
                        ? 'Periode absensi Anda belum dimulai.'
                        : 'Periode absensi Anda sudah berakhir.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _statusCard('Clock In', clockIn)),
                  const SizedBox(width: 12),
                  Expanded(child: _statusCard('Clock Out', clockOut)),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: btnEnabled ? _bukaAbsen : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        btnEnabled ? btnColor : const Color(0xFF94A3B8),
                    disabledBackgroundColor: const Color(0xFF94A3B8),
                  ),
                  child: Text(btnText),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: (user.aktif && !sudahClockIn && !adaPengajuanHariIni)
                      ? () async {
                          final ok = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TidakHadirScreen(
                                email: user.email,
                                onSuccess: _loadStatus,
                              ),
                            ),
                          );
                          if (ok == true) _loadStatus();
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'Tidak Hadir (Sakit / Izin / Alpha / Lupa Absen)',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: TextButton.icon(
                  onPressed: _bukaWa,
                  icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                  label: const Text(
                    'Gabung Group WhatsApp',
                    style: TextStyle(color: Color(0xFF334155)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF3B82F6),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
