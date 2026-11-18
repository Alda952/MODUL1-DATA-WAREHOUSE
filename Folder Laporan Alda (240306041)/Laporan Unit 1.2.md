# LAPORAN MODUL 1 UNIT 1.2

# DATA PROFILING DAN DATA QUALITY ASSESSMENT

## Identitas Laporan

Nama       : Alda Syafitri  
NIM        : [240306041]  
Program Studi : [Teknologi Informasi]  
Modul      : 1  
Unit       : 1.2    
DBMS       : PostgreSQL  
Database   : uadw_lab  
Schema     : `src`

---

## Tujuan Praktikum

Setelah menyelesaikan praktikum ini, mahasiswa diharapkan mampu:

1. Melakukan profiling terhadap struktur dan ukuran dataset akademik.
2. Memeriksa kualitas data berdasarkan aspek *uniqueness*, *completeness*, *validity*, dan *consistency*.
3. Mengidentifikasi indikasi duplikasi pada tabel master maupun transaksi.
4. Memeriksa keterhubungan data antar-tabel (*referential integrity*).
5. Menyusun interpretasi berdasarkan hasil eksekusi query SQL tanpa langsung mengubah data sumber.

## Ketentuan Pengerjaan

1. Gunakan PostgreSQL dan schema `src`.
2. Gunakan dataset UADW v1.0 yang disediakan pada praktikum.
3. Pertahankan data pada source layer dalam kondisi aslinya (*raw data*).
4. Praktikum ini berfokus pada pemeriksaan. Jangan melakukan `UPDATE`, `DELETE`, deduplikasi, atau standardisasi langsung pada tabel `src`.
5. Tempelkan query yang benar-benar dijalankan. Query boleh disesuaikan selama menghasilkan pemeriksaan yang diminta.
6. Sertakan hasil eksekusi. Untuk hasil berbentuk tabel, salin tabel hasil atau lampirkan tangkapan layar yang terbaca.
7. Interpretasi harus sesuai dengan hasil aktual. Jangan mengarang hasil atau menyimpulkan bahwa data harus dihapus hanya karena terindikasi duplikat.
8. Apabila query menghasilkan nol baris atau nilai 0, tuliskan maknanya dalam interpretasi.

---

# 1. Menyiapkan dan Memverifikasi Environment Praktikum

Pastikan perangkat kerja dan koneksi database tersedia sebelum melakukan profiling.

### 1.1 Memeriksa versi PostgreSQL

```sql
-- Jalankan query pemeriksaan versi PostgreSQL
select version();
```

**Hasil eksekusi:**

PostgreSQL 18.6 on x86_64-windows

**Keterangan:**

[Isi versi PostgreSQL yang digunakan]

### 1.2 Memeriksa database dan user aktif

```sql
select
    current_database() as database_aktif,
    current_user as user_aktif;
```

**Hasil eksekusi:**

| database_aktif | user_aktif |
|---|---|
| uadw_lab | postgres |

**Keterangan:**

- Database aktif: [Isi hasil]
- User aktif: [Isi hasil]

### 1.3 Memastikan schema `src` tersedia

```sql
select schema_name
from information_schema.schemata
where schema_name = 'src';
```

**Hasil eksekusi:**

| schema_name |
|---|
| src |

**Keterangan:**

[Nyatakan apakah schema `src` ditemukan]

---

# 2. Profiling Struktur dan Ukuran Dataset

## 2.1 Soal 1 — Menghitung jumlah record setiap tabel

**Tujuan pemeriksaan**  
Mengetahui jumlah record pada sepuluh tabel sumber database akademik.

**Query SQL**

```sql
SELECT 'program_studi' AS dataset, COUNT(*) AS jumlah_record FROM src.program_studi
UNION ALL SELECT 'semester',      COUNT(*) FROM src.semester
UNION ALL SELECT 'mahasiswa',     COUNT(*) FROM src.mahasiswa
UNION ALL SELECT 'dosen',         COUNT(*) FROM src.dosen
UNION ALL SELECT 'mata_kuliah',   COUNT(*) FROM src.mata_kuliah
UNION ALL SELECT 'krs',           COUNT(*) FROM src.krs
UNION ALL SELECT 'nilai',         COUNT(*) FROM src.nilai
UNION ALL SELECT 'aktivitas_lms', COUNT(*) FROM src.aktivitas_lms
UNION ALL SELECT 'pembayaran',    COUNT(*) FROM src.pembayaran
UNION ALL SELECT 'kelulusan',     COUNT(*) FROM src.kelulusan;
```

**Hasil eksekusi**

| Dataset | Jumlah Record |
|---|---:|
| `program_studi` | 6 |
| `semester` | 8 |
| `mahasiswa` | 1.965 |
| `dosen` | 96 |
| `mata_kuliah` | 208 |
| `krs` | 57.025 |
| `nilai` | 57.000 |
| `aktivitas_lms` | 200.356 |
| `pembayaran` | 9.500 |
| `kelulusan` | 347 |

**Interpretasi**

Tabel terbesar adalah `aktivitas_lms` (200.356 record), disusul `krs` (57.025) dan `nilai` (57.000). Tabel terkecil adalah `program_studi` (6 record) dan `semester` (8 record). Total seluruh tabel 326.511 record. Seluruh jumlah sama dengan nilai acuan pada bahan praktikum. Selisih 25 record antara `krs` (57.025) dan `nilai` (57.000) menjadi petunjuk awal adanya duplikasi pada `krs`, yang diperiksa pada Soal 13–15.

## 2.2 Soal 2 — Menghitung jumlah kolom setiap tabel

**Tujuan pemeriksaan**  
Mengetahui jumlah kolom pada setiap tabel dalam schema `src`.

**Query SQL**

```sql
SELECT table_name AS nama_tabel, COUNT(*) AS jumlah_kolom
FROM information_schema.columns
WHERE table_schema = 'src'
GROUP BY table_name
ORDER BY table_name;
```

**Hasil eksekusi**

| Nama Tabel | Jumlah Kolom |
|---|---:|
| `program_studi` | 5 |
| `semester` | 6 |
| `mahasiswa` | 11 |
| `dosen` | 7 |
| `mata_kuliah` | 7 |
| `krs` | 8 |
| `nilai` | 8 |
| `aktivitas_lms` | 9 |
| `pembayaran` | 8 |
| `kelulusan` | 7 |

**Interpretasi**

Jumlah kolom berkisar antara 5 dan 11. Tabel `mahasiswa` memiliki kolom terbanyak (11) karena memuat atribut deskriptif mahasiswa, sedangkan `program_studi` paling sedikit (5). Tabel transaksi memiliki 7–9 kolom. Tidak ada tabel dengan jumlah kolom yang tidak wajar.

---

# 3. Profiling Tabel Mahasiswa

## 3.1 Soal 3 — Mengukur keunikan NIM

**Tujuan pemeriksaan**  
Mengetahui jumlah record mahasiswa, jumlah NIM unik, dan indikasi kelebihan record berdasarkan NIM.

**Query SQL**

```sql
SELECT COUNT(*) AS raw_rows,
       COUNT(DISTINCT nim) AS distinct_nim,
       COUNT(*) - COUNT(DISTINCT nim) AS excess_duplicate_rows
FROM src.mahasiswa;
```

**Hasil eksekusi**

