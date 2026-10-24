import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class ApiService {
  static Future<Map<String, dynamic>> _call(
    String action, {
    Map<String, dynamic>? params,
  }) async {
    final query = <String, String>{
      'action': action,
      if (params != null)
        ...params.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    };

    final uri = Uri.parse(AppConstants.baseUrl).replace(queryParameters: query);

    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final body = response.body.trim();
    if (body.isEmpty) throw Exception('Response kosong dari server');

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      // Jika server mengembalikan List langsung (mis. getDaftarUser)
      return {'data': decoded, 'success': true};
    } catch (_) {
      throw Exception('Format response tidak valid');
    }
  }

  // ====================== AUTH ======================
  static Future<Map<String, dynamic>> loginUser(String email) {
    return _call('loginUser', params: {'email': email});
  }

  static Future<Map<String, dynamic>> daftarUser({
    required String email,
    required String nama,
    required String sekolah,
    required String mulai,
    required String akhir,
  }) {
    return _call('daftarUser', params: {
      'email': email,
      'nama': nama,
      'sekolah': sekolah,
      'mulaiTanggal': mulai,
      'akhirTanggal': akhir,
    });
  }

  // ====================== USER ======================
  static Future<Map<String, dynamic>> getStatusHariIni(String email) {
    return _call('getStatusHariIni', params: {'email': email});
  }

  static Future<Map<String, dynamic>> cekPerluPengajuan(String email) {
    return _call('cekPerluPengajuanSebelumAbsen', params: {'email': email});
  }

  static Future<Map<String, dynamic>> simpanAbsenNormal({
    required String email,
    required String status,
    required double lat,
    required double lng,
  }) {
    return _call('simpanAbsenNormal', params: {
      'email': email,
      'status': status,
      'latUser': lat.toString(),
      'lngUser': lng.toString(),
    });
  }

  static Future<Map<String, dynamic>> ajukanTidakHadir({
    required String email,
    required String alasan,
    required String keterangan,
    required String tanggalTarget,
    String? fileBase64,
    String? fileName,
  }) {
    return _call('ajukanTidakHadir', params: {
      'email': email,
      'alasan': alasan,
      'keterangan': keterangan,
      'tanggalTarget': tanggalTarget,
      if (fileBase64 != null) 'fileBase64': fileBase64,
      if (fileName != null) 'fileName': fileName,
    });
  }

  // ====================== ADMIN ======================
  static Future<Map<String, dynamic>> getAdminDashboard(String email) {
    return _call('getAdminDashboard', params: {'email': email});
  }

  static Future<List<dynamic>> getDaftarPengajuan(
    String email, {
    String statusFilter = 'PENDING',
  }) async {
    final res = await _call('getDaftarPengajuan', params: {
      'email': email,
      'statusFilter': statusFilter,
    });
    if (res['data'] is List) return res['data'] as List;
    // Beberapa endpoint mengembalikan array langsung via wrapper
    return [];
  }

  static Future<Map<String, dynamic>> prosesPersetujuanAdmin({
    required String email,
    required String idPengajuan,
    required String aksi,
  }) {
    return _call('prosesPersetujuanAdmin', params: {
      'email': email,
      'idPengajuan': idPengajuan,
      'aksi': aksi,
    });
  }

  static Future<List<dynamic>> getDaftarUser(String email) async {
    final res = await _call('getDaftarUser', params: {'email': email});
    if (res['data'] is List) return res['data'] as List;
    return [];
  }

  static Future<Map<String, dynamic>> tambahUserAdmin({
    required String emailAdmin,
    required String email,
    required String nama,
    required String sekolah,
    required String mulai,
    required String akhir,
  }) {
    return _call('tambahUserAdmin', params: {
      'email': emailAdmin,
      'emailBaru': email,
      'nama': nama,
      'sekolah': sekolah,
      'mulaiTanggal': mulai,
      'akhirTanggal': akhir,
    });
  }

  static Future<Map<String, dynamic>> updateUser({
    required String emailAdmin,
    required String emailLama,
    required String nama,
    required String sekolah,
    required String mulai,
    required String akhir,
    String? emailBaru,
  }) {
    return _call('updateUser', params: {
      'email': emailAdmin,
      'emailLama': emailLama,
      'nama': nama,
      'sekolah': sekolah,
      'mulaiTanggal': mulai,
      'akhirTanggal': akhir,
      'emailBaru': emailBaru ?? emailLama,
    });
  }

  static Future<Map<String, dynamic>> hapusUser({
    required String emailAdmin,
    required String emailTarget,
  }) {
    return _call('hapusUser', params: {
      'email': emailAdmin,
      'emailTarget': emailTarget,
    });
  }

  static Future<List<dynamic>> getDaftarAdmin(String email) async {
    final res = await _call('getDaftarAdmin', params: {'email': email});
    if (res['data'] is List) return res['data'] as List;
    return [];
  }

  static Future<Map<String, dynamic>> tambahAdmin({
    required String emailAdmin,
    required String emailBaru,
  }) {
    return _call('tambahAdmin', params: {
      'email': emailAdmin,
      'emailBaru': emailBaru,
    });
  }

  static Future<Map<String, dynamic>> hapusAdmin({
    required String emailAdmin,
    required String emailTarget,
  }) {
    return _call('hapusAdmin', params: {
      'email': emailAdmin,
      'emailTarget': emailTarget,
    });
  }

  static Future<List<dynamic>> getLaporanBulanan({
    required String email,
    required int bulan,
    required int tahun,
  }) async {
    final res = await _call('getLaporanBulanan', params: {
      'email': email,
      'bulan': bulan.toString(),
      'tahun': tahun.toString(),
    });
    if (res['data'] is List) return res['data'] as List;
    return [];
  }
}
