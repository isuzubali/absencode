/**
 * ROUTER untuk Flutter / API eksternal
 * Tempel di file .gs kamu (ganti function doGet yang lama).
 *
 * Setelah menambah, Deploy ulang sebagai Web App:
 * Execute as: Me | Who has access: Anyone
 */

function doGet(e) {
  setupSheets();
  var action = (e.parameter.action || '').toString().trim();
  var email = (e.parameter.email || '').toString().trim().toLowerCase();

  try {
    var result;

    switch (action) {
      case 'loginUser':
        result = loginUser(email);
        break;

      case 'daftarUser':
        result = daftarUser(
          email,
          e.parameter.nama,
          e.parameter.sekolah,
          e.parameter.mulaiTanggal,
          e.parameter.akhirTanggal
        );
        break;

      case 'getStatusHariIni':
        result = getStatusHariIni(email);
        break;

      case 'cekPerluPengajuanSebelumAbsen':
        result = cekPerluPengajuanSebelumAbsen(email);
        break;

      case 'simpanAbsenNormal':
        result = simpanAbsenNormal(
          email,
          e.parameter.status,
          e.parameter.latUser,
          e.parameter.lngUser
        );
        break;

      case 'ajukanTidakHadir':
        result = ajukanTidakHadir(
          email,
          e.parameter.alasan,
          e.parameter.keterangan,
          e.parameter.fileBase64 || null,
          e.parameter.fileName || null,
          e.parameter.tanggalTarget
        );
        break;

      case 'getAdminDashboard':
        result = getAdminDashboard(email);
        break;

      case 'getDaftarPengajuan':
        result = getDaftarPengajuan(email, e.parameter.statusFilter || 'PENDING');
        break;

      case 'prosesPersetujuanAdmin':
        result = prosesPersetujuanAdmin(
          e.parameter.idPengajuan,
          e.parameter.aksi,
          email
        );
        break;

      case 'getDaftarUser':
        result = getDaftarUser(email);
        break;

      case 'tambahUserAdmin':
        result = tambahUserAdmin(
          email,
          e.parameter.emailBaru,
          e.parameter.nama,
          e.parameter.sekolah,
          e.parameter.mulaiTanggal,
          e.parameter.akhirTanggal
        );
        break;

      case 'updateUser':
        result = updateUser(
          email,
          e.parameter.emailLama,
          e.parameter.nama,
          e.parameter.sekolah,
          e.parameter.mulaiTanggal,
          e.parameter.akhirTanggal,
          e.parameter.emailBaru
        );
        break;

      case 'hapusUser':
        result = hapusUser(email, e.parameter.emailTarget);
        break;

      case 'getDaftarAdmin':
        result = getDaftarAdmin(email);
        break;

      case 'tambahAdmin':
        result = tambahAdmin(email, e.parameter.emailBaru);
        break;

      case 'hapusAdmin':
        result = hapusAdmin(email, e.parameter.emailTarget);
        break;

      case 'getLaporanBulanan':
        result = getLaporanBulanan(
          Number(e.parameter.bulan),
          Number(e.parameter.tahun),
          email
        );
        break;

      default:
        // Fallback: tampilkan HTML web (browser)
        var template = HtmlService.createTemplateFromFile('Index');
        template.userEmail = '';
        template.isAdmin = false;
        return template.evaluate()
          .setTitle('Sistem Absensi Terintegrasi')
          .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
    }

    return ContentService
      .createTextOutput(JSON.stringify(result))
      .setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({
        success: false,
        message: err.message || String(err)
      }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}
