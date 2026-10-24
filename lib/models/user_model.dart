class UserModel {
  final String email;
  final String nama;
  final String sekolah;
  final String? mulai;
  final String? akhir;
  final bool aktif;
  final bool isAdmin;
  final String statusPeriode;
  final bool terdaftar;

  UserModel({
    required this.email,
    this.nama = '',
    this.sekolah = '',
    this.mulai,
    this.akhir,
    this.aktif = false,
    this.isAdmin = false,
    this.statusPeriode = '',
    this.terdaftar = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: (json['email'] ?? '').toString().toLowerCase(),
      nama: (json['nama'] ?? '').toString(),
      sekolah: (json['sekolah'] ?? '').toString(),
      mulai: json['mulai']?.toString(),
      akhir: json['akhir']?.toString(),
      aktif: json['aktif'] == true,
      isAdmin: json['isAdmin'] == true,
      statusPeriode: (json['statusPeriode'] ?? '').toString(),
      terdaftar: json['terdaftar'] == true,
    );
  }
}
