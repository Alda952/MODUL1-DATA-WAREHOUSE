-- =====================================================================
-- MODUL 1 - UNIT 1.2
-- Data Profiling dan Data Quality Assessment (PostgreSQL, schema src)
-- Hanya SELECT. Tidak ada UPDATE/DELETE pada raw data.
-- =====================================================================

-- 1.1 - 1.3 Verifikasi environment
SELECT version();
SELECT current_database() AS database_aktif, current_user AS user_aktif;
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'src';

-- ---------- A. Struktur dan Ukuran ----------
-- Soal 1
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

-- Soal 2
SELECT table_name AS nama_tabel, COUNT(*) AS jumlah_kolom
FROM information_schema.columns
WHERE table_schema = 'src'
GROUP BY table_name
ORDER BY table_name;

-- ---------- B. Mahasiswa - Uniqueness ----------
-- Soal 3
SELECT COUNT(*) AS raw_rows,
       COUNT(DISTINCT nim) AS distinct_nim,
       COUNT(*) - COUNT(DISTINCT nim) AS excess_duplicate_rows
FROM src.mahasiswa;

-- Soal 4
SELECT nim, COUNT(*) AS jumlah_kemunculan
FROM src.mahasiswa
GROUP BY nim
HAVING COUNT(*) > 1
ORDER BY jumlah_kemunculan DESC, nim;

-- ---------- C. Mahasiswa - Completeness ----------
-- Soal 5
SELECT COUNT(*) AS missing_kota
FROM src.mahasiswa
WHERE kota_asal_raw IS NULL OR TRIM(kota_asal_raw) = '';

-- ---------- D. Mahasiswa - Distribusi dan Standardisasi ----------
-- Soal 6
SELECT prodi_raw, COUNT(*) AS frekuensi
FROM src.mahasiswa
GROUP BY prodi_raw
ORDER BY frekuensi DESC, prodi_raw;

-- Soal 7
SELECT COUNT(DISTINCT prodi_raw) AS distinct_raw_prodi
FROM src.mahasiswa;

-- Soal 8
SELECT jk_raw, COUNT(*) AS frekuensi
FROM src.mahasiswa
GROUP BY jk_raw
ORDER BY frekuensi DESC, jk_raw;

-- Soal 9
SELECT status_raw, COUNT(*) AS frekuensi
FROM src.mahasiswa
GROUP BY status_raw
ORDER BY frekuensi DESC, status_raw;

-- Soal 10
SELECT kode_prodi_raw, COUNT(*) AS frekuensi
FROM src.mahasiswa
GROUP BY kode_prodi_raw
ORDER BY frekuensi DESC, kode_prodi_raw;

-- Soal 11
SELECT COUNT(*) AS non_standard_prodi_rows
FROM src.mahasiswa m
WHERE NOT EXISTS (
    SELECT 1 FROM src.program_studi p
    WHERE p.nama_prodi = m.prodi_raw
);

-- ---------- E. Mahasiswa - Format Tanggal ----------
-- Soal 12
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

-- ---------- F. KRS - Duplikasi ----------
-- Soal 13
SELECT COUNT(*) AS raw_rows, COUNT(DISTINCT krs_id) AS distinct_krs_id
FROM src.krs;

-- Soal 14
SELECT nim, kode_mk, semester_id, COUNT(*) AS jumlah
FROM src.krs
GROUP BY nim, kode_mk, semester_id
HAVING COUNT(*) > 1
ORDER BY jumlah DESC, nim, kode_mk, semester_id;

-- Soal 15
SELECT COALESCE(SUM(jumlah - 1), 0) AS excess_duplicate_krs
FROM (
    SELECT COUNT(*) AS jumlah
    FROM src.krs
    GROUP BY nim, kode_mk, semester_id
    HAVING COUNT(*) > 1
) d;

-- ---------- G. Nilai - Completeness dan Validity ----------
-- Soal 16
SELECT COUNT(*) AS missing_nilai_angka
FROM src.nilai
WHERE nilai_angka IS NULL OR TRIM(nilai_angka::text) = '';

-- Soal 17
SELECT COUNT(*) AS invalid_nilai_angka
FROM src.nilai
WHERE TRIM(COALESCE(nilai_angka::text, '')) <> ''
  AND (NULLIF(TRIM(nilai_angka::text),'')::NUMERIC < 0 OR NULLIF(TRIM(nilai_angka::text),'')::NUMERIC > 100);

-- Soal 18
SELECT COUNT(*)                          AS valid_rows,
       MIN(NULLIF(TRIM(nilai_angka::text),'')::NUMERIC) AS nilai_min,
       MAX(NULLIF(TRIM(nilai_angka::text),'')::NUMERIC) AS nilai_max,
       ROUND(AVG(NULLIF(TRIM(nilai_angka::text),'')::NUMERIC), 2) AS nilai_rata_rata
FROM src.nilai
WHERE TRIM(COALESCE(nilai_angka::text, '')) <> ''
  AND NULLIF(TRIM(nilai_angka::text),'')::NUMERIC BETWEEN 0 AND 100;

-- ---------- H. Nilai - Konsistensi ----------
-- Soal 19
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

