# LAPORAN MODUL 1 – UNIT 1.1
## Persiapan Source Layer dan Initial Data Profiling

**Studi Kasus:** Database Akademik Perguruan Tinggi  
**DBMS:** PostgreSQL  
**Schema:** `src`

---

## Identitas Laporan

| Identitas | Keterangan |
|---|---|
| Nama | Alda Syafitri |
| NIM | 240306041 |
| Program Studi | TEKNOLOGI INFORMASI|
| Kelas/Kelompok | A/4 |
| Modul | 1 |
| Unit | 1.1 |

## Tujuan Praktikum

Praktikum Unit 1.1 bertujuan menyiapkan source layer pada PostgreSQL, memuat dataset raw UADW v1.0, memverifikasi struktur dan jumlah data sumber, serta melakukan *initial profiling* untuk memperoleh gambaran awal karakteristik dataset akademik.

## Ketentuan Praktikum

1. Gunakan PostgreSQL dan schema `src`.
2. Pertahankan nilai raw sebagaimana tersedia pada file sumber.
3. Jangan melakukan proses cleaning, standardisasi, deduplikasi, `UPDATE`, atau `DELETE` terhadap isi raw source pada unit ini.
4. Sesuaikan path file CSV dengan lokasi dataset pada komputer masing-masing.
5. Untuk setiap aktivitas query, cantumkan query yang dijalankan, hasil eksekusi, dan interpretasi.
6. Apabila hasil aktual berbeda dari nilai acuan pada bahan praktikum, catat perbedaannya dan lakukan pemeriksaan; jangan mengubah data hanya agar hasilnya sama.

---

## 1. Verifikasi Environment PostgreSQL

Pada tahap ini dilakukan pemeriksaan awal terhadap perangkat lunak dan koneksi database yang digunakan untuk praktikum.

### 1.1 Memeriksa versi PostgreSQL

Query yang digunakan:

```sql
SELECT version();
```

**Hasil eksekusi:**

```text
```

**Interpretasi:**

Hasil query menunjukkan versi PostgreSQL yang digunakan pada perangkat kerja (lihat tangkapan layar). Versi ini tercatat sebagai bagian dari kesiapan environment praktikum.

### 1.2 Memeriksa database dan user aktif

Query yang digunakan:

```sql
SELECT
    current_database() AS database_aktif,
    current_user AS user_aktif;
```

**Hasil eksekusi:**

| database_aktif | user_aktif |
|---|---|
| uadw_lab | postgres |

**Interpretasi:**

Query menampilkan nama database yang sedang terhubung dan pengguna (user) yang dipakai pada koneksi DBeaver, sehingga seluruh pekerjaan berikutnya dapat ditelusuri ke koneksi yang benar.

### 1.3 Memeriksa keberadaan schema `src`

Query yang digunakan:

```sql
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'src';
```

**Hasil eksekusi:**

| schema_name |
|---|
| src |

**Status:** [x] Schema ditemukan  [ ] Schema belum ditemukan

**Interpretasi:**

Schema `src` ditemukan pada database yang digunakan, sehingga dapat dipakai sebagai tempat penyimpanan data mentah (raw source layer).

---

## 2. Membuat dan Memverifikasi Source Layer

Source layer menggunakan schema `src` untuk menyimpan data mentah (*raw source*). Sepuluh tabel yang digunakan pada praktikum ini adalah sebagai berikut.

| No. | Nama tabel | Peran data | Status pembuatan |
|---:|---|---|---|
| 1 | `src.program_studi` | Master/reference program studi | Berhasil dibuat |
| 2 | `src.semester` | Reference periode akademik | Berhasil dibuat |
| 3 | `src.mahasiswa` | Master mahasiswa | Berhasil dibuat |
| 4 | `src.dosen` | Master dosen | Berhasil dibuat |
| 5 | `src.mata_kuliah` | Master/reference mata kuliah | Berhasil dibuat |
| 6 | `src.krs` | Transaksi pengambilan mata kuliah | Berhasil dibuat |
| 7 | `src.nilai` | Hasil penilaian akademik | Berhasil dibuat |
| 8 | `src.aktivitas_lms` | Aktivitas mahasiswa pada LMS | Berhasil dibuat |
| 9 | `src.pembayaran` | Transaksi pembayaran | Berhasil dibuat |
| 10 | `src.kelulusan` | Data outcome kelulusan | Berhasil dibuat |

### 2.1 Membuat schema dan tabel

Tuliskan atau lampirkan DDL yang digunakan untuk membuat schema dan sepuluh tabel pada schema `src`. Struktur kolom harus mengikuti spesifikasi pada bahan praktikum.

**Script DDL yang digunakan:**

