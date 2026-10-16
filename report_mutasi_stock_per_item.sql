-- Laporan mutasi stok per item untuk MySQL 5.5.
-- Ubah parameter periode dan gudang sebelum menjalankan query.
-- Gunakan '%' untuk mengambil seluruh gudang.
SET @tanggal_awal = '2024-01-01';
SET @tanggal_akhir = '2024-01-31';
SET @gudang = '%';

SELECT
    @nomor := IF(@kode_sebelumnya = hasil.kode_item, @nomor + 1, 1) AS `No.`,
    @kode_sebelumnya := hasil.kode_item AS `Kode Item`,
    hasil.nama_item AS `Nama Item`,
    hasil.satuan AS `Satuan`,
    hasil.tanggal AS `Tanggal`,
    hasil.departemen AS `Department`,
    hasil.balance AS `Balance`,
    hasil.incoming AS `Incoming`,
    hasil.outgoing AS `Outgoing`,
    hasil.balance + hasil.incoming - hasil.outgoing AS `Stock`
FROM (
    SELECT
        transaksi.kode_item,
        transaksi.nama_item,
        transaksi.satuan,
        transaksi.tanggal,
        transaksi.source_id,
        transaksi.source_type,
        transaksi.departemen,
        transaksi.incoming,
        transaksi.outgoing,
        (
            SELECT COALESCE(SUM(IFNULL(detail_masuk.qty, 0)), 0)
            FROM othinmas masuk
            INNER JOIN othindet detail_masuk ON detail_masuk.othinid = masuk.othinid
            WHERE detail_masuk.icode = transaksi.kode_item
              AND masuk.othindate <= transaksi.tanggal
              AND masuk.whid LIKE @gudang
              AND masuk.status <> 'X'
              AND (
                    masuk.othindate < transaksi.tanggal
                    OR masuk.othinid < transaksi.source_id
                    OR (masuk.othinid = transaksi.source_id AND 'IN' < transaksi.source_type)
              )
        ) - (
            SELECT COALESCE(SUM(IFNULL(detail_keluar.qty, 0)), 0)
            FROM othoutmas keluar
            INNER JOIN othoutdet detail_keluar ON detail_keluar.othoutid = keluar.othoutid
            WHERE detail_keluar.icode = transaksi.kode_item
              AND keluar.othoutdate <= transaksi.tanggal
              AND keluar.whid LIKE @gudang
              AND keluar.status <> 'X'
              AND (
                    keluar.othoutdate < transaksi.tanggal
                    OR keluar.othoutid < transaksi.source_id
                    OR (keluar.othoutid = transaksi.source_id AND 'OUT' < transaksi.source_type)
              )
        ) AS balance
    FROM (
        SELECT
            item.icode AS kode_item,
            TRIM(item.desc1) AS nama_item,
            TRIM(item.uom) AS satuan,
            masuk.othindate AS tanggal,
            masuk.othinid AS source_id,
            'IN' AS source_type,
            COALESCE(NULLIF(TRIM(masuk.remark), ''), TRIM(masuk.whid)) AS departemen,
            SUM(IFNULL(detail_masuk.qty, 0)) AS incoming,
            0 AS outgoing
        FROM itemast item
        INNER JOIN othindet detail_masuk ON detail_masuk.icode = item.icode
        INNER JOIN othinmas masuk ON masuk.othinid = detail_masuk.othinid
        WHERE item.stock = 'Y'
          AND masuk.othindate BETWEEN @tanggal_awal AND @tanggal_akhir
          AND masuk.whid LIKE @gudang
          AND masuk.status <> 'X'
        GROUP BY item.icode, item.desc1, item.uom, masuk.othindate, masuk.othinid, masuk.remark, masuk.whid

        UNION ALL

        SELECT
            item.icode AS kode_item,
            TRIM(item.desc1) AS nama_item,
            TRIM(item.uom) AS satuan,
            keluar.othoutdate AS tanggal,
            keluar.othoutid AS source_id,
            'OUT' AS source_type,
            COALESCE(NULLIF(TRIM(keluar.remark), ''), TRIM(keluar.whid)) AS departemen,
            0 AS incoming,
            SUM(IFNULL(detail_keluar.qty, 0)) AS outgoing
        FROM itemast item
        INNER JOIN othoutdet detail_keluar ON detail_keluar.icode = item.icode
        INNER JOIN othoutmas keluar ON keluar.othoutid = detail_keluar.othoutid
        WHERE item.stock = 'Y'
          AND keluar.othoutdate BETWEEN @tanggal_awal AND @tanggal_akhir
          AND keluar.whid LIKE @gudang
          AND keluar.status <> 'X'
        GROUP BY item.icode, item.desc1, item.uom, keluar.othoutdate, keluar.othoutid, keluar.remark, keluar.whid
    ) transaksi
) hasil
CROSS JOIN (SELECT @nomor := 0, @kode_sebelumnya := '') nomor_awal
ORDER BY hasil.kode_item, hasil.tanggal, hasil.source_id, hasil.source_type;
