# Dokumen Perencanaan Absensi PPKD B6 ("AbsensiBro")

Dokumen ini berisi perencanaan komprehensif untuk pengembangan aplikasi mobile **AbsensiBro** (Absensi PPKD B6) berbasis Flutter. Perencanaan ini disusun berdasarkan analisis file `lib/ABSENSI PPKD B6.postman_collection.json` dan kebutuhan sistem keamanan **Role-Based Access Control (RBAC)**.

---

## 1. Pendahuluan & Ringkasan Proyek

Aplikasi **AbsensiBro** adalah platform pencatatan kehadiran digital untuk peserta pelatihan di PPKD (Pusat Pelatihan Kerja Daerah). Aplikasi ini mengintegrasikan REST API Backend, validasi lokasi berbasis GPS (Latitude/Longitude), dan pengunggahan foto profil/absensi guna mencegah kecurangan.

### Fitur Utama Aplikasi:
- **Autentikasi & Otorisasi**: Login, Registrasi (memilih Batch & Pelatihan), Lupa Password (OTP via Email).
- **Manajemen Kehadiran**: Check-in (Masuk), Check-out (Pulang), Pengajuan Izin Ketidakhadiran (Sakit/Izin).
- **Validasi Spasial**: Perekaman koordinat GPS (latitude, longitude, dan alamat fisik) saat melakukan absensi.
- **Statistik & Rekap**: Dasbor riwayat kehadiran harian dan grafik statistik kehadiran.
- **Offline Caching**: Penyimpanan data absensi sementara secara lokal jika koneksi internet terputus (antrean sinkronisasi).

---

## 2. Role-Based Access Control (RBAC)

Sistem membedakan hak akses dan antarmuka (UI) berdasarkan peran pengguna yang masuk. Terdapat **dua peran utama**:

### A. Peran (Roles) & Tanggung Jawab

| Peran (Role) | Deskripsi | Hak Akses Utama |
| :--- | :--- | :--- |
| **Peserta (Participant)** | Siswa/peserta pelatihan PPKD yang terdaftar pada batch dan program pelatihan tertentu. | - Melakukan Register & Login.<br>- Melakukan Check-in & Check-out.<br>- Mengajukan Izin Ketidakhadiran.<br>- Mengubah profil dan foto pribadi.<br>- Melihat statistik absensi milik sendiri. |
| **Admin / Pengelola** | Staf administrasi atau instruktur PPKD yang mengawasi jalannya pelatihan. | - Melihat daftar seluruh pengguna (`/api/users`).<br>- Memantau rekap kehadiran seluruh kelas.<br>- Melihat daftar program pelatihan (`trainings`) dan angkatan (`batches`).<br>- Melakukan penghapusan/koreksi data absensi (`DELETE /api/absen/{id}`). |

### B. Matriks Hak Akses REST API (Permissions Matrix)

Berikut adalah pemetaan hak akses untuk setiap endpoint yang didefinisikan dalam Postman Collection:

| No | Endpoint / API Route | HTTP Method | Auth Required | Akses Peserta | Akses Admin | Keterangan |
|:--:|:---|:---:|:---:|:---:|:---:|:---|
| 1 | `/api/register` | `POST` | No | Ya | Ya | Pendaftaran peserta baru |
| 2 | `/api/login` | `POST` | No | Ya | Ya | Login ke sistem, mendapatkan Bearer Token |
| 3 | `/api/absen/check-in` | `POST` | Bearer Token | Ya | Tidak | Mengirim data absen masuk (GPS + Foto) |
| 4 | `/api/absen/check-out` | `POST` | Bearer Token | Ya | Tidak | Mengirim data absen pulang |
| 5 | `/api/izin` | `POST` | Bearer Token | Ya | Tidak | Pengajuan izin/sakit dengan alasan |
| 6 | `/api/device-token` | `POST` | Bearer Token | Ya | Ya | Menyimpan token perangkat (Push Notification) |
| 7 | `/api/absen/today` | `GET` | Bearer Token | Ya | Ya | Memeriksa status absen hari ini |
| 8 | `/api/absen/stats` | `GET` | Bearer Token | Ya (Milik Sendiri) | Ya (Semua) | Statistik absen (filter tanggal/tahun) |
| 9 | `/api/absen/{id}` | `DELETE` | Bearer Token | Tidak | Ya | Penghapusan/koreksi data absen oleh Admin |
| 10| `/api/profile` | `GET` | Bearer Token | Ya (Milik Sendiri) | Ya (Milik Sendiri) | Mengambil data profil yang sedang login |
| 11| `/api/profile` (Update) | `PUT` | Bearer Token | Ya (Milik Sendiri) | Ya (Milik Sendiri) | Mengedit nama profil |
| 12| `/api/profile` (Photo) | `PUT` | Bearer Token | Ya (Milik Sendiri) | Ya (Milik Sendiri) | Mengupload foto profil baru (Base64) |
| 13| `/api/users` | `GET` | Bearer Token | Tidak | Ya | Mendapatkan daftar seluruh pengguna |
| 14| `/api/trainings` | `GET` | No | Ya | Ya | List program pelatihan yang aktif |
| 15| `/api/trainings/{id}` | `GET` | No | Ya | Ya | Detail program pelatihan berdasarkan ID |
| 16| `/api/batches` | `GET` | Bearer Token | Ya | Ya | List angkatan/batch pelatihan yang tersedia |
| 17| `/api/forgot-password` | `POST` | No | Ya | Ya | Kirim kode OTP reset password ke email |
| 18| `/api/reset-password` | `POST` | No | Ya | Ya | Reset password baru dengan kode OTP |