```sql
CREATE SCHEMA IF NOT EXISTS src;

-- Struktur kolom mengikuti Source Inventory Workbook Unit 1.1 (kolom real CSV UADW v1.0).
-- Urutan kolom sama dengan header CSV. Seluruh kolom disimpan TEXT agar nilai
-- mentah tidak berubah saat impor (angkatan, tanggal, dan nilai dikonversi saat query).

CREATE TABLE IF NOT EXISTS src.program_studi (  -- 5 kolom
    kode_prodi         TEXT,
    nama_prodi         TEXT,
    fakultas           TEXT,
    departemen         TEXT,
    status             TEXT
);

CREATE TABLE IF NOT EXISTS src.semester (  -- 6 kolom
    semester_id        TEXT,
    tahun_akademik     TEXT,
    term               TEXT,
    urutan_tahun       TEXT,
    tanggal_mulai      TEXT,
    tanggal_selesai    TEXT
);

CREATE TABLE IF NOT EXISTS src.mahasiswa (  -- 11 kolom
    nim                TEXT,
    nama               TEXT,
    jk_raw             TEXT,
    tanggal_lahir_raw  TEXT,
    kota_asal_raw      TEXT,
    kode_prodi_raw     TEXT,
    prodi_raw          TEXT,
    angkatan           TEXT,
    tanggal_masuk_raw  TEXT,
    status_raw         TEXT,
    email_kampus       TEXT
);

CREATE TABLE IF NOT EXISTS src.dosen (  -- 7 kolom
    nidn               TEXT,
    nama_dosen         TEXT,
    jk_raw             TEXT,
    unit_prodi_raw     TEXT,
    jabatan_akademik   TEXT,
    tanggal_masuk_raw  TEXT,
    status             TEXT
);

CREATE TABLE IF NOT EXISTS src.mata_kuliah (  -- 7 kolom
    kode_mk            TEXT,
    nama_mk            TEXT,
    kode_prodi         TEXT,
    sks                TEXT,
    semester_rekomendasi TEXT,
    kategori           TEXT,
    aktif              TEXT
);

CREATE TABLE IF NOT EXISTS src.krs (  -- 8 kolom
    krs_id             TEXT,
    nim                TEXT,
    kode_mk            TEXT,
    semester_id        TEXT,
    kelas              TEXT,
    status_krs         TEXT,
    tanggal_ambil_raw  TEXT,
    sumber_sistem      TEXT
);

CREATE TABLE IF NOT EXISTS src.nilai (  -- 8 kolom
    nilai_id           TEXT,
    nim                TEXT,
    kode_mk            TEXT,
    semester_id        TEXT,
    nilai_angka        TEXT,
    nilai_huruf        TEXT,
    status_lulus       TEXT,
    tanggal_input_raw  TEXT
);

CREATE TABLE IF NOT EXISTS src.aktivitas_lms (  -- 9 kolom
    lms_event_id       TEXT,
    nim                TEXT,
    kode_mk            TEXT,
    semester_id        TEXT,
    waktu_event        TEXT,
    tipe_event         TEXT,
    durasi_menit       TEXT,
    skor_kuis          TEXT,
    platform           TEXT
);

CREATE TABLE IF NOT EXISTS src.pembayaran (  -- 8 kolom
    pembayaran_id      TEXT,
    nim                TEXT,
    semester_id        TEXT,
    tanggal_bayar_raw  TEXT,
    nominal_tagihan    TEXT,
    nominal_bayar      TEXT,
    status_pembayaran  TEXT,
    kanal              TEXT
);

CREATE TABLE IF NOT EXISTS src.kelulusan (  -- 7 kolom
    kelulusan_id       TEXT,
    nim                TEXT,
    tanggal_lulus_raw  TEXT,
    ipk_final          TEXT,
    masa_studi_bulan   TEXT,
    predikat           TEXT,
    status_tepat_waktu TEXT
);
```

**Bukti eksekusi / hasil:**


**Catatan:** Perintah `DROP TABLE` dapat menghapus tabel beserta isinya. Gunakan hanya apabila memang diperlukan dalam persiapan praktikum dan pastikan tidak menghapus data yang masih dibutuhkan.

**Interpretasi:**

Schema `src` dan sepuluh tabel sumber dibuat dengan struktur sesuai bahan praktikum. Seluruh kolom raw disimpan sebagai teks agar nilai mentah tidak berubah saat impor. Hasil verifikasi pada bagian 4 sampai 7 menunjukkan sepuluh tabel tersedia dengan jumlah baris dan kolom yang sesuai acuan, sehingga source layer siap dipakai.

---

## 3. Mengimpor/Mengakses Raw Source

Dataset UADW v1.0 terdiri atas sepuluh file CSV. Data dimuat ke tabel yang sesuai dengan mempertahankan nilai raw, tanpa cleaning, standardisasi, atau deduplikasi.

### 3.1 Perintah impor CSV

Sesuaikan `/PATH/UADW_v1.0/` dengan lokasi dataset pada komputer masing-masing.