-- Soal 20
SELECT COUNT(*) AS status_mismatch
FROM src.nilai
WHERE TRIM(COALESCE(nilai_angka::text, '')) <> ''
  AND NULLIF(TRIM(nilai_angka::text),'')::NUMERIC BETWEEN 0 AND 100
  AND status_lulus IS DISTINCT FROM CASE
        WHEN NULLIF(TRIM(nilai_angka::text),'')::NUMERIC >= 60 THEN 'Lulus'
        ELSE 'Tidak Lulus'
      END;

-- ---------- I. Nilai - Duplikasi ----------
-- Soal 21
SELECT nim, kode_mk, semester_id, COUNT(*) AS jumlah
FROM src.nilai
GROUP BY nim, kode_mk, semester_id
HAVING COUNT(*) > 1
ORDER BY jumlah DESC, nim, kode_mk, semester_id;

-- ---------- J. Referential Integrity KRS dan Nilai ----------
-- Soal 22
SELECT COUNT(*) AS krs_nim_tidak_terdaftar
FROM src.krs k
WHERE NOT EXISTS (SELECT 1 FROM src.mahasiswa m WHERE m.nim = k.nim);

-- Soal 23
SELECT COUNT(*) AS nim_tidak_terdaftar
FROM src.nilai n
WHERE NOT EXISTS (SELECT 1 FROM src.mahasiswa m WHERE m.nim = n.nim);

-- Soal 24
SELECT COUNT(*) AS orphan_nilai_mk
FROM src.nilai n
WHERE NOT EXISTS (SELECT 1 FROM src.mata_kuliah mk WHERE mk.kode_mk = n.kode_mk);

-- Soal 25
SELECT COUNT(*) AS orphan_nilai_semester
FROM src.nilai n
WHERE NOT EXISTS (SELECT 1 FROM src.semester s WHERE s.semester_id = n.semester_id);

-- ---------- K. Aktivitas LMS ----------
-- Soal 26
SELECT COUNT(*) AS raw_rows,
       COUNT(DISTINCT lms_event_id) AS distinct_event_id,
       COUNT(*) - COUNT(DISTINCT lms_event_id) AS duplicate_excess
FROM src.aktivitas_lms;

-- Soal 27
SELECT tipe_event, COUNT(*) AS jumlah
FROM src.aktivitas_lms
GROUP BY tipe_event
ORDER BY jumlah DESC, tipe_event;

-- Soal 28
SELECT COUNT(*) AS quiz_missing_score
FROM src.aktivitas_lms
WHERE tipe_event = 'quiz_attempt'
  AND (skor_kuis IS NULL OR TRIM(skor_kuis::text) = '');

-- Soal 29
SELECT COUNT(*) AS nonquiz_with_score
FROM src.aktivitas_lms
WHERE tipe_event <> 'quiz_attempt'
  AND skor_kuis IS NOT NULL AND TRIM(skor_kuis::text) <> '';

-- ---------- L. Pembayaran ----------
-- Soal 30
SELECT COUNT(*) AS negative_payment
FROM src.pembayaran
WHERE TRIM(COALESCE(nominal_bayar::text, '')) <> ''
  AND NULLIF(TRIM(nominal_bayar::text),'')::NUMERIC < 0;

-- Soal 31
SELECT COUNT(*) AS positive_payment_missing_date
FROM src.pembayaran
WHERE TRIM(COALESCE(nominal_bayar::text, '')) <> ''
  AND NULLIF(TRIM(nominal_bayar::text),'')::NUMERIC > 0
  AND (tanggal_bayar_raw IS NULL OR TRIM(tanggal_bayar_raw::text) = '');

-- Soal 32
SELECT status_pembayaran, COUNT(*) AS jumlah
FROM src.pembayaran
GROUP BY status_pembayaran
ORDER BY jumlah DESC, status_pembayaran;

-- ---------- M. Kelulusan ----------
-- Soal 33
SELECT COUNT(*) AS raw_rows,
       COUNT(DISTINCT nim) AS distinct_graduate_nim,
       COUNT(*) - COUNT(DISTINCT nim) AS duplicate_excess
FROM src.kelulusan;

-- Soal 34
SELECT status_tepat_waktu, COUNT(*) AS jumlah
FROM src.kelulusan
GROUP BY status_tepat_waktu
ORDER BY jumlah DESC, status_tepat_waktu;

-- ---------- N. Relasi Antar-Tabel ----------
-- Soal 35
SELECT COUNT(*) AS orphan_lms_student
FROM src.aktivitas_lms a
WHERE NOT EXISTS (SELECT 1 FROM src.mahasiswa m WHERE m.nim = a.nim);

-- Soal 36
SELECT COUNT(*) AS orphan_lms_course
FROM src.aktivitas_lms a
WHERE NOT EXISTS (SELECT 1 FROM src.mata_kuliah mk WHERE mk.kode_mk = a.kode_mk);

-- Soal 37
SELECT COUNT(*) AS orphan_payment_student
FROM src.pembayaran p
WHERE NOT EXISTS (SELECT 1 FROM src.mahasiswa m WHERE m.nim = p.nim);

-- Soal 38
SELECT COUNT(*) AS orphan_graduation_student
FROM src.kelulusan k
WHERE NOT EXISTS (SELECT 1 FROM src.mahasiswa m WHERE m.nim = k.nim);
