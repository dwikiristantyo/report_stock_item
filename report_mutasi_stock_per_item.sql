-- Laporan mutasi stok per item untuk MySQL 5.5.
-- Ubah parameter periode dan gudang sebelum menjalankan query.
-- Gunakan '%' untuk mengambil seluruh gudang.
SET @tanggal_awal = '2024-01-01';
SET @tanggal_akhir = '2024-01-31';
SET @gudang = '%';

SELECT
    i.icode AS kode_item,
    TRIM(i.desc1) AS nama_item,
    TRIM(i.uom) AS satuan,
    COALESCE(m.saldo_awal, 0) AS saldo_awal,
    COALESCE(m.barang_masuk, 0) AS barang_masuk,
    COALESCE(m.barang_keluar, 0) AS barang_keluar,
    COALESCE(m.saldo_awal, 0)
        + COALESCE(m.barang_masuk, 0)
        - COALESCE(m.barang_keluar, 0) AS saldo_akhir
FROM itemast i
LEFT JOIN (
    SELECT
        transaksi.icode,
        SUM(CASE
                WHEN transaksi.tanggal < @tanggal_awal
                THEN transaksi.qty_masuk - transaksi.qty_keluar
                ELSE 0
            END) AS saldo_awal,
        SUM(CASE
                WHEN transaksi.tanggal BETWEEN @tanggal_awal AND @tanggal_akhir
                THEN transaksi.qty_masuk
                ELSE 0
            END) AS barang_masuk,
        SUM(CASE
                WHEN transaksi.tanggal BETWEEN @tanggal_awal AND @tanggal_akhir
                THEN transaksi.qty_keluar
                ELSE 0
            END) AS barang_keluar
    FROM (
        SELECT
            masuk.othindate AS tanggal,
            detail_masuk.icode,
            IFNULL(detail_masuk.qty, 0) AS qty_masuk,
            0 AS qty_keluar
        FROM othinmas masuk
        INNER JOIN othindet detail_masuk ON detail_masuk.othinid = masuk.othinid
        WHERE masuk.othindate <= @tanggal_akhir
          AND masuk.whid LIKE @gudang
          AND masuk.status <> 'X'

        UNION ALL

        SELECT
            keluar.othoutdate AS tanggal,
            detail_keluar.icode,
            0 AS qty_masuk,
            IFNULL(detail_keluar.qty, 0) AS qty_keluar
        FROM othoutmas keluar
        INNER JOIN othoutdet detail_keluar ON detail_keluar.othoutid = keluar.othoutid
        WHERE keluar.othoutdate <= @tanggal_akhir
          AND keluar.whid LIKE @gudang
          AND keluar.status <> 'X'
    ) transaksi
    GROUP BY transaksi.icode
) m ON m.icode = i.icode
WHERE i.stock = 'Y'
ORDER BY i.icode;