```sql
\copy src.program_studi FROM '/PATH/UADW_v1.0/01_raw_data/program_studi.csv' CSV HEADER ENCODING 'UTF8';
\copy src.semester      FROM '/PATH/UADW_v1.0/01_raw_data/semester.csv'      CSV HEADER ENCODING 'UTF8';
\copy src.mahasiswa     FROM '/PATH/UADW_v1.0/01_raw_data/mahasiswa.csv'     CSV HEADER ENCODING 'UTF8';
\copy src.dosen         FROM '/PATH/UADW_v1.0/01_raw_data/dosen.csv'         CSV HEADER ENCODING 'UTF8';
\copy src.mata_kuliah   FROM '/PATH/UADW_v1.0/01_raw_data/mata_kuliah.csv'   CSV HEADER ENCODING 'UTF8';
\copy src.krs           FROM '/PATH/UADW_v1.0/01_raw_data/krs.csv'           CSV HEADER ENCODING 'UTF8';
\copy src.nilai         FROM '/PATH/UADW_v1.0/01_raw_data/nilai.csv'         CSV HEADER ENCODING 'UTF8';
\copy src.aktivitas_lms FROM '/PATH/UADW_v1.0/01_raw_data/aktivitas_lms.csv' CSV HEADER ENCODING 'UTF8';
\copy src.pembayaran    FROM '/PATH/UADW_v1.0/01_raw_data/pembayaran.csv'    CSV HEADER ENCODING 'UTF8';
\copy src.kelulusan     FROM '/PATH/UADW_v1.0/01_raw_data/kelulusan.csv'     CSV HEADER ENCODING 'UTF8';
```

### 3.2 Catatan proses impor

| No. | File CSV | Tabel tujuan | Status impor | Jumlah baris yang dilaporkan saat impor | Catatan/error |
|---:|---|---|---|---:|---|
| 1 | `program_studi.csv` | `src.program_studi` | Berhasil | 6 | Tidak ada error |
| 2 | `semester.csv` | `src.semester` | Berhasil | 8 | Tidak ada error |
| 3 | `mahasiswa.csv` | `src.mahasiswa` | Berhasil | 1.965 | Tidak ada error |
| 4 | `dosen.csv` | `src.dosen` | Berhasil | 96 | Tidak ada error |
| 5 | `mata_kuliah.csv` | `src.mata_kuliah` | Berhasil | 208 | Tidak ada error |
| 6 | `krs.csv` | `src.krs` | Berhasil | 57.025 | Tidak ada error |
| 7 | `nilai.csv` | `src.nilai` | Berhasil | 57.000 | Tidak ada error |
| 8 | `aktivitas_lms.csv` | `src.aktivitas_lms` | Berhasil | 200.356 | Tidak ada error |
| 9 | `pembayaran.csv` | `src.pembayaran` | Berhasil | 9.500 | Tidak ada error |
| 10 | `kelulusan.csv` | `src.kelulusan` | Berhasil | 347 | Tidak ada error |

**Bukti proses impor:**


**Interpretasi:** Seluruh sepuluh file CSV berhasil dimuat ke tabel yang sesuai. Keberhasilan dipastikan dengan membandingkan jumlah baris tiap tabel setelah impor dengan jumlah acuan pada bahan praktikum (bagian 6): seluruhnya sama. Nilai raw dipertahankan karena kolom disimpan sebagai teks, impor memakai header dan encoding UTF-8, dan tidak ada `UPDATE`, `DELETE`, standardisasi, atau deduplikasi sesudah impor. Duplikat yang ditemukan pada bagian berikutnya merupakan isi asli file sumber.

---

## 4. Menginventarisasi Tabel pada Schema `src`

Aktivitas ini bertujuan mengetahui seluruh *base table* yang tersedia pada schema `src` setelah proses pembuatan dan pemuatan data.

**Query SQL:**

