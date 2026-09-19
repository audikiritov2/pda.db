# PDA Control Flutter

APK Android untuk sistem kontrol PDA dengan Google Sheets sebagai database melalui Google Apps Script API.

## Fitur versi 1.1
- Dashboard monitoring
- Daftar PDA + pencarian + filter Tersedia/Dipinjam
- Monitoring PDA yang sedang dipinjam
- Pengembalian PDA + kondisi Bagus/Rusak/Hilang
- Pencarian OPS
- Pinjam PDA berdasarkan OPS ID
- Scan QR
- UI mobile Material 3
- Tidak ada login/PIN

## Jalur data
Flutter APK -> Google Apps Script API -> Google Sheets

Sheet utama tetap dipakai: DADICATED, DBOPSTEAM, Database_OPS, PDA CONTROL, Peminjaman_PDA, Backup_Peminjaman_PDA.

## Build lokal
```bash
flutter pub get
flutter run
flutter build apk --release
```

## Build otomatis di GitHub
Upload seluruh isi folder ini ke repository GitHub. Workflow `.github/workflows/build-apk.yml` akan membuat project Android, build APK release, lalu menyimpan APK sebagai GitHub Actions Artifact.

Untuk distribusi langsung, hasil artifact bernama `PDA-Control-APK` berisi `app-release.apk`.

> Jangan masukkan ke repository public file keystore, password signing, atau secret pribadi. Flutter merekomendasikan menjaga file signing tetap privat.