| Raw Rows | Distinct NIM | Excess Duplicate Rows |
|---:|---:|---:|
| 1.965 | 1.950 | 15 |

**Interpretasi**

Jumlah record (1.965) lebih besar daripada jumlah NIM unik (1.950), sehingga terdapat 15 record berlebih. Ini adalah indikasi duplikasi pada `nim`, sehingga NIM belum terbukti unik pada data mentah. Karena itu NIM belum dapat langsung dipakai sebagai kunci tanpa pemeriksaan lanjutan. Pada tahap ini tidak dilakukan penghapusan record.

## 3.2 Soal 4 — Mengidentifikasi kelompok NIM duplikat

**Tujuan pemeriksaan**  
Menampilkan NIM yang muncul lebih dari satu kali beserta jumlah kemunculannya.

**Query SQL**

```sql
SELECT nim, COUNT(*) AS jumlah_kemunculan
FROM src.mahasiswa
GROUP BY nim
HAVING COUNT(*) > 1
ORDER BY jumlah_kemunculan DESC, nim;
```

**Hasil eksekusi**

15 NIM muncul lebih dari satu kali, masing-masing tepat 2 kali. Contoh:

| nim | jumlah_kemunculan |
|---|---:|
| 21TI0042 | 2 |
| 21IF0052 | 2 |
| 23DS0040 | 2 |
| ... (total 15 NIM) | 2 |

**Interpretasi**

- Jumlah kelompok NIM duplikat: 15
- Jumlah kemunculan tertinggi: 2
- Catatan/pola: seluruh kolom pada kedua baris untuk setiap NIM identik (bukan perubahan historis), dan baris ganda berada di bagian akhir file sumber sehingga menyerupai pengulangan saat ekstraksi atau impor.

Karena isinya persis sama, indikasi ini mengarah pada duplikat persis (*exact duplicate*), bukan data historis. Meskipun demikian, tindakan penghapusan belum dilakukan pada Unit ini dan ditetapkan sebagai aturan deduplikasi pada tahap *cleaning*.

## 3.3 Soal 5 — Memeriksa kelengkapan kota asal mahasiswa

**Tujuan pemeriksaan**  
Menghitung jumlah record dengan `kota_asal_raw` kosong, `NULL`, atau hanya berisi spasi.

**Query SQL**

```sql
SELECT COUNT(*) AS missing_kota
FROM src.mahasiswa
WHERE kota_asal_raw IS NULL OR TRIM(kota_asal_raw) = '';
```

**Hasil eksekusi**

| Missing Kota Asal |
|---:|
| 30 |

**Interpretasi**

Terdapat 30 record mahasiswa tanpa kota asal, atau sekitar 1,53% dari 1.965 record. Proporsinya kecil, tetapi analisis persebaran daerah asal akan kehilangan 30 mahasiswa. Nilai kosong ini sebaiknya diperlakukan sebagai "tidak diketahui" dan tidak ditebak. Contoh: NIM 21TI0022.

## 3.4 Soal 6 — Distribusi mahasiswa berdasarkan program studi mentah

**Tujuan pemeriksaan**  
Menampilkan frekuensi setiap label pada kolom `prodi_raw`.

**Query SQL**

```sql
SELECT prodi_raw, COUNT(*) AS frekuensi
FROM src.mahasiswa
GROUP BY prodi_raw
ORDER BY frekuensi DESC, prodi_raw;
```

**Hasil eksekusi**

Terdapat 30 label `prodi_raw` untuk 6 program studi. Ringkasan frekuensi:

| Kelompok label `prodi_raw` | Jumlah label | Frekuensi (record) |
|---|---:|---:|
| Sama persis dengan `nama_prodi` resmi | 6 | 1.530 |
| Varian penulisan (singkatan, kapitalisasi, ejaan) | 24 | 435 |
| **Total** | **30** | **1.965** |

Contoh varian: `TI`, `Tek. Informasi`, `TEKNOLOGI INFORMASI`, `Teknologi informasi`, `IF`, `TRK`, `Data Science`. (Daftar lengkap 30 label tersedia pada lampiran tangkapan layar.)

**Interpretasi**

Label resmi mendominasi (1.530 record, 77,86%), tetapi 435 record (22,14%) memakai 24 variasi penulisan untuk program studi yang sama. Akibatnya agregasi per program studi terpecah menjadi 30 kelompok, padahal hanya ada 6 program studi. Variasi ini perlu dipetakan ke `kode_prodi` pada tahap standardisasi.

## 3.5 Soal 7 — Menghitung variasi nama program studi

**Tujuan pemeriksaan**  
Menghitung jumlah nilai berbeda pada kolom `prodi_raw`.

**Query SQL**

```sql
SELECT COUNT(DISTINCT prodi_raw) AS distinct_raw_prodi
FROM src.mahasiswa;
```

**Hasil eksekusi**

| Jumlah Variasi `prodi_raw` |
|---:|
| 30 |

**Interpretasi**

Ada 30 nilai berbeda pada `prodi_raw`, sedangkan tabel referensi hanya memiliki 6 program studi. Selisih 24 label menunjukkan variasi penulisan nama program studi (singkatan, huruf besar/kecil, ejaan), sesuai dugaan pada soal.

## 3.6 Soal 8 — Distribusi jenis kelamin mahasiswa

**Tujuan pemeriksaan**  
Menampilkan setiap nilai `jk_raw` dan frekuensi kemunculannya.

**Query SQL**

```sql
SELECT jk_raw, COUNT(*) AS frekuensi
FROM src.mahasiswa
GROUP BY jk_raw
ORDER BY frekuensi DESC, jk_raw;
```

**Hasil eksekusi**

| jk_raw | Frekuensi |
|---|---:|
| L | 764 |
| P | 764 |
| Perempuan | 183 |
| Laki-laki | 162 |
| M | 53 |
| F | 39 |

**Interpretasi**