```sql
SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'src'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

**Hasil eksekusi:**

| table_schema | table_name |
|---|---|
| src | aktivitas_lms |
| src | dosen |
| src | kelulusan |
| src | krs |
| src | mahasiswa |
| src | mata_kuliah |
| src | nilai |
| src | pembayaran |
| src | program_studi |
| src | semester |

**Interpretasi:**

Schema `src` memuat tepat sepuluh *base table* yang diharapkan, terurut berdasarkan nama tabel. Tidak ada tabel yang kurang maupun berlebih, sehingga struktur source layer lengkap.

---

## 5. Verifikasi Jumlah Baris Lima Source Awal

Lima tabel master/reference awal yang diverifikasi adalah `program_studi`, `semester`, `mahasiswa`, `dosen`, dan `mata_kuliah`.

**Query SQL:**

```sql
SELECT 'program_studi' AS tabel, COUNT(*) AS jumlah_baris
FROM src.program_studi
UNION ALL
SELECT 'semester', COUNT(*) FROM src.semester
UNION ALL
SELECT 'mahasiswa', COUNT(*) FROM src.mahasiswa
UNION ALL
SELECT 'dosen', COUNT(*) FROM src.dosen
UNION ALL
SELECT 'mata_kuliah', COUNT(*) FROM src.mata_kuliah
ORDER BY tabel;
```

**Hasil eksekusi:**

| tabel | jumlah_baris |
|---|---:|
| `dosen` | 96 |
| `mahasiswa` | 1.965 |
| `mata_kuliah` | 208 |
| `program_studi` | 6 |
| `semester` | 8 |

**Interpretasi:** Jumlah baris aktual sama dengan jumlah acuan (6, 8, 1.965, 96, dan 208), sehingga tidak ada selisih yang perlu dijelaskan. Tabel `mahasiswa` merupakan tabel master terbesar pada kelompok ini, sedangkan `program_studi` dan `semester` adalah tabel referensi yang kecil.

---

## 6. Verifikasi Jumlah Baris Seluruh Sepuluh Source

Aktivitas ini memeriksa jumlah baris pada seluruh tabel sumber di schema `src`.

**Query SQL:**

```sql
SELECT 'program_studi' AS tabel, COUNT(*) AS jumlah_baris FROM src.program_studi
UNION ALL SELECT 'semester', COUNT(*) FROM src.semester
UNION ALL SELECT 'mahasiswa', COUNT(*) FROM src.mahasiswa
UNION ALL SELECT 'dosen', COUNT(*) FROM src.dosen
UNION ALL SELECT 'mata_kuliah', COUNT(*) FROM src.mata_kuliah
UNION ALL SELECT 'krs', COUNT(*) FROM src.krs
UNION ALL SELECT 'nilai', COUNT(*) FROM src.nilai
UNION ALL SELECT 'aktivitas_lms', COUNT(*) FROM src.aktivitas_lms
UNION ALL SELECT 'pembayaran', COUNT(*) FROM src.pembayaran
UNION ALL SELECT 'kelulusan', COUNT(*) FROM src.kelulusan
ORDER BY tabel;
```

**Hasil eksekusi:**

| Dataset | Jumlah baris aktual | Jumlah baris acuan (bila tersedia) | Status/catatan |
|---|---:|---:|---|
| `program_studi` | 6 | 6 | Sesuai |
| `semester` | 8 | 8 | Sesuai |
| `mahasiswa` | 1.965 | 1.965 | Sesuai |
| `dosen` | 96 | 96 | Sesuai |
| `mata_kuliah` | 208 | 208 | Sesuai |
| `krs` | 57.025 | 57.025 | Sesuai |
| `nilai` | 57.000 | 57.000 | Sesuai |
| `aktivitas_lms` | 200.356 | 200.356 | Sesuai |
| `pembayaran` | 9.500 | 9.500 | Sesuai |
| `kelulusan` | 347 | 347 | Sesuai |

**Interpretasi:** Seluruh sepuluh tabel memiliki jumlah baris yang sama dengan nilai acuan, sehingga pemuatan dataset dinyatakan lengkap tanpa baris yang hilang atau berlebih. Total seluruh tabel 326.511 baris. Selisih 25 baris antara `krs` (57.025) dan `nilai` (57.000) bukan kesalahan impor, melainkan karakteristik data sumber yang dianalisis pada Unit 1.2.

---

## 7. Verifikasi Jumlah Kolom Seluruh Source

Aktivitas ini bertujuan mengetahui jumlah kolom pada setiap tabel dalam schema `src`.

**Query SQL:**

```sql
SELECT
    table_name,
    COUNT(*) AS jumlah_kolom
FROM information_schema.columns
WHERE table_schema = 'src'
GROUP BY table_name
ORDER BY table_name;
```

**Hasil eksekusi:**

| table_name | jumlah_kolom |
|---|---:|
| `aktivitas_lms` | 9 |
| `dosen` | 7 |
| `kelulusan` | 7 |
| `krs` | 8 |
| `mahasiswa` | 11 |
| `mata_kuliah` | 7 |
| `nilai` | 8 |
| `pembayaran` | 8 |
| `program_studi` | 5 |
| `semester` | 6 |

**Interpretasi:**

Jumlah kolom berkisar antara 5 dan 11. `mahasiswa` memiliki kolom terbanyak (11) karena memuat atribut deskriptif, sedangkan `program_studi` paling sedikit (5). Tabel transaksi memiliki 7–9 kolom. Jumlah kolom ini sesuai dengan struktur source pada bahan praktikum.

---

## 8. Verifikasi Struktur Kolom Tabel Mahasiswa

Pemeriksaan dilakukan pada tabel `src.mahasiswa` untuk mengetahui urutan kolom, nama kolom, dan tipe data.

**Query SQL:**

```sql
SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'src'
  AND table_name = 'mahasiswa'
