# Sistem Absensi — Flutter (Web + Mobile)

Aplikasi absensi terintegrasi dengan GPS radius, pengajuan tidak hadir, dan dashboard admin.

Backend: **Google Apps Script** (Spreadsheet).

---

## Setup Cepat

### 1. Update URL Backend

Buka `lib/constants.dart` dan ganti:

```dart
static const String baseUrl =
    'https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec';
```

### 2. Deploy Google Apps Script

1. Buka project Apps Script kamu.
2. Tambahkan **router `doGet`** (lihat file `gas_router.js` di folder ini).
3. Deploy → **New deployment** → Type: **Web app**
   - Execute as: **Me**
   - Who has access: **Anyone**
4. Salin URL, paste ke `constants.dart`.

### 3. Jalankan Flutter

```bash
flutter pub get
flutter run -d chrome          # Web
flutter run                    # Mobile
```

### 4. Build Web (production)

```bash
flutter build web --release
```

Hasil ada di `build/web/`. Deploy ke Firebase Hosting / Netlify / Vercel (**wajib HTTPS** agar GPS jalan).

---

## Fitur

| Fitur | Keterangan |
|-------|------------|
| Login / Daftar | Email + periode absensi |
| Clock In / Out | GPS + radius 100 m + peta |
| Tidak Hadir | Sakit / Izin / Alpha / Lupa + upload surat |
| Admin | Status hari ini, approve pengajuan, kelola user/admin, laporan bulanan |
| WhatsApp Group | Tombol join group |

---

## Permission Lokasi (Web)

- Browser hanya mengizinkan GPS di **HTTPS** (atau `localhost`).
- User harus klik **Allow** di dialog browser.
- Jika ditolak: buka ikon gembok di address bar → Site settings → Location → Allow.

---

## Struktur Folder

```
lib/
  main.dart
  constants.dart
  models/user_model.dart
  services/api_service.dart
  screens/
    login_screen.dart
    daftar_screen.dart
    dashboard_screen.dart
    absen_screen.dart
    tidak_hadir_screen.dart
    admin/
      admin_home_screen.dart
      tab_status_hari_ini.dart
      tab_pengajuan.dart
      tab_kelola_user.dart
      tab_kelola_admin.dart
      tab_laporan_bulanan.dart
web/
  index.html
```

---

## Catatan

- Koordinat kantor default: Gianyar (`-8.640570, 115.277860`). Ubah di `constants.dart` jika perlu.
- Radius maksimal: **100 meter**.