---

## 3. Pemetaan & Analisis Endpoint REST API

Berdasarkan Postman Collection `ABSENSI PPKD B6`, berikut detail request-response utama yang wajib diintegrasikan:

### A. Autentikasi & Registrasi

#### 1. Registrasi Peserta (`POST /api/register`)
- **Tujuan**: Mendaftarkan akun peserta pelatihan baru.
- **Request Body (JSON)**:
  ```json
  {
    "name": "Habibie",
    "email": "pesertamobile@gmail.com",
    "password": "Password123!",
    "jenis_kelamin": "L", // L = Laki-laki, P = Perempuan
    "profile_photo": "", // Base64 string (optional saat register)
    "batch_id": 1,
    "training_id": 16
  }
  ```
- **Response Sukses (200 OK)**:
  ```json
  {
    "message": "Registrasi berhasil",
    "data": {
      "token": "5|ckl7NZOm9I9s...",
      "user": {
        "id": 4,
        "name": "Habibie",
        "email": "pesertamobile@gmail.com",
        "created_at": "2025-04-11T01:14:55.000000Z"
      }
    }
  }
  ```

#### 2. Login Pengguna (`POST /api/login`)
- **Tujuan**: Autentikasi ke sistem untuk mendapatkan token sesi.
- **Request Body (JSON)**:
  ```json
  {
    "email": "projecthabibie@gmail.com",
    "password": "Password123"
  }
  ```
- **Response Sukses (200 OK)**:
  ```json
  {
    "message": "Login berhasil",
    "data": {
      "token": "14|zzUM9ra1...",
      "user": {
        "id": 1,
        "name": "budianduks",
        "email": "budi@example.com"
      }
    }
  }
  ```

### B. Fitur Absensi & Kehadiran (Peserta)

#### 1. Check-in Kehadiran (`POST /api/absen/check-in`)
- **Tujuan**: Mencatat jam masuk pelatihan, koordinat GPS, dan alamat lokasi.
- **Headers**: `Authorization: Bearer <token>`
- **Request Body (JSON)**:
  ```json
  {
    "attendance_date": "2026-05-03", // Tanggal absensi (YYYY-MM-DD)
    "check_in": "07:50",            // Jam masuk (HH:MM)
    "check_in_lat": -6.123456,      // Koordinat Lintang
    "check_in_lng": 106.123456,     // Koordinat Bujur
    "check_in_address": "Jakarta",   // Nama lokasi/alamat hasil geocoding
    "status": "masuk"               // Status: 'masuk' atau 'izin'
  }
  ```
- **Response Sukses (200 OK)**:
  ```json
  {
    "message": "Absen masuk berhasil",
    "data": {
      "id": 351,
      "attendance_date": "2025-07-16",
      "check_in_time": "08:10",
      "check_in_lat": -6.123456,
      "check_in_lng": 106.123456,
      "check_in_address": "Jakarta",
      "status": "masuk",
      "alasan_izin": null
    }
  }
  ```

#### 2. Check-out Kehadiran (`POST /api/absen/check-out`)
- **Tujuan**: Mencatat jam pulang pelatihan dan koordinat GPS saat pulang.
- **Headers**: `Authorization: Bearer <token>`
- **Request Body (JSON)**:
  ```json
  {
    "attendance_date": "2026-04-02",
    "check_out": "19:10",
    "check_out_lat": 6.2,
    "check_out_lng": 106.8,
    "check_out_address": "Jakarta"
  }
  ```

#### 3. Pengajuan Izin (`POST /api/izin`)
- **Tujuan**: Mengirim izin tidak masuk pelatihan dengan memberikan alasan tertulis.
- **Request Body (JSON)**:
  ```json
  {
    "date": "2025-07-20",
    "alasan_izin": "Alasan tidak bisa hadir karena sakit"
  }
  ```