ORDER BY ordinal_position;
```

**Hasil eksekusi:**

| ordinal_position | column_name | data_type |
|---:|---|---|
| 1 | nim | text |
| 2 | nama | text |
| 3 | jk_raw | text |
| 4 | tanggal_lahir_raw | text |
| 5 | kota_asal_raw | text |
| 6 | kode_prodi_raw | text |
| 7 | prodi_raw | text |
| 8 | angkatan | text |
| 9 | tanggal_masuk_raw | text |
| 10 | status_raw | text |
| 11 | email_kampus | text |

**Interpretasi:** Tabel `mahasiswa` memiliki 11 kolom. Seluruh kolom bertipe teks karena disimpan sebagai data mentah, termasuk kolom tanggal (`tanggal_lahir_raw`, `tanggal_masuk_raw`) dan `angkatan`, sehingga diperlukan konversi tipe data sebelum dihitung (seperti pada bagian 10). Kolom bertanda `_raw` menyimpan nilai mentah yang belum distandardisasi. Struktur dan urutan kolom sesuai dengan definisi source pada bahan praktikum.

---

## 9. Verifikasi Candidate Key Mahasiswa

NIM merupakan *candidate natural key* secara bisnis untuk mengidentifikasi mahasiswa. Keunikan NIM perlu diperiksa sebelum digunakan sebagai key.

**Query SQL:**

```sql
SELECT
    COUNT(*) AS raw_rows,
    COUNT(DISTINCT nim) AS distinct_nim,
    COUNT(*) - COUNT(DISTINCT nim) AS excess_duplicate_rows
FROM src.mahasiswa;
```

**Hasil eksekusi:**

| raw_rows | distinct_nim | excess_duplicate_rows |
|---:|---:|---:|
| 1.965 | 1.950 | 15 |

**Analisis:**

- Apakah jumlah seluruh baris sama dengan jumlah NIM unik? **Tidak.** 1.965 baris berbanding 1.950 NIM unik.
- Apakah terdapat indikasi NIM duplikat? **Ya**, terdapat 15 baris berlebih (15 NIM muncul 2 kali).
- Apakah hasil ini sudah cukup untuk memutuskan penghapusan record? **Belum.** Hasil ini hanya membuktikan adanya NIM ganda; penyebabnya (duplikat persis atau data historis) harus diperiksa dulu.

**Interpretasi:**

NIM belum terbukti unik pada data mentah. Pemeriksaan lanjutan pada Unit 1.2 menunjukkan bahwa seluruh kolom pada baris ganda identik dan baris tersebut berada di akhir file, sehingga mengarah pada duplikat persis, bukan perubahan historis. Meski begitu, tidak ada record yang dihapus pada Unit 1.1.

---

## 10. Mengetahui Rentang Angkatan Mahasiswa

Aktivitas ini bertujuan mengetahui tahun angkatan paling awal dan paling akhir yang tercatat pada tabel mahasiswa. Kolom `angkatan` disimpan sebagai teks sehingga dikonversi ke tipe integer sebelum dihitung.

**Query SQL:**

```sql
SELECT
    MIN(CAST(angkatan AS INTEGER)) AS angkatan_min,
    MAX(CAST(angkatan AS INTEGER)) AS angkatan_max
FROM src.mahasiswa;
```

**Hasil eksekusi:**

| angkatan_min | angkatan_max |
|---:|---:|
| 2021 | 2024 |

**Interpretasi:** Dataset mencakup empat angkatan, yaitu 2021 sampai 2024. Pemeriksaan tahun pada tanggal masuk menunjukkan tahun masuk sama dengan angkatan pada seluruh baris. Rentang ini sesuai dengan cakupan semester 2021G–2024E pada tabel `semester`.

---

## 11. Memeriksa Data Kota Asal yang Kosong

Pemeriksaan dilakukan untuk mengetahui jumlah record mahasiswa yang tidak memiliki informasi kota asal pada kolom `kota_asal_raw`.

**Query SQL:**

```sql
SELECT COUNT(*) AS missing_kota
FROM src.mahasiswa
WHERE TRIM(COALESCE(kota_asal_raw, '')) = '';
```

**Hasil eksekusi:**

| missing_kota |
|---:|
| 30 |

**Interpretasi:** Terdapat 30 record mahasiswa (sekitar 1,53%) tanpa kota asal. Dampaknya, analisis persebaran daerah asal mahasiswa akan kehilangan 30 mahasiswa, sehingga perlu dikelompokkan sebagai "tidak diketahui" dan bukan ditebak.

---

## 12. Menghitung Variasi Label Program Studi pada Mahasiswa

Pemeriksaan awal dilakukan untuk mengetahui jumlah variasi nilai pada kolom `prodi_raw`.

**Query SQL:**

```sql
SELECT COUNT(DISTINCT prodi_raw) AS distinct_prodi_raw
FROM src.mahasiswa;
```

**Hasil eksekusi:**

| distinct_prodi_raw |
|---:|
| 30 |

**Interpretasi:** Terdapat 30 label `prodi_raw`, sedangkan program studi resmi hanya 6. Jadi jumlah variasi tidak sama dengan jumlah program studi resmi. Selisih 24 label menunjukkan satu program studi ditulis dengan beberapa cara (singkatan, kapitalisasi, ejaan).

---

## 13. Menghitung Jumlah Program Studi pada Tabel Referensi

Tabel `src.program_studi` digunakan sebagai referensi program studi. Jumlah record pada tabel referensi dihitung untuk dibandingkan dengan variasi label pada `prodi_raw`.

**Query SQL:**

```sql
SELECT COUNT(*) AS canonical_programs
FROM src.program_studi;
```

**Hasil eksekusi:**

| canonical_programs |
|---:|
| 6 |

**Perbandingan:**

| Keterangan | Jumlah |
|---|---:|
| Variasi label `prodi_raw` | 30 |
| Record pada `src.program_studi` | 6 |

**Interpretasi:** Tabel referensi hanya berisi 6 program studi, sedangkan data mahasiswa memakai 30 label. Hal ini menjadi indikasi kuat adanya variasi representasi nama program studi pada data mahasiswa (24 label varian pada 435 baris), yang perlu dipetakan ke tabel referensi pada tahap standardisasi.

---

## 14. Menampilkan Distribusi Label Program Studi Mentah

Pemeriksaan ini bertujuan mengetahui frekuensi kemunculan setiap label program studi pada kolom `prodi_raw`.

**Query SQL:**

```sql
SELECT
    prodi_raw,
    COUNT(*) AS jumlah
