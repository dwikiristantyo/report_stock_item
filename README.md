# report_stock_item
Laporan mutasi stok per item untuk database `inventory-ga`.

## Jalankan laporan

1. Buka `report_mutasi_stock_per_item.sql` di HeidiSQL dan pilih database `inventory-ga`.
2. Sesuaikan `@tanggal_awal`, `@tanggal_akhir`, dan `@gudang` di bagian atas query. Nilai `%` pada gudang berarti semua gudang.
3. Jalankan seluruh script. Hasilnya satu baris per transaksi item, dengan kolom `No.`, `Tanggal`, `Department`, `Balance`, `Incoming`, `Outgoing`, dan `Stock`. `Balance` adalah saldo sebelum transaksi; `Stock` adalah saldo sesudahnya. Baris diurutkan dan diberi nomor per item.
4. Pada grid hasil query, pilih ekspor hasil ke Excel/CSV untuk menyimpan laporan. Kolom `Kode Item`, `Nama Item`, dan `Satuan` menjadi identitas/pengelompokan item.

Perhitungan memakai transaksi masuk (`othinmas`/`othindet`) dan keluar (`othoutmas`/`othoutdet`) yang berstatus bukan `X`, sesuai pola function `f_get_qty_stockawal.srf`. Item stok tanpa transaksi pada periode tetap ditampilkan dengan nilai mutasi nol.