Terdapat 6 label untuk 2 konsep. Selain `L` dan `P`, terdapat `Laki-laki`, `Perempuan`, `M`, dan `F`; total 437 record (22,24%) tidak memakai kode `L`/`P`. Label `M`/`F` bergaya bahasa Inggris dan maknanya perlu dikonfirmasi ke pemilik data (kemungkinan *Male*/*Female*). Standardisasi dilakukan pada tahap berikutnya, bukan pada tabel raw.

## 3.7 Soal 9 — Distribusi status mahasiswa

**Tujuan pemeriksaan**  
Menampilkan variasi nilai `status_raw` dan jumlah record pada setiap status.

**Query SQL**

```sql
SELECT status_raw, COUNT(*) AS frekuensi
FROM src.mahasiswa
GROUP BY status_raw
ORDER BY frekuensi DESC, status_raw;
```

**Hasil eksekusi**

| status_raw | Frekuensi |
|---|---:|
| Aktif | 1.567 |
| Lulus | 348 |
| AKTIF | 18 |
| `Aktif ` (spasi di belakang) | 16 |
| cuti | 9 |
| Cuti | 7 |

**Interpretasi**

Ada 6 label untuk 3 status (Aktif, Lulus, Cuti). Sebanyak 43 record memakai varian kapitalisasi atau spasi tambahan. Tidak ada nilai kosong. Status `Lulus` tercatat 348 record, terdiri atas 345 mahasiswa unik dan 3 baris ganda; jumlah 345 sama dengan jumlah NIM pada tabel `kelulusan`.

## 3.8 Soal 10 — Distribusi kode program studi

**Tujuan pemeriksaan**  
Menampilkan nilai `kode_prodi_raw` dan frekuensi kemunculannya.

**Query SQL**

```sql
SELECT kode_prodi_raw, COUNT(*) AS frekuensi
FROM src.mahasiswa
GROUP BY kode_prodi_raw
ORDER BY frekuensi DESC, kode_prodi_raw;
```

**Hasil eksekusi**

Terdapat 24 label `kode_prodi_raw` untuk 6 kode program studi (TI, SI, IF, DS, TR, BD). Sebanyak 208 record (10,59%) tidak sama persis dengan `program_studi.kode_prodi`: memiliki spasi di depan (misalnya `' TI'`) atau huruf kecil (misalnya `ti`, `bd`).

**Interpretasi**

Setelah `UPPER(TRIM())`, seluruh kode cocok 100% dengan `program_studi` dan dengan segmen kode program studi pada NIM. Jadi masalahnya adalah format penulisan, bukan kode yang tidak dikenal. Join langsung ke tabel referensi akan gagal untuk 208 record sehingga perlu normalisasi pada tahap staging.

## 3.9 Soal 11 — Mengidentifikasi nama program studi yang tidak sesuai standar

**Tujuan pemeriksaan**  
Menghitung record mahasiswa dengan `prodi_raw` yang tidak memiliki kecocokan persis pada `program_studi.nama_prodi`.

**Query SQL**

```sql
SELECT COUNT(*) AS non_standard_prodi_rows
FROM src.mahasiswa m
WHERE NOT EXISTS (
    SELECT 1 FROM src.program_studi p
    WHERE p.nama_prodi = m.prodi_raw
);
```

**Hasil eksekusi**

| Non-standard Prodi Rows |
|---:|
| 435 |

**Interpretasi**

Sebanyak 435 record (22,14%) memiliki `prodi_raw` yang tidak ditemukan persis pada `program_studi.nama_prodi`. Angka ini sama dengan jumlah record yang memakai 24 label varian pada Soal 6. Ketidakcocokan bersumber dari singkatan, kapitalisasi, dan variasi ejaan, bukan dari program studi yang tidak dikenal. Penyebab pastinya dipastikan pada tahap pemetaan label.

## 3.10 Soal 12 — Mengidentifikasi variasi format tanggal masuk

**Tujuan pemeriksaan**  
Mengelompokkan `tanggal_masuk_raw` berdasarkan format `YYYY-MM-DD`, `DD/MM/YYYY`, `DD-Mon-YYYY`, dan `OTHER`.

**Query SQL**

```sql
SELECT CASE
         WHEN tanggal_masuk_raw ~ '^\d{4}-\d{2}-\d{2}$'        THEN 'YYYY-MM-DD'
         WHEN tanggal_masuk_raw ~ '^\d{2}/\d{2}/\d{4}$'        THEN 'DD/MM/YYYY'
         WHEN tanggal_masuk_raw ~ '^\d{2}-[A-Za-z]{3}-\d{4}$'  THEN 'DD-Mon-YYYY'
         ELSE 'OTHER'
       END AS format_tanggal,
       COUNT(*) AS jumlah_record
FROM src.mahasiswa
GROUP BY 1
ORDER BY jumlah_record DESC;
```

**Hasil eksekusi**

| Format Tanggal | Jumlah Record |
|---|---:|
| `YYYY-MM-DD` | 1.429 |
| `DD/MM/YYYY` | 346 |
| `DD-Mon-YYYY` | 190 |
| `OTHER` | 0 |

**Interpretasi**

Ditemukan tiga format tanggal masuk yang bercampur dalam satu kolom bertipe teks. Format `YYYY-MM-DD` paling banyak (1.429 record), sedangkan 536 record memakai format lain. Tidak ada record berkategori OTHER (0). Hasil ini baru memeriksa pola penulisan; kevalidan tanggal kalender belum dibuktikan, tetapi pemeriksaan lain menunjukkan tahun masuk sama dengan angkatan pada seluruh baris.

---

# 4. Profiling Tabel KRS

## 4.1 Soal 13 — Membandingkan jumlah record KRS dengan KRS unik

**Tujuan pemeriksaan**  
Membandingkan jumlah seluruh record KRS dengan jumlah `krs_id` yang unik.

**Query SQL**

```sql
SELECT COUNT(*) AS raw_rows, COUNT(DISTINCT krs_id) AS distinct_krs_id
FROM src.krs;
```

**Hasil eksekusi**

| Raw Rows | Distinct KRS ID |
|---:|---:|
| 57.025 | 57.000 |

**Interpretasi**

Jumlah record KRS (57.025) lebih besar daripada jumlah `krs_id` unik (57.000). Terdapat 25 record berlebih sebagai indikasi duplikasi berdasarkan `krs_id`.

## 4.2 Soal 14 — Mengidentifikasi duplikasi pengambilan mata kuliah

**Tujuan pemeriksaan**  
Menemukan kombinasi `nim`, `kode_mk`, dan `semester_id` yang muncul lebih dari satu kali pada tabel KRS.

**Query SQL**

```sql
SELECT nim, kode_mk, semester_id, COUNT(*) AS jumlah
FROM src.krs
GROUP BY nim, kode_mk, semester_id
HAVING COUNT(*) > 1
ORDER BY jumlah DESC, nim, kode_mk, semester_id;
```

**Hasil eksekusi**

25 kombinasi (`nim`, `kode_mk`, `semester_id`) muncul lebih dari satu kali, masing-masing 2 kali. Contoh `krs_id`: KRS0000025 dan KRS0000571.

**Interpretasi**

- Jumlah kombinasi yang terindikasi duplikat: 25
- Jumlah kemunculan tertinggi: 2
- Catatan: 25 `krs_id` duplikat sekaligus 25 kombinasi *business key* duplikat, dengan isi kedua baris identik, dan baris ganda berada di akhir file.

Karena seluruh atribut sama, tidak tampak perbedaan kelas, perubahan status, maupun riwayat transaksi; indikasinya adalah duplikat persis yang menggandakan beban SKS dan jumlah transaksi KRS. Keputusan penanganan ditunda ke tahap *cleaning*.

## 4.3 Soal 15 — Menghitung kelebihan record KRS akibat duplikasi

**Tujuan pemeriksaan**  
Menghitung total record yang melebihi satu record pada setiap kelompok kombinasi NIM, mata kuliah, dan semester yang duplikat.

**Query SQL**

```sql
SELECT COALESCE(SUM(jumlah - 1), 0) AS excess_duplicate_krs
FROM (
    SELECT COUNT(*) AS jumlah
    FROM src.krs
    GROUP BY nim, kode_mk, semester_id
    HAVING COUNT(*) > 1
) d;
```

**Hasil eksekusi**

| Excess Duplicate KRS |
|---:|
| 25 |

**Interpretasi**

Total kelebihan record KRS adalah 25. Karena setiap kombinasi duplikat muncul tepat 2 kali, jumlah kelebihan record sama dengan jumlah kelompok duplikat (25). Angka ini konsisten dengan selisih 57.025 − 57.000 pada Soal 13.

---

# 5. Profiling Tabel Nilai

## 5.1 Soal 16 — Menghitung nilai angka yang kosong

**Tujuan pemeriksaan**  
Menghitung record dengan `nilai_angka` kosong, `NULL`, atau hanya berisi spasi.

**Query SQL**

```sql
SELECT COUNT(*) AS missing_nilai_angka
FROM src.nilai
WHERE nilai_angka IS NULL OR TRIM(nilai_angka::text) = '';
```

**Hasil eksekusi**

| Missing Nilai Angka |
|---:|
| 20 |

**Interpretasi**

Terdapat 20 record nilai tanpa `nilai_angka` (sekitar 0,04% dari 57.000). Kolom `nilai_huruf` juga kosong pada baris yang sama. Rata-rata nilai dan *pass rate* tidak dapat dihitung untuk 20 record ini, dan 19 di antaranya tetap berstatus `Lulus` tanpa dasar nilai. Contoh: NIL0001733 (NIM 21DS0038, MKU101).

## 5.2 Soal 17 — Mengidentifikasi nilai angka di luar rentang valid

**Tujuan pemeriksaan**  
Menghitung nilai angka di luar rentang 0–100. Nilai kosong tidak dihitung sebagai nilai di luar rentang pada pemeriksaan ini.

**Query SQL**

```sql
SELECT COUNT(*) AS invalid_nilai_angka
FROM src.nilai
WHERE TRIM(COALESCE(nilai_angka::text, '')) <> ''
  AND (NULLIF(TRIM(nilai_angka::text),'')::NUMERIC < 0 OR NULLIF(TRIM(nilai_angka::text),'')::NUMERIC > 100);
```

**Hasil eksekusi**

| Invalid Nilai Angka |
|---:|
| 12 |

**Interpretasi**

Ditemukan 12 nilai di luar rentang 0–100: 6 nilai lebih dari 100 dan 6 nilai negatif (nilai terendah −18, tertinggi 106). Contoh: NIL0000320 = 105; NIL0002756 = −9; NIL0032132 = −18. Nilai kosong tidak dihitung pada pemeriksaan ini. Nilai tersebut tidak mungkin secara akademik dan perlu dikonfirmasi ke sumber data.

## 5.3 Soal 18 — Menghitung statistik deskriptif nilai mahasiswa

**Tujuan pemeriksaan**  
Menghitung jumlah nilai valid, nilai minimum, maksimum, dan rata-rata untuk nilai angka dalam rentang 0–100.

**Query SQL**

```sql
SELECT COUNT(*)                          AS valid_rows,
       MIN(NULLIF(TRIM(nilai_angka::text),'')::NUMERIC) AS nilai_min,
       MAX(NULLIF(TRIM(nilai_angka::text),'')::NUMERIC) AS nilai_max,
       ROUND(AVG(NULLIF(TRIM(nilai_angka::text),'')::NUMERIC), 2) AS nilai_rata_rata
FROM src.nilai
WHERE TRIM(COALESCE(nilai_angka::text, '')) <> ''
  AND NULLIF(TRIM(nilai_angka::text),'')::NUMERIC BETWEEN 0 AND 100;
```

**Hasil eksekusi**

| Valid Rows | Minimum | Maksimum | Rata-rata |
|---:|---:|---:|---:|
| 56.968 | 34,8 | 100 | 77,4 |

Jumlah valid diperoleh dari 56.980 nilai terisi dikurangi 12 nilai di luar rentang. Sebagai pembanding, statistik seluruh nilai terisi (termasuk 12 nilai di luar rentang): min −18, maks 106, rata-rata 77,39.

**Interpretasi**

Dari 57.000 record, 56.968 record memenuhi syarat (terisi dan berada di rentang 0–100). Rata-rata nilai berada di sekitar 77 dengan sebaran mendekati normal, dan 12 nilai ekstrem hampir tidak memengaruhi rata-rata. Interpretasi bersifat deskriptif dan tidak menyimpulkan kualitas pembelajaran.

## 5.4 Soal 19 — Memeriksa konsistensi nilai angka dengan nilai huruf

**Tujuan pemeriksaan**  
Menghitung record dengan ketidaksesuaian antara `nilai_angka` dan `nilai_huruf` berdasarkan aturan konversi berikut.

| Nilai Angka | Nilai Huruf |
|---|---|
| 85–100 | A |
| 80–<85 | AB |
| 75–<80 | B |
| 70–<75 | BC |
| 60–<70 | C |
| 50–<60 | D |
| 0–<50 | E |

**Query SQL**

```sql
SELECT COUNT(*) AS letter_mismatch
FROM src.nilai
WHERE TRIM(COALESCE(nilai_angka::text, '')) <> ''
  AND NULLIF(TRIM(nilai_angka::text),'')::NUMERIC BETWEEN 0 AND 100
  AND nilai_huruf IS DISTINCT FROM CASE
        WHEN NULLIF(TRIM(nilai_angka::text),'')::NUMERIC >= 85 THEN 'A'
        WHEN NULLIF(TRIM(nilai_angka::text),'')::NUMERIC >= 80 THEN 'AB'
        WHEN NULLIF(TRIM(nilai_angka::text),'')::NUMERIC >= 75 THEN 'B'
        WHEN NULLIF(TRIM(nilai_angka::text),'')::NUMERIC >= 70 THEN 'BC'
        WHEN NULLIF(TRIM(nilai_angka::text),'')::NUMERIC >= 60 THEN 'C'
        WHEN NULLIF(TRIM(nilai_angka::text),'')::NUMERIC >= 50 THEN 'D'
        ELSE 'E'
      END;
```

**Hasil eksekusi**

| Letter Mismatch |
|---:|
| 20 |

**Interpretasi**

Dengan aturan konversi pada soal (A 85–100, AB 80–84,99, B 75–79,99, BC 70–74,99, C 60–69,99, D 50–59,99, E 0–49,99), hanya 20 record yang `nilai_huruf`-nya tidak sesuai dengan `nilai_angka`. Contoh: NIL0053075 bernilai 100,0 tetapi berhuruf BC; NIL0033574 bernilai 91,3 berhuruf D; NIL0021195 bernilai 80,0 berhuruf E. Record ini perlu ditelusuri lebih lanjut. Catatan: skala berbeda (misalnya A mulai 80) menghasilkan jauh lebih banyak ketidaksesuaian (41.224 record), sehingga skala resmi perlu dikonfirmasi.

## 5.5 Soal 20 — Memeriksa konsistensi nilai angka dengan status kelulusan

**Tujuan pemeriksaan**  
Menghitung record dengan ketidaksesuaian antara `nilai_angka` dan `status_lulus`, dengan ketentuan nilai minimal 60 dinyatakan `Lulus`, sedangkan nilai di bawah 60 dinyatakan `Tidak Lulus`.

**Query SQL**

```sql
SELECT COUNT(*) AS status_mismatch
FROM src.nilai
WHERE TRIM(COALESCE(nilai_angka::text, '')) <> ''
  AND NULLIF(TRIM(nilai_angka::text),'')::NUMERIC BETWEEN 0 AND 100
  AND status_lulus IS DISTINCT FROM CASE
        WHEN NULLIF(TRIM(nilai_angka::text),'')::NUMERIC >= 60 THEN 'Lulus'
        ELSE 'Tidak Lulus'
      END;
```

**Hasil eksekusi**

| Status Mismatch |
|---:|
| 0 |

**Interpretasi**

Hasil 0 berarti tidak ada record nilai valid yang `status_lulus`-nya bertentangan dengan aturan nilai angka ≥ 60 = Lulus dan nilai angka < 60 = Tidak Lulus. Status kelulusan pada tabel nilai konsisten dengan nilai angka. Ketidaksesuaian yang tercatat pada Soal 19 (20 record) bersumber dari nilai huruf, bukan dari status kelulusan. Seluruh nilai raw tidak diubah pada tahap ini.

## 5.6 Soal 21 — Mengidentifikasi duplikasi record nilai

**Tujuan pemeriksaan**  
Menampilkan kombinasi `nim`, `kode_mk`, dan `semester_id` yang tercatat lebih dari satu kali pada tabel nilai.

**Query SQL**

```sql
SELECT nim, kode_mk, semester_id, COUNT(*) AS jumlah
FROM src.nilai
GROUP BY nim, kode_mk, semester_id
HAVING COUNT(*) > 1
ORDER BY jumlah DESC, nim, kode_mk, semester_id;
```

**Hasil eksekusi**

Query menghasilkan 0 baris.

**Interpretasi**

Tidak ada kombinasi `nim`, `kode_mk`, dan `semester_id` yang tercatat lebih dari satu kali pada tabel nilai. Setiap mahasiswa memiliki satu nilai per mata kuliah per semester (57.000 kombinasi unik, tanpa nilai revisi ganda), sehingga cocok sebagai grain tabel fakta.

---

# 6. Pemeriksaan Referential Integrity pada KRS dan Nilai

## 6.1 Soal 22 — Memeriksa NIM KRS yang tidak terdaftar sebagai mahasiswa

**Tujuan pemeriksaan**  
Menghitung record KRS dengan NIM yang tidak ditemukan pada tabel mahasiswa.

**Query SQL**

```sql
SELECT COUNT(*) AS krs_nim_tidak_terdaftar
FROM src.krs k
WHERE NOT EXISTS (SELECT 1 FROM src.mahasiswa m WHERE m.nim = k.nim);
```

**Hasil eksekusi**

| KRS NIM Tidak Terdaftar |
|---:|
| 0 |

**Interpretasi**

Nilai 0 berarti seluruh NIM pada tabel KRS ditemukan pada tabel mahasiswa; tidak ditemukan masalah referensial pada relasi ini.

## 6.2 Soal 23 — Memeriksa NIM pada tabel nilai yang tidak terdaftar sebagai mahasiswa

**Tujuan pemeriksaan**  
Menghitung record nilai dengan NIM yang tidak ditemukan pada tabel mahasiswa.

**Query SQL**

```sql
SELECT COUNT(*) AS nim_tidak_terdaftar
FROM src.nilai n
WHERE NOT EXISTS (SELECT 1 FROM src.mahasiswa m WHERE m.nim = n.nim);
```

**Hasil eksekusi**

| NIM Tidak Terdaftar |
|---:|
| 0 |

**Interpretasi**

Nilai 0 berarti seluruh NIM pada tabel nilai terhubung dengan tabel mahasiswa. Relasi nilai–mahasiswa utuh.

## 6.3 Soal 24 — Memeriksa kode mata kuliah yang tidak memiliki referensi

**Tujuan pemeriksaan**  
Menghitung record nilai dengan `kode_mk` yang tidak ditemukan pada tabel `mata_kuliah`.

**Query SQL**

```sql
SELECT COUNT(*) AS orphan_nilai_mk
FROM src.nilai n
WHERE NOT EXISTS (SELECT 1 FROM src.mata_kuliah mk WHERE mk.kode_mk = n.kode_mk);
```

**Hasil eksekusi**

| Orphan Nilai Mata Kuliah |
|---:|
| 0 |

**Interpretasi**

Nilai 0 berarti seluruh `kode_mk` pada tabel nilai memiliki referensi pada tabel `mata_kuliah`.

## 6.4 Soal 25 — Memeriksa semester nilai yang tidak memiliki referensi

**Tujuan pemeriksaan**  
Menghitung record nilai dengan `semester_id` yang tidak ditemukan pada tabel `semester`.

**Query SQL**

```sql
SELECT COUNT(*) AS orphan_nilai_semester
FROM src.nilai n
WHERE NOT EXISTS (SELECT 1 FROM src.semester s WHERE s.semester_id = n.semester_id);
```

**Hasil eksekusi**

| Orphan Nilai Semester |
|---:|
| 0 |

**Interpretasi**

Nilai 0 berarti seluruh `semester_id` pada tabel nilai terdaftar pada tabel `semester` (8 semester, 2021G–2024E).

---

# 7. Profiling Aktivitas LMS

## 7.1 Soal 26 — Mengukur duplikasi aktivitas LMS

**Tujuan pemeriksaan**  
Membandingkan jumlah seluruh record aktivitas LMS dengan jumlah `lms_event_id` unik.

**Query SQL**

```sql
SELECT COUNT(*) AS raw_rows,
       COUNT(DISTINCT lms_event_id) AS distinct_event_id,
       COUNT(*) - COUNT(DISTINCT lms_event_id) AS duplicate_excess
FROM src.aktivitas_lms;
```

**Hasil eksekusi**

| Raw Rows | Distinct Event ID | Duplicate Excess |
|---:|---:|---:|
| 200.356 | 200.326 | 30 |

**Interpretasi**

Terdapat 30 record berlebih. 30 `lms_event_id` muncul 2 kali dengan isi identik (60 baris terlibat), dan posisinya di akhir file. Duplikasi ini menggelembungkan hitungan aktivitas dan durasi belajar, tetapi proporsinya kecil (0,015%). Contoh: LMS00000417 dan LMS00005546.

## 7.2 Soal 27 — Menganalisis distribusi tipe aktivitas LMS

**Tujuan pemeriksaan**  
Menampilkan setiap `tipe_event` dan jumlah aktivitas pada masing-masing tipe.

**Query SQL**

```sql
SELECT tipe_event, COUNT(*) AS jumlah
FROM src.aktivitas_lms
GROUP BY tipe_event
ORDER BY jumlah DESC, tipe_event;
```

**Hasil eksekusi**

| tipe_event | Jumlah |
|---|---:|
| view_material | 56.040 |
| login | 50.136 |
| assignment_submit | 43.859 |
| quiz_attempt | 40.321 |
| forum_post | 10.000 |

**Interpretasi**

Terdapat 5 tipe aktivitas tanpa variasi penulisan label. `view_material` paling banyak (56.040), `forum_post` paling sedikit (10.000). Aktivitas didominasi akses materi dan login; kuis mencakup sekitar 20% dari seluruh aktivitas.

## 7.3 Soal 28 — Memeriksa kelengkapan skor kuis

**Tujuan pemeriksaan**  
Menghitung aktivitas bertipe `quiz_attempt` yang tidak memiliki skor pada `skor_kuis`.

**Query SQL**

```sql
SELECT COUNT(*) AS quiz_missing_score
FROM src.aktivitas_lms
WHERE tipe_event = 'quiz_attempt'
  AND (skor_kuis IS NULL OR TRIM(skor_kuis::text) = '');
```

**Hasil eksekusi**

| Quiz Missing Score |
|---:|
| 0 |

**Interpretasi**

Nilai 0: seluruh 40.321 aktivitas `quiz_attempt` memiliki skor kuis. Kolom `skor_kuis` kosong sebanyak 160.035 record, tepat sama dengan jumlah aktivitas non-kuis, sehingga tidak ada kuis yang kehilangan skor. Skor yang terisi berada pada rentang 26–100.

## 7.4 Soal 29 — Mengidentifikasi skor pada aktivitas selain kuis

**Tujuan pemeriksaan**  
Menghitung aktivitas selain `quiz_attempt` yang tetap memiliki nilai pada kolom `skor_kuis`.

**Query SQL**

```sql
SELECT COUNT(*) AS nonquiz_with_score
FROM src.aktivitas_lms
WHERE tipe_event <> 'quiz_attempt'
  AND skor_kuis IS NOT NULL AND TRIM(skor_kuis::text) <> '';
```

**Hasil eksekusi**

| Nonquiz With Score |
|---:|
| 0 |

**Interpretasi**

Nilai 0: tidak ada aktivitas selain `quiz_attempt` yang memiliki skor kuis. Kekosongan `skor_kuis` pada 79,88% record bersifat struktural (by design), sehingga tidak boleh diimputasi atau dihitung sebagai 0 pada rata-rata skor kuis.

---

# 8. Profiling Tabel Pembayaran

## 8.1 Soal 30 — Mengidentifikasi nominal pembayaran negatif

**Tujuan pemeriksaan**  
Menghitung record pembayaran dengan `nominal_bayar` kurang dari nol.

**Query SQL**

```sql
SELECT COUNT(*) AS negative_payment
FROM src.pembayaran
WHERE TRIM(COALESCE(nominal_bayar::text, '')) <> ''
  AND NULLIF(TRIM(nominal_bayar::text),'')::NUMERIC < 0;
```

**Hasil eksekusi**

| Negative Payment |
|---:|
| 5 |

**Interpretasi**

Ada 5 pembayaran bernominal negatif, semuanya berstatus Lunas dan tepat bernilai −`nominal_tagihan` (contoh PAY0001112: −5.750.000; PAY0002911: −5.250.000). Pola ini mengindikasikan tanda positif/negatif terbalik. Transaksi perlu dikonfirmasi ke bagian keuangan; nilai mentah tidak diubah.

## 8.2 Soal 31 — Memeriksa tanggal pembayaran yang kosong

**Tujuan pemeriksaan**  
Menghitung pembayaran dengan nominal positif tetapi `tanggal_bayar_raw` kosong, `NULL`, atau hanya berisi spasi.

**Query SQL**

```sql
SELECT COUNT(*) AS positive_payment_missing_date
FROM src.pembayaran
WHERE TRIM(COALESCE(nominal_bayar::text, '')) <> ''
  AND NULLIF(TRIM(nominal_bayar::text),'')::NUMERIC > 0
  AND (tanggal_bayar_raw IS NULL OR TRIM(tanggal_bayar_raw::text) = '');
```

**Hasil eksekusi**

| Positive Payment Missing Date |
|---:|
| 12 |

**Interpretasi**

Ada 12 transaksi yang sudah dibayar (10 Lunas dan 2 Cicilan) tetapi tidak memiliki tanggal bayar (contoh PAY0000031). Analisis ketepatan waktu pembayaran menjadi tidak lengkap untuk record ini. Sebanyak 461 record Belum Lunas tanpa tanggal bersifat wajar dan tidak dihitung sebagai masalah.

## 8.3 Soal 32 — Menganalisis distribusi status pembayaran

**Tujuan pemeriksaan**  
Menampilkan jumlah record berdasarkan setiap nilai `status_pembayaran`.

**Query SQL**

```sql
SELECT status_pembayaran, COUNT(*) AS jumlah
FROM src.pembayaran
GROUP BY status_pembayaran
ORDER BY jumlah DESC, status_pembayaran;
```

**Hasil eksekusi**

| status_pembayaran | Jumlah |
|---|---:|
| Lunas | 7.962 |
| Cicilan | 1.077 |
| Belum Lunas | 461 |

**Interpretasi**

Status Lunas paling banyak (7.962 record, 83,81%), diikuti Cicilan (1.077) dan Belum Lunas (461). Tidak ada variasi penulisan label status. Tingkat kelunasan perlu mengecualikan 5 nominal negatif yang berstatus Lunas.

---

# 9. Profiling Tabel Kelulusan

## 9.1 Soal 33 — Memeriksa duplikasi data kelulusan

**Tujuan pemeriksaan**  
Membandingkan jumlah seluruh record kelulusan dengan jumlah NIM unik.

**Query SQL**

```sql
SELECT COUNT(*) AS raw_rows,
       COUNT(DISTINCT nim) AS distinct_graduate_nim,
       COUNT(*) - COUNT(DISTINCT nim) AS duplicate_excess
FROM src.kelulusan;
```

**Hasil eksekusi**

| Raw Rows | Distinct Graduate NIM | Duplicate Excess |
|---:|---:|---:|
| 347 | 345 | 2 |

**Interpretasi**

Terdapat 2 record berlebih: GRD00097 (21SI0036) dan GRD00300 (21BD0005) masing-masing muncul 2 kali dengan isi identik. Jumlah lulusan terhitung 347 padahal yang unik 345, sama dengan jumlah mahasiswa berstatus Lulus di tabel mahasiswa. Dengan demikian dua record tersebut berupa duplikat persis, bukan lulusan ganda yang sah.

## 9.2 Soal 34 — Menganalisis status kelulusan tepat waktu

**Tujuan pemeriksaan**  
Menampilkan jumlah record berdasarkan setiap nilai `status_tepat_waktu`.

**Query SQL**

```sql
SELECT status_tepat_waktu, COUNT(*) AS jumlah
FROM src.kelulusan
GROUP BY status_tepat_waktu
ORDER BY jumlah DESC, status_tepat_waktu;
```

**Hasil eksekusi**

| status_tepat_waktu | Jumlah |
|---|---:|
| Ya | 347 |

**Interpretasi**

Seluruh 347 record berstatus `Ya` dan tidak ada kategori `Tidak`. Kolom ini konstan dan masa studi hanya 46 atau 47 bulan, sehingga tidak dapat dipakai membedakan lulusan tepat waktu dan tidak tepat waktu. Persentase 100% tepat waktu berbasis 347 record (345 setelah dedup) perlu diperlakukan hati-hati dan aturan penetapan statusnya dikonfirmasi ke pemilik data.

---

# 10. Pemeriksaan Relasi Antar-Tabel

## 10.1 Soal 35 — Memeriksa aktivitas LMS dengan NIM yang tidak terdaftar

**Tujuan pemeriksaan**  
Menghitung record aktivitas LMS dengan NIM yang tidak ditemukan pada tabel mahasiswa.

**Query SQL**

```sql
SELECT COUNT(*) AS orphan_lms_student
FROM src.aktivitas_lms a
WHERE NOT EXISTS (SELECT 1 FROM src.mahasiswa m WHERE m.nim = a.nim);
```

**Hasil eksekusi**

| Orphan LMS Student |
|---:|
| 0 |

**Interpretasi**

Nilai 0: seluruh aktivitas LMS berasal dari NIM yang terdaftar pada tabel mahasiswa.

## 10.2 Soal 36 — Memeriksa aktivitas LMS dengan mata kuliah yang tidak terdaftar

**Tujuan pemeriksaan**  
Menghitung record aktivitas LMS dengan `kode_mk` yang tidak ditemukan pada tabel mata kuliah.

**Query SQL**

```sql
SELECT COUNT(*) AS orphan_lms_course
FROM src.aktivitas_lms a
WHERE NOT EXISTS (SELECT 1 FROM src.mata_kuliah mk WHERE mk.kode_mk = a.kode_mk);
```

**Hasil eksekusi**

| Orphan LMS Course |
|---:|
| 0 |

**Interpretasi**

Nilai 0: seluruh `kode_mk` pada aktivitas LMS ditemukan pada tabel `mata_kuliah`.

## 10.3 Soal 37 — Memeriksa pembayaran dengan NIM yang tidak terdaftar

**Tujuan pemeriksaan**  
Menghitung record pembayaran dengan NIM yang tidak ditemukan pada tabel mahasiswa.

**Query SQL**

```sql
SELECT COUNT(*) AS orphan_payment_student
FROM src.pembayaran p
WHERE NOT EXISTS (SELECT 1 FROM src.mahasiswa m WHERE m.nim = p.nim);
```

**Hasil eksekusi**

| Orphan Payment Student |
|---:|
| 0 |

**Interpretasi**

Nilai 0: seluruh transaksi pembayaran terhubung dengan data mahasiswa.

## 10.4 Soal 38 — Memeriksa data kelulusan dengan NIM yang tidak terdaftar

**Tujuan pemeriksaan**  
Menghitung record kelulusan dengan NIM yang tidak ditemukan pada tabel mahasiswa.

**Query SQL**

```sql
SELECT COUNT(*) AS orphan_graduation_student
FROM src.kelulusan k
WHERE NOT EXISTS (SELECT 1 FROM src.mahasiswa m WHERE m.nim = k.nim);
```

**Hasil eksekusi**

| Orphan Graduation Student |
|---:|
| 0 |

**Interpretasi**

Nilai 0: seluruh record kelulusan memiliki data induk pada tabel mahasiswa; 345 NIM kelulusan cocok sempurna dengan mahasiswa berstatus Lulus.

---

# 11. Rekapitulasi Hasil Data Profiling dan Data Quality

Isikan ringkasan hasil dari seluruh pemeriksaan. Kolom status dapat menggunakan kategori **Tidak ditemukan masalah**, **Perlu pemeriksaan**, atau **Data belum cukup**. Berikan status berdasarkan hasil dan konteks data, bukan berdasarkan dugaan.

| No. | Area Pemeriksaan | Indikator | Hasil | Status | Catatan Temuan |
|---:|---|---|---:|---|---|
| 1 | Dataset | Jumlah record setiap tabel | 326.511 (total) | Tidak ditemukan masalah | Terbesar `aktivitas_lms` 200.356; sama dengan acuan modul |
| 2 | Dataset | Jumlah kolom setiap tabel | 5–11 | Tidak ditemukan masalah | `mahasiswa` 11 kolom; `program_studi` 5 kolom |
| 3 | Mahasiswa | Kelebihan record berdasarkan NIM | 15 | Perlu pemeriksaan | 1.965 baris vs 1.950 NIM unik; duplikat persis |
| 4 | Mahasiswa | Kelompok NIM duplikat | 15 | Perlu pemeriksaan | Masing-masing 2×; contoh 21TI0042, 21IF0052, 23DS0040 |
| 5 | Mahasiswa | Kota asal kosong | 30 | Perlu pemeriksaan | 1,53%; perlakukan sebagai tidak diketahui |
| 6 | Mahasiswa | Variasi label program studi | 30 | Perlu pemeriksaan | 30 label untuk 6 prodi; 435 baris varian |
| 7 | Mahasiswa | Variasi label jenis kelamin | 6 | Perlu pemeriksaan | L, P, Laki-laki, Perempuan, M, F; 437 baris bukan L/P |
| 8 | Mahasiswa | Program studi tidak cocok dengan referensi | 435 | Perlu pemeriksaan | 22,14%; berasal dari variasi penulisan |
| 9 | Mahasiswa | Variasi format tanggal masuk | 3 format | Perlu pemeriksaan | 1.429 / 346 / 190; OTHER 0 |
| 10 | KRS | Kelebihan record berdasarkan KRS ID | 25 | Perlu pemeriksaan | 57.025 baris vs 57.000 unik |
| 11 | KRS | Duplikasi kombinasi NIM–MK–semester | 25 | Perlu pemeriksaan | Masing-masing 2×; isi identik |
| 12 | Nilai | Nilai angka kosong | 20 | Perlu pemeriksaan | 19 di antaranya tetap berstatus Lulus |
| 13 | Nilai | Nilai angka di luar rentang | 12 | Perlu pemeriksaan | 6 > 100 dan 6 negatif |
| 14 | Nilai | Statistik nilai valid | 56.968 valid | Tidak ditemukan masalah | Min 34,8; maks 100; rata-rata 77,4 |
| 15 | Nilai | Ketidaksesuaian nilai angka dan huruf | 20 | Perlu pemeriksaan | Skala resmi perlu dikonfirmasi |
| 16 | Nilai | Ketidaksesuaian nilai dan status lulus | 0 | Tidak ditemukan masalah | Status lulus konsisten dengan nilai angka (≥ 60) |
| 17 | Nilai | Duplikasi kombinasi NIM–MK–semester | 0 | Tidak ditemukan masalah | 57.000 kombinasi unik |
| 18 | Referential integrity | NIM KRS tidak terdaftar | 0 | Tidak ditemukan masalah | Relasi utuh |
| 19 | Referential integrity | NIM nilai tidak terdaftar | 0 | Tidak ditemukan masalah | Relasi utuh |
| 20 | Referential integrity | Kode MK nilai tidak terdaftar | 0 | Tidak ditemukan masalah | Relasi utuh |
| 21 | Referential integrity | Semester nilai tidak terdaftar | 0 | Tidak ditemukan masalah | Relasi utuh |
| 22 | LMS | Kelebihan record berdasarkan event ID | 30 | Perlu pemeriksaan | 200.356 baris vs 200.326 unik |
| 23 | LMS | Distribusi tipe aktivitas | 5 tipe | Tidak ditemukan masalah | Tanpa variasi label |
| 24 | LMS | Skor kuis kosong | 0 | Tidak ditemukan masalah | Semua `quiz_attempt` memiliki skor |
| 25 | LMS | Skor pada aktivitas non-kuis | 0 | Tidak ditemukan masalah | Kosong 160.035 baris bersifat struktural |
| 26 | Pembayaran | Nominal pembayaran negatif | 5 | Perlu pemeriksaan | Tepat −nominal tagihan; berstatus Lunas |
| 27 | Pembayaran | Pembayaran positif tanpa tanggal | 12 | Perlu pemeriksaan | 10 Lunas dan 2 Cicilan |
| 28 | Pembayaran | Distribusi status pembayaran | 3 status | Tidak ditemukan masalah | Lunas 7.962; Cicilan 1.077; Belum Lunas 461 |
| 29 | Kelulusan | Kelebihan record berdasarkan NIM | 2 | Perlu pemeriksaan | 347 baris vs 345 NIM unik |
| 30 | Kelulusan | Distribusi status tepat waktu | Ya = 347 | Perlu pemeriksaan | Konstan; tidak ada kategori Tidak |
| 31 | Relasi LMS | NIM aktivitas LMS tidak terdaftar | 0 | Tidak ditemukan masalah | Relasi utuh |
| 32 | Relasi LMS | Kode MK aktivitas LMS tidak terdaftar | 0 | Tidak ditemukan masalah | Relasi utuh |
| 33 | Relasi pembayaran | NIM pembayaran tidak terdaftar | 0 | Tidak ditemukan masalah | Relasi utuh |
| 34 | Relasi kelulusan | NIM kelulusan tidak terdaftar | 0 | Tidak ditemukan masalah | Relasi utuh |

> **Catatan:** Rekap di atas merangkum indikator utama. Hasil distribusi dan statistik yang berbentuk beberapa baris tetap perlu disertakan pada bagian aktivitas masing-masing.

---

# 12. Kesimpulan Praktikum

Berdasarkan seluruh query dan hasil pemeriksaan yang telah dilakukan, tuliskan kesimpulan dengan menjawab pertanyaan berikut.

1. Bagaimana gambaran umum struktur dan ukuran dataset akademik yang diperiksa?

   Dataset terdiri atas 10 tabel dengan total 326.511 record dan 5–11 kolom per tabel. Tabel terbesar adalah `aktivitas_lms` (200.356 record), diikuti `krs` (57.025) dan `nilai` (57.000); tabel referensi (`program_studi` 6 dan `semester` 8) paling kecil. Seluruh jumlah record sesuai dengan acuan bahan praktikum.

2. Aspek kualitas data apa saja yang menunjukkan indikasi masalah?

   *Uniqueness* (duplikat persis pada `mahasiswa`, `krs`, `kelulusan`, `aktivitas_lms`), *consistency* (label program studi, jenis kelamin, status, dan tiga format tanggal), *validity* (12 nilai di luar 0–100 dan 5 nominal pembayaran negatif), *completeness* (30 kota asal, 20 nilai, 12 tanggal bayar kosong), serta konsistensi nilai angka–huruf–status.

3. Tabel mana yang memiliki temuan paling banyak atau paling perlu diperiksa lebih lanjut?

   Tabel `mahasiswa` memiliki temuan terbanyak (duplikasi NIM, label tidak seragam, format tanggal, kota kosong). Tabel `nilai` paling penting untuk analisis karena memuat nilai di luar rentang, nilai kosong, dan inkonsistensi huruf/status. Tabel `kelulusan` memiliki kolom `status_tepat_waktu` yang konstan.

4. Apakah terdapat relasi antar-tabel yang tidak terpenuhi?

   Tidak. Seluruh pemeriksaan *orphan* menghasilkan 0 (KRS, nilai, aktivitas LMS, pembayaran, dan kelulusan terhadap mahasiswa; nilai dan aktivitas LMS terhadap mata kuliah; nilai terhadap semester). Masalah terdapat pada kualitas atribut dan duplikasi, bukan pada keterhubungan kunci.

5. Pemeriksaan lanjutan apa yang diperlukan sebelum melakukan cleaning, standardisasi, atau deduplikasi?

   Konfirmasi skala nilai resmi, arti label `M`/`F`, aturan penetapan `status_tepat_waktu`, serta penyebab nilai negatif dan nominal negatif ke pemilik data; tentukan aturan parse tiga format tanggal; dan tetapkan aturan deduplikasi berbasis *business key* sebelum menghapus apa pun.

## 12.1 Temuan Utama

1. Duplikat persis pada empat tabel: 15 NIM (`mahasiswa`), 25 `krs_id`, 2 baris `kelulusan`, dan 30 `lms_event_id`; seluruhnya berada di akhir file.
2. Label kategori tidak seragam pada mahasiswa: 30 label program studi untuk 6 program studi (435 baris), 208 kode program studi dengan spasi/huruf kecil, 6 label jenis kelamin, dan 6 label status.
3. Tiga format tanggal bercampur pada kolom teks (contoh `tanggal_masuk_raw`: 1.429 / 346 / 190).
4. Nilai tidak valid pada sedikit baris: 12 nilai di luar 0–100, 20 nilai kosong, 20 huruf mutu tidak sesuai, serta 5 nominal pembayaran negatif.
5. Relasi antar-tabel utuh (0 *orphan*), tetapi `status_tepat_waktu` konstan `Ya` pada 347 lulusan.

## 12.2 Rekomendasi Pemeriksaan Lanjutan

1. Konfirmasi ke dosen/pemilik data: skala nilai resmi, arti `M`/`F`, aturan `status_tepat_waktu`, dan penyebab nominal/nilai negatif.
2. Rancang aturan deduplikasi (berdasarkan `nim`, `krs_id`, `kelulusan_id`, `lms_event_id`) dan aturan parse tanggal sebelum proses *cleaning* tanpa mengubah tabel `src`.
3. Susun tabel pemetaan label (prodi, jenis kelamin, status) serta pisahkan nilai kosong struktural dan nilai kosong cacat; gunakan hasil ini pada Source Mapping dan Data Fitness Unit 1.3.

---

# 13. Lampiran

## 13.1 Bukti Eksekusi Query

Hasil verifikasi jumlah baris seluruh tabel sumber pada schema `src`:

| No | Tabel | Jumlah baris aktual | Jumlah baris acuan | Status |
|---:|---|---:|---:|---|
| 1 | program_studi | 6 | 6 | Sesuai |
| 2 | semester | 8 | 8 | Sesuai |
| 3 | mahasiswa | 1.965 | 1.965 | Sesuai |
| 4 | dosen | 96 | 96 | Sesuai |
| 5 | mata_kuliah | 208 | 208 | Sesuai |
| 6 | krs | 57.025 | 57.025 | Sesuai |
| 7 | nilai | 57.000 | 57.000 | Sesuai |
| 8 | aktivitas_lms | 200.356 | 200.356 | Sesuai |
| 9 | pembayaran | 9.500 | 9.500 | Sesuai |
| 10 | kelulusan | 347 | 347 | Sesuai |

## 13.2 Catatan Kendala Praktikum

| No. | Kendala | Penyebab (jika diketahui) | Solusi yang Dilakukan |
|---:|---|---|---|
| 1 | Skala konversi nilai pada modul berbeda dengan skala yang dipakai data (A mulai 85 vs 80) | Aturan konversi belum dikonfirmasi pemilik data | Memakai skala pada soal (A ≥ 85) dan mencatat selisih sebagai temuan |
| 2 | Data CSV tidak membedakan `NULL` dan string kosong | Sifat file CSV | Pengecekan kosong memakai `IS NULL` dan `TRIM(...) = ''` |
| 3 | Dosen tidak dapat dihubungkan ke KRS, nilai, atau mata kuliah | Tidak ada kolom penghubung pada tabel `dosen` | Dicatat sebagai anomali untuk dikonfirmasi ke sumber data |

## 13.3 Referensi

- Materi praktikum Modul 1 Unit 1.1 — persiapan environment dan source layer UADW v1.0.
- Dataset UADW v1.0 yang disediakan untuk praktikum.
- Dokumentasi PostgreSQL: `information_schema`, fungsi agregat, dan operator ekspresi reguler (https://www.postgresql.org/docs/).

---

**Akhir Laporan**