FROM src.mahasiswa
GROUP BY prodi_raw
ORDER BY prodi_raw;
```

**Hasil eksekusi:**

| Kelompok label `prodi_raw` | Jumlah label | jumlah (baris) |
|---|---:|---:|
| Sama persis dengan nama program studi resmi | 6 | 1.530 |
| Varian penulisan | 24 | 435 |
| **Total** | **30** | **1.965** |

Contoh varian: `TI`, `Tek. Informasi`, `TEKNOLOGI INFORMASI`, `Teknologi informasi`, `IF`, `TRK`, `Data Science`. (Daftar lengkap 30 baris hasil query ada pada lampiran tangkapan layar.)

**Interpretasi:** Label resmi mendominasi (1.530 baris, 77,86%), tetapi 435 baris (22,14%) memakai 24 variasi penulisan yang perlu diperiksa lebih lanjut dan dipetakan ke `kode_prodi`. Seluruh variasi tetap dicatat apa adanya tanpa diubah.

---

## 15. Menampilkan Variasi Label Jenis Kelamin

Pemeriksaan dilakukan untuk mengetahui variasi representasi jenis kelamin pada kolom `jk_raw`.

**Query SQL:**

```sql
SELECT
    jk_raw,
    COUNT(*) AS jumlah
FROM src.mahasiswa
GROUP BY jk_raw
ORDER BY jk_raw;
```

**Hasil eksekusi:**

| jk_raw | jumlah |
|---|---:|
| F | 39 |
| L | 764 |
| Laki-laki | 162 |
| M | 53 |
| P | 764 |
| Perempuan | 183 |

**Interpretasi:** Ditemukan 6 label untuk 2 konsep jenis kelamin: `L`, `Laki-laki`, `M` untuk laki-laki dan `P`, `Perempuan`, `F` untuk perempuan (arti `M`/`F` perlu dikonfirmasi). Sebanyak 437 baris (22,24%) tidak memakai kode `L`/`P`. Standardisasi diperlukan pada tahap berikutnya.

---

## 16. Menampilkan Sampel Record Tabel Mahasiswa

Sampel record digunakan untuk memahami bentuk data dan nilai pada setiap kolom. Pemeriksaan dibatasi pada lima baris.

**Query SQL:**

```sql
SELECT *
FROM src.mahasiswa
LIMIT 5;
```

**Hasil eksekusi:**


**Interpretasi:** Sampel lima baris memperlihatkan bentuk data mahasiswa: NIM berpola dua digit angkatan, kode program studi, dan nomor urut; kolom `_raw` menyimpan teks mentah; email kampus mengikuti NIM. Lima baris belum cukup untuk menyimpulkan kualitas dataset karena masalah seperti duplikat (15 baris), label bervariasi (435 baris), dan kota kosong (30 baris) hanya tampak bila seluruh 1.965 baris diperiksa.

---

## 17. Mengidentifikasi Source dengan Jumlah Baris Terbesar

Aktivitas ini bertujuan membandingkan ukuran seluruh tabel berdasarkan jumlah baris, kemudian menentukan source dengan jumlah record terbanyak.

**Query SQL:**

```sql
SELECT 'program_studi' AS source, COUNT(*) AS rows FROM src.program_studi
UNION ALL SELECT 'semester', COUNT(*) FROM src.semester
UNION ALL SELECT 'mahasiswa', COUNT(*) FROM src.mahasiswa
UNION ALL SELECT 'dosen', COUNT(*) FROM src.dosen
UNION ALL SELECT 'mata_kuliah', COUNT(*) FROM src.mata_kuliah
UNION ALL SELECT 'krs', COUNT(*) FROM src.krs
UNION ALL SELECT 'nilai', COUNT(*) FROM src.nilai
UNION ALL SELECT 'aktivitas_lms', COUNT(*) FROM src.aktivitas_lms
UNION ALL SELECT 'pembayaran', COUNT(*) FROM src.pembayaran
UNION ALL SELECT 'kelulusan', COUNT(*) FROM src.kelulusan
ORDER BY rows DESC;
```

**Hasil eksekusi:**

| source | rows |
|---|---:|
| aktivitas_lms | 200.356 |
| krs | 57.025 |
| nilai | 57.000 |
| pembayaran | 9.500 |
| mahasiswa | 1.965 |
| kelulusan | 347 |
| mata_kuliah | 208 |
| dosen | 96 |
| semester | 8 |
| program_studi | 6 |

**Source dengan jumlah baris terbanyak:** `aktivitas_lms`

**Jumlah baris:** 200.356

**Interpretasi:** `aktivitas_lms` adalah tabel terbesar (sekitar 61% dari total 326.511 baris) karena mencatat setiap event aktivitas mahasiswa. Informasi ukuran berguna untuk perencanaan pengolahan data: tabel besar membutuhkan waktu proses, indeks, dan strategi pemuatan yang lebih hati-hati, sedangkan tabel referensi kecil mudah dimuat dan diperiksa.

---

## 18. Mengidentifikasi Indikasi Relasi Mahasiswa dengan Tabel Transaksi

Kolom `nim` terdapat pada tabel mahasiswa dan beberapa tabel transaksi/aktivitas akademik. Query berikut membandingkan jumlah NIM berbeda pada masing-masing tabel transaksi.

**Query SQL:**

```sql
SELECT 'krs' AS source,
       COUNT(DISTINCT nim) AS distinct_nim
