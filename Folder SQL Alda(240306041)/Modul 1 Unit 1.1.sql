-- =====================================================================
-- MODUL 1 - UNIT 1.1
-- Persiapan Source Layer dan Initial Data Profiling (PostgreSQL, schema src)
-- Dijalankan di DBeaver. Jangan UPDATE/DELETE raw data pada tahap ini.
-- =====================================================================

-- ---------- A. Verifikasi Environment ----------
-- Soal 1
SELECT version();

-- Soal 2
SELECT current_database() AS database_aktif,
       current_user       AS user_aktif;

-- Soal 3
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'src';

-- ---------- B. Membuat Source Layer (Soal 4) ----------
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

-- Bukti tabel terbentuk
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'src' AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ---------- C. Impor CSV (Soal 5) ----------
-- Di DBeaver: klik kanan tabel > Import Data > CSV (header = ya, encoding UTF-8).
-- Alternatif psql (ubah /PATH/UADW_v1.0/ sesuai lokasi dataset):
-- \copy src.program_studi FROM '/PATH/UADW_v1.0/01_raw_data/program_studi.csv' CSV HEADER ENCODING 'UTF8';
-- \copy src.semester      FROM '/PATH/UADW_v1.0/01_raw_data/semester.csv'      CSV HEADER ENCODING 'UTF8';
-- \copy src.mahasiswa     FROM '/PATH/UADW_v1.0/01_raw_data/mahasiswa.csv'     CSV HEADER ENCODING 'UTF8';
-- \copy src.dosen         FROM '/PATH/UADW_v1.0/01_raw_data/dosen.csv'         CSV HEADER ENCODING 'UTF8';
-- \copy src.mata_kuliah   FROM '/PATH/UADW_v1.0/01_raw_data/mata_kuliah.csv'   CSV HEADER ENCODING 'UTF8';
-- \copy src.krs           FROM '/PATH/UADW_v1.0/01_raw_data/krs.csv'           CSV HEADER ENCODING 'UTF8';
-- \copy src.nilai         FROM '/PATH/UADW_v1.0/01_raw_data/nilai.csv'         CSV HEADER ENCODING 'UTF8';
-- \copy src.aktivitas_lms FROM '/PATH/UADW_v1.0/01_raw_data/aktivitas_lms.csv' CSV HEADER ENCODING 'UTF8';
-- \copy src.pembayaran    FROM '/PATH/UADW_v1.0/01_raw_data/pembayaran.csv'    CSV HEADER ENCODING 'UTF8';
-- \copy src.kelulusan     FROM '/PATH/UADW_v1.0/01_raw_data/kelulusan.csv'     CSV HEADER ENCODING 'UTF8';

-- ---------- D. Inventarisasi dan Verifikasi ----------
-- Soal 6
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'src' AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Soal 7
SELECT 'program_studi' AS tabel, COUNT(*) AS jumlah_baris FROM src.program_studi
UNION ALL SELECT 'semester',    COUNT(*) FROM src.semester
UNION ALL SELECT 'mahasiswa',   COUNT(*) FROM src.mahasiswa
UNION ALL SELECT 'dosen',       COUNT(*) FROM src.dosen
UNION ALL SELECT 'mata_kuliah', COUNT(*) FROM src.mata_kuliah
ORDER BY tabel;

-- Soal 8
SELECT 'program_studi' AS tabel, COUNT(*) AS jumlah_baris FROM src.program_studi
UNION ALL SELECT 'semester',      COUNT(*) FROM src.semester
UNION ALL SELECT 'mahasiswa',     COUNT(*) FROM src.mahasiswa
UNION ALL SELECT 'dosen',         COUNT(*) FROM src.dosen
UNION ALL SELECT 'mata_kuliah',   COUNT(*) FROM src.mata_kuliah
UNION ALL SELECT 'krs',           COUNT(*) FROM src.krs
UNION ALL SELECT 'nilai',         COUNT(*) FROM src.nilai
UNION ALL SELECT 'aktivitas_lms', COUNT(*) FROM src.aktivitas_lms
UNION ALL SELECT 'pembayaran',    COUNT(*) FROM src.pembayaran
UNION ALL SELECT 'kelulusan',     COUNT(*) FROM src.kelulusan
ORDER BY tabel;

-- Soal 9
SELECT table_name, COUNT(*) AS jumlah_kolom
FROM information_schema.columns
WHERE table_schema = 'src'
GROUP BY table_name
ORDER BY table_name;

-- Soal 10
SELECT ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'src' AND table_name = 'mahasiswa'
ORDER BY ordinal_position;

-- ---------- E. Initial Profiling Mahasiswa ----------
-- Soal 11
SELECT COUNT(*)                                AS raw_rows,
       COUNT(DISTINCT nim)                     AS distinct_nim,
       COUNT(*) - COUNT(DISTINCT nim)          AS excess_duplicate_rows
FROM src.mahasiswa;

-- Soal 12
SELECT MIN(CAST(angkatan AS INTEGER)) AS angkatan_min,
       MAX(CAST(angkatan AS INTEGER)) AS angkatan_max
FROM src.mahasiswa;

-- Soal 13
SELECT COUNT(*) AS missing_kota
FROM src.mahasiswa
WHERE TRIM(COALESCE(kota_asal_raw, '')) = '';

-- Soal 14
SELECT COUNT(DISTINCT prodi_raw) AS distinct_prodi_raw
FROM src.mahasiswa;

-- Soal 15
SELECT COUNT(*) AS canonical_programs
FROM src.program_studi;

-- Soal 16
SELECT prodi_raw, COUNT(*) AS jumlah
FROM src.mahasiswa
GROUP BY prodi_raw
ORDER BY prodi_raw;

-- Soal 17
SELECT jk_raw, COUNT(*) AS jumlah
FROM src.mahasiswa
GROUP BY jk_raw
ORDER BY jk_raw;

-- Soal 18
SELECT * FROM src.mahasiswa LIMIT 5;

-- ---------- F. Ukuran Source dan Relasi Awal ----------
-- Soal 19
SELECT 'program_studi' AS source, COUNT(*) AS rows FROM src.program_studi
UNION ALL SELECT 'semester',      COUNT(*) FROM src.semester
UNION ALL SELECT 'mahasiswa',     COUNT(*) FROM src.mahasiswa
UNION ALL SELECT 'dosen',         COUNT(*) FROM src.dosen
UNION ALL SELECT 'mata_kuliah',   COUNT(*) FROM src.mata_kuliah
UNION ALL SELECT 'krs',           COUNT(*) FROM src.krs
UNION ALL SELECT 'nilai',         COUNT(*) FROM src.nilai
UNION ALL SELECT 'aktivitas_lms', COUNT(*) FROM src.aktivitas_lms
UNION ALL SELECT 'pembayaran',    COUNT(*) FROM src.pembayaran
UNION ALL SELECT 'kelulusan',     COUNT(*) FROM src.kelulusan
ORDER BY rows DESC;

-- Soal 20
SELECT 'krs' AS source, COUNT(DISTINCT nim) AS distinct_nim FROM src.krs
UNION ALL SELECT 'nilai',         COUNT(DISTINCT nim) FROM src.nilai
UNION ALL SELECT 'aktivitas_lms', COUNT(DISTINCT nim) FROM src.aktivitas_lms
UNION ALL SELECT 'pembayaran',    COUNT(DISTINCT nim) FROM src.pembayaran
UNION ALL SELECT 'kelulusan',     COUNT(DISTINCT nim) FROM src.kelulusan;
