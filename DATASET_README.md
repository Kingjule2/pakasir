# Dataset Documentation & Data Attribution

## 1. Sumber Dataset (Data Sources)

1. **Dataset Transaksi POS F&B UMKM Indonesia**
   - **Sumber:** Mendeley Data
   - **DOI:** [10.17632/kcgf45y24m.2](https://doi.org/10.17632/kcgf45y24m.2)
   - **Deskripsi:** Data transaksi riil kasir POS UMKM F&B periode 2 Januari 2025 s/d 30 September 2025 (53.820 transaksi, 61.973 item terjual, 3 cabang outlet) beserta metadata produk (96 SKU minuman kopi, teh, makanan ringan, dan varian).
   - **Lisensi:** CC BY 4.0 (Creative Commons Attribution 4.0 International).

2. **Dataset Transaksi Penjualan Apotek Indonesia (Opsional)**
   - **Sumber:** Mendeley Data
   - **DOI:** [10.17632/2ym7v78wtd.1](https://doi.org/10.17632/2ym7v78wtd.1)
   - **Deskripsi:** Database SQL penjualan apotek (`sales.sql`) yang mencakup tabel master produk, harga neto apotek / harga beli (`HNA`), harga jual (`HJ`), resep, dan PPN.
   - **Lisensi:** CC BY 4.0.

---

## 2. Catatan Data Sintetis vs Data Riil

Untuk menjaga privasi dan melengkapi struktur analisis keuangan UMKM tanpa menghilangkan keaslian transaksi POS, data dibagi secara transparan dengan kolom flag `is_synthetic`:

| File CSV | Kolom / Komponen | Status | Penjelasan |
| :--- | :--- | :--- | :--- |
| `data/processed/produk.csv` | `id, nama, kategori, harga_jual` | **RIIL** (`is_synthetic=False`) | Berasal langsung dari Mendeley Data `Products.csv`. |
| `data/processed/produk.csv` | `harga_beli, stok, stok_minimum` | **SINTETIS** (`is_synthetic=True`) | Dihasilkan dengan *fixed random seed* (42). HPP diatur realistis 52%–68% dari harga jual. Stok saat ini dan batas aman minimum mencerminkan toko aktif. |
| `data/processed/transaksi.csv` | `id, tanggal, produk_id, qty, harga_satuan, metode_bayar` | **RIIL** (`is_synthetic=False`) | Berasal dari 53.820 struk kasir riil (`Transactions.csv`) yang dinormalisasi per item baris. |
| `data/processed/pengeluaran.csv` | `tanggal, kategori, jumlah` | **SINTETIS** (`is_synthetic=True`) | Estimasi beban operasional bulanan wajar UMKM (sewa 3 outlet, gaji barista/karyawan, listrik & utilitas, internet POS, packaging, marketing). |
| `data/processed/restock.csv` | `tanggal, produk_id, qty, harga_beli` | **SINTETIS** (`is_synthetic=True`) | Riwayat pengadaan barang mingguan proporsional terhadap *sales velocity* masing-masing produk. |

---

## 3. Instruksi Menjalankan ETL & Unit Testing

```bash
# 1. Jalankan pipeline ETL (menghasilkan 4 CSV di data/processed/)
python scripts/prepare_data.py

# 2. Jalankan unit test validasi kepatuhan data dan tools
python -m unittest tests/test_supri_tools.py

# 3. Jalankan konsultasi AI Supri
python scripts/supri_agent.py
```

*Catatan Keamanan Git:* Folder `data/raw/`, `dataset/`, serta file mentah `*.zip` dan `*.sql` telah dimasukkan ke dalam `.gitignore` dan tidak boleh di-commit ke repositori publik.