FROM src.krs
UNION ALL
SELECT 'nilai', COUNT(DISTINCT nim) FROM src.nilai
UNION ALL
SELECT 'aktivitas_lms', COUNT(DISTINCT nim) FROM src.aktivitas_lms
UNION ALL
SELECT 'pembayaran', COUNT(DISTINCT nim) FROM src.pembayaran
UNION ALL
SELECT 'kelulusan', COUNT(DISTINCT nim) FROM src.kelulusan;
```

**Hasil eksekusi:**

| source | distinct_nim |
|---|---:|
| `krs` | 1.950 |
| `nilai` | 1.950 |
| `aktivitas_lms` | 1.950 |
| `pembayaran` | 1.950 |
| `kelulusan` | 345 |

### 18.1 Catatan relasi awal

| Rel ID | Source A | Key A | Source B | Key B | Dugaan hubungan bisnis | Catatan/verifikasi lanjutan |
|---|---|---|---|---|---|---|
| REL01 | `mahasiswa` | `nim` | `krs` | `nim` | 1 mahasiswa : banyak KRS | 1.950 NIM unik pada KRS; tidak ada NIM KRS yang tidak terdaftar; perlu dedup 25 baris KRS |
| REL02 | `mahasiswa` | `nim` | `nilai` | `nim` | 1 mahasiswa : banyak nilai | Kombinasi NIM–MK–semester pada nilai sama persis dengan KRS (57.000); tidak ada NIM nilai yang tidak terdaftar |
| REL03 | `mahasiswa` | `nim` | `aktivitas_lms` | `nim` | 1 mahasiswa : banyak aktivitas LMS | Tidak ada NIM LMS yang tidak terdaftar; perlu dedup 30 event |
| REL04 | `mahasiswa` | `nim` | `pembayaran` | `nim` | 1 mahasiswa : banyak pembayaran | Satu baris per NIM–semester; tidak ada NIM yang tidak terdaftar |
| REL05 | `mahasiswa` | `nim` | `kelulusan` | `nim` | 1 mahasiswa : 0/1 outcome kelulusan secara bisnis | 345 NIM lulusan sama dengan mahasiswa berstatus Lulus; ada 2 baris kelulusan ganda |

**Interpretasi:** Kolom `nim` muncul pada kelima tabel transaksi dan menjadi kandidat kunci penghubung ke `mahasiswa`. Secara bisnis, satu mahasiswa dapat memiliki banyak KRS, nilai, aktivitas LMS, dan pembayaran, tetapi paling banyak satu kelulusan. Kesamaan nama kolom dan jumlah NIM berbeda belum membuktikan integritas referensial: pembuktian membutuhkan pemeriksaan *orphan key* (yang dilakukan pada Unit 1.2 dan menghasilkan 0 orphan), disertai penanganan NIM ganda pada tabel mahasiswa agar join tidak menggandakan baris.

---

## 19. Ringkasan Hasil Initial Profiling

Lengkapi tabel berikut berdasarkan hasil seluruh aktivitas Unit 1.1.

| No. | Aspek yang diperiksa | Temuan berdasarkan hasil query | Tindak lanjut yang disarankan |
|---:|---|---|---|
| 1 | Kesiapan environment PostgreSQL | PostgreSQL dan schema `src` dapat diakses melalui DBeaver | Cantumkan versi dan user pada lampiran |
| 2 | Ketersediaan schema dan tabel | Schema `src` dan 10 tabel tersedia | Tidak ada tindak lanjut |
| 3 | Keberhasilan impor dataset | 10 file CSV termuat; jumlah baris sama dengan acuan | Pertahankan raw data apa adanya |
| 4 | Jumlah baris setiap source | Total 326.511 baris; seluruhnya sesuai acuan | Tidak ada |
| 5 | Jumlah kolom setiap source | 5 sampai 11 kolom per tabel | Tidak ada |
| 6 | Keunikan NIM mahasiswa | 1.965 baris vs 1.950 NIM unik (15 berlebih) | Periksa penyebab; tetapkan aturan deduplikasi pada cleaning |
| 7 | Rentang angkatan | 2021 sampai 2024 | Tidak ada |
| 8 | Kelengkapan kota asal | 30 baris kosong (1,53%) | Tandai sebagai tidak diketahui |
| 9 | Variasi label program studi | 30 label untuk 6 prodi (435 baris varian) | Susun pemetaan ke `kode_prodi` |
| 10 | Variasi label jenis kelamin | 6 label untuk 2 konsep (437 baris bukan L/P) | Konfirmasi arti M/F dan standardisasi |
| 11 | Ukuran source terbesar | `aktivitas_lms` 200.356 baris | Rencanakan pemuatan data besar |
| 12 | Indikasi relasi antartabel | `nim` muncul pada 5 tabel transaksi | Verifikasi integritas referensial (Unit 1.2: 0 orphan) |

---

## 20. Kesimpulan

Tuliskan kesimpulan berdasarkan hasil praktikum Unit 1.1. Kesimpulan sekurang-kurangnya mencakup:

1. Kesiapan environment dan keberhasilan pembuatan source layer.
2. Keberhasilan pemuatan sepuluh dataset raw.
3. Hasil verifikasi jumlah baris dan kolom source.
4. Karakteristik awal data mahasiswa yang ditemukan, seperti indikasi duplikasi, nilai kosong, dan variasi label.
5. Gambaran awal relasi antartabel yang perlu diverifikasi lebih lanjut.
6. Hal-hal yang akan menjadi fokus pemeriksaan pada unit praktikum berikutnya.

**Kesimpulan:**

Source layer pada schema `src` siap dipakai: sepuluh tabel berhasil dibuat dan sepuluh file CSV berhasil dimuat dengan jumlah baris yang sama dengan acuan (total 326.511 baris) serta jumlah kolom 5–11 per tabel. Nilai raw dipertahankan tanpa cleaning, standardisasi, `UPDATE`, atau `DELETE`.

*Initial profiling* tabel mahasiswa menunjukkan: NIM belum terbukti unik (1.965 baris vs 1.950 NIM unik, 15 baris berlebih); angkatan mencakup 2021–2024; 30 baris kota asal kosong; 30 label program studi untuk 6 program studi resmi; dan 6 label jenis kelamin untuk 2 konsep (437 baris bukan L/P). Seluruh temuan dicatat untuk dianalisis, bukan diperbaiki, pada unit ini.

Tabel terbesar adalah `aktivitas_lms` (200.356 baris). Kolom `nim` pada lima tabel transaksi mengindikasikan relasi 1 mahasiswa : banyak transaksi (dan 0/1 kelulusan), tetapi integritas referensial baru dapat dinyatakan setelah pemeriksaan *orphan key*. Fokus Unit 1.2 adalah profiling kualitas data lebih lengkap: duplikasi, kelengkapan, validitas, konsistensi, dan integritas referensial.

---

## Lampiran Bukti Praktikum

Lampirkan bukti yang relevan dan terbaca, antara lain:

- [ ] Koneksi PostgreSQL dan informasi versi.
- [ ] Schema `src` dan daftar sepuluh tabel.
- [ ] Proses impor sepuluh file CSV.
- [ ] Hasil query verifikasi row count dan column count.
- [ ] Hasil query initial profiling mahasiswa.
- [ ] Hasil query ukuran source dan relasi awal.
- [ ] Bukti tambahan apabila terdapat kendala atau perbedaan hasil.

## Pernyataan Integritas Data

Saya menyatakan bahwa pada pelaksanaan Unit 1.1, pemeriksaan dilakukan terhadap raw source untuk keperluan persiapan dan *initial profiling*. Saya tidak melakukan cleaning, standardisasi, deduplikasi, `UPDATE`, atau `DELETE` terhadap isi raw source.

| Nama Mahasiswa | Tanggal | Tanda Tangan |
|---|---|---|
|  |  |  |