#### 4. Statistik Kehadiran (`GET /api/absen/stats`)
- **Query Params**: `?start=2025-07-31&end=2025-12-31` atau `?year=2025`
- **Response Sukses (200 OK)**:
  ```json
  {
    "message": "Statistik absensi pengguna",
    "data": {
      "total_absen": 14,
      "total_masuk": 12,
      "total_izin": 2,
      "sudah_absen_hari_ini": true
    }
  }
  ```

### C. Manajemen Akun & Data Pelatihan

#### 1. Edit Profil (`PUT /api/profile`)
- **Request Body (JSON)**:
  ```json
  {
    "name": "budianduks"
  }
  ```

#### 2. Edit Foto Profil (`PUT /api/profile`)
- **Request Body (JSON)**:
  ```json
  {
    "profile_photo": "data:image/png;base64,iVBORw0KGgoAAAANS..." // Base64 string
  }
  ```

#### 3. Mengambil Semua Pengguna (`GET /api/users` - Admin Only)
- **Tujuan**: Admin memantau daftar seluruh peserta terdaftar.
- **Response Sukses (200 OK)**:
  ```json
  {
    "message": "Berhasil mengambil seluruh data pengguna",
    "data": [
      {
        "id": 1,
        "name": "budianduks",
        "email": "budi@example.com",
        "created_at": "2025-04-10T07:01:59.000000Z"
      }
    ]
  }
  ```

---

## 4. Arsitektur & Paket Pendukung (Flutter)

Aplikasi akan dikembangkan menggunakan arsitektur **MVVM (Model-View-ViewModel)** atau **Clean Architecture** (Data, Domain, Presentation) untuk memisahkan logika bisnis dari UI.

### A. Struktur Folder Proyek
```text
lib/
├── auth/                 # Logika otorisasi & penentuan Role (Peserta / Admin)
├── database/             # Helper SQLite & Preferences lokal
│   ├── databasehelper.dart
│   └── preferences_handler.dart
├── extensions/           # Utilitas tambahan / Extensions Dart
│   └── extension.dart
├── models/               # Model data parsing JSON & SQLite
│   ├── user_model_sql.dart
│   ├── attendance_model.dart
│   └── training_model.dart
├── services/             # HTTP Client (Dio/Retrofit) & Service API
│   ├── dio_client.dart
│   ├── api_service.dart  # Menggunakan Retrofit Generator
│   └── token_storage.dart
├── views/                # Layar UI (Page/Screen) dibagi per-Fitur & Role
│   ├── auth/             # Login, Register, Forgot Password
│   ├── dashboard/        # Layout utama (BottomNavBar)
│   ├── peserta/          # Layar khusus Peserta (Absen, Izin, Stats)
│   └── admin/            # Layar khusus Admin (List Users, Rekap Absen)
├── widgets/              # Komponen reusable UI (Buttons, Cards, Modals)
└── main.dart             # Titik masuk aplikasi
```

### B. Analisis Paket Pendukung (`pubspec.yaml`)
Aplikasi ini memanfaatkan pustaka-pustaka modern yang sudah terinstal di proyek:
- **`dio` & `retrofit`**: Manajemen REST API dengan auto-generated parser (`retrofit_generator`), lebih bersih dan aman dibanding http standard.
- **`shared_preferences` & `flutter_secure_storage`**: Menyimpan token autentikasi (Bearer token) dengan enkripsi aman di keychain/keystore peranti, serta menyimpan data sesi pengguna (termasuk Role).
- **`sqflite` & `path`**: SQLite database lokal untuk menyimpan data user lokal dan mengantre absensi offline saat koneksi buruk.
- **`geolocator` & `geocoding`**: Mengambil koordinat GPS peserta (Lat/Lng) dan mengonversinya menjadi alamat fisik (Jalan, Kota, Negara).
- **`google_maps_flutter`**: Menampilkan peta lokasi presisi peserta dan menggambar radius (Geofencing) jarak ke kantor/PPKD.
- **`image_picker`**: Membuka kamera/galeri untuk mengambil foto peserta untuk absensi mandiri atau memperbarui foto profil.
- **`fl_chart`**: Membuat visualisasi grafik rekap absensi bulanan/mingguan yang interaktif untuk dasbor peserta dan admin.

---

## 5. Rencana Skema Database Lokal (SQLite)

Untuk mendukung **Offline-First Capabilities** (pengisian absen ketika tidak ada sinyal internet), database lokal `skinoura.db` pada databasehelper.dart akan dikembangkan dengan menambahkan tabel **antrean absensi (attendance queue)**:

```sql
-- 1. Tabel Sesi User (Menyimpan profil & role saat login)
CREATE TABLE session_user (
    id INTEGER PRIMARY KEY,
    name TEXT,
    email TEXT,
    role TEXT, -- 'admin' atau 'peserta'
    token TEXT,
    batch_id INTEGER,
    training_id INTEGER
);

-- 2. Tabel Antrean Absensi Offline
CREATE TABLE attendance_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_type TEXT, -- 'check-in' atau 'check-out' atau 'izin'
    attendance_date TEXT,
    check_time TEXT,
    latitude REAL,
    longitude REAL,
    address TEXT,
    status TEXT,
    alasan_izin TEXT,
    is_synced INTEGER DEFAULT 0 -- 0 = Belum sinkron, 1 = Sudah sinkron
);
```

### Mekanisme Offline Caching:
1. Saat peserta menekan tombol **Check-In/Check-Out/Izin**, aplikasi mengecek status internet.
2. Jika **online**, data dikirim langsung ke API.
3. Jika **offline**, data disimpan ke tabel `attendance_queue` lokal.
4. Ketika perangkat kembali **online** (dideteksi via plugin connectivity_plus atau dio interceptor), aplikasi otomatis mengirim antrean yang tersimpan ke server backend secara berurutan.

---

## 6. Alur Pengalaman Pengguna (UI Flow) Berbasis RBAC

1. **Start App** -> Periksa Token Sesi (menggunakan secure storage).
2. Jika **Token Tidak Ada/Expired** -> Tampilkan halaman **Login / Register**.
3. Jika **Token Ada & Valid** -> Periksa Role User:
   - **Role: Peserta**:
     - Dasbor utama menampilkan sisa waktu check-in, status absen hari ini, tombol Check-In (aktif jika berada di radius pelatihan) & Check-Out.
     - Halaman Riwayat Kehadiran (kalender kehadiran & grafik fl_chart).
     - Halaman Pengajuan Izin (Form input tanggal + alasan).
     - Halaman Profile & Edit Profile.
   - **Role: Admin**:
     - Dasbor utama menampilkan metrik ringkasan kehadiran hari ini (misal: Total hadir, Total izin, Total alpha).
     - Halaman Daftar Peserta (`/api/users`), dengan pencarian dan filter kelas.
     - Halaman Verifikasi Pengajuan Izin (meninjau izin dari peserta).
     - Fitur menghapus/koreksi absensi (`DELETE /api/absen/{id}`).

---

## 7. Rencana Kerja Pengembangan (Roadmap)

Rencana kerja ini dibagi menjadi beberapa sprint (1 sprint = 1 minggu):

### Sprint 1: Setup Proyek & REST Client (Arsitektur Dasar)
- Konfigurasi `DioClient` dan `TokenStorage` (menggunakan secure storage).
- Implementasi Retrofit `ApiService` untuk mendefinisikan 18 endpoint REST API.
- Pembuatan Model JSON Serializable untuk model user, pelatihan, batch, dan absensi.

### Sprint 2: Autentikasi & Authorization (Penerapan RBAC)
- Pembuatan UI Login, Registrasi (dengan pilihan Batch & Pelatihan dinamis dari API), dan Forgot/Reset Password.
- Manajemen Sesi: Menyimpan Bearer Token dan Role User (Peserta/Admin).
- Pembuatan Router/Middleware: Mengarahkan user ke halaman Dasbor yang sesuai dengan role setelah login.

### Sprint 3: Core Fitur Peserta - Geofencing & Absen
- Implementasi Geolocation: Mendapatkan koordinat GPS dan memverifikasi apakah koordinat berada di dalam radius PPKD (misal: radius 50 meter).
- Integrasi Image Picker untuk foto bukti absensi.
- Pembuatan halaman Check-In/Check-Out, Today's Absen, dan Form Pengajuan Izin.

### Sprint 4: Database Lokal & Sinkronisasi Offline
- Migrasi database SQLite (`DBHelper`) untuk tabel antrean absensi offline.
- Pembuatan service background worker untuk sinkronisasi otomatis ketika internet kembali terhubung.
- Pengujian offline-first scenario (mematikan WiFi/Data seluler lalu mencoba absen).

### Sprint 5: Dasbor Admin & Grafik Statistik
- Pembuatan Dasbor khusus Admin untuk melihat rekapitulasi kehadiran semua peserta.
- Pembuatan layar daftar user (mengakses `/api/users`) dan fitur menghapus absensi (`DELETE /api/absen/{id}`).
- Integrasi grafik `fl_chart` pada dasbor Peserta dan Admin untuk rekap bulanan.

### Sprint 6: Testing & Finishing
- Debugging, optimalisasi performa API Call, penanganan exception/error handler (contoh: status code 409 untuk absensi ganda, 422 untuk validasi gagal).
- Pembersihan kode (refactoring) dan persiapan rilis aplikasi.
