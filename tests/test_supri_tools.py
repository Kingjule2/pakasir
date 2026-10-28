#!/usr/bin/env python3
"""Unit Tests for Supri AI Agent Deterministic Tools.

Validations:
1. Total omzet = sum of individual item sales.
2. Margin per product is non-negative (harga_jual >= harga_beli).
3. Dates are valid within expected range and parseable.
4. No duplicate IDs in products and transactions.
5. Filter period correctness (monthly, quarterly, range).
6. Consistency between tools (tren monthly omzet sum == ringkasan total_omzet).
"""

from __future__ import annotations

import os
import sys
import unittest
from pathlib import Path

import pandas as pd

# Add scripts directory to path
current_dir = Path(__file__).resolve().parent
repo_root = current_dir.parent
scripts_dir = repo_root / "scripts"
if str(scripts_dir) not in sys.path:
    sys.path.insert(0, str(scripts_dir))

from supri_tools import SupriBusinessTools


class TestSupriBusinessTools(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.data_dir = repo_root / "data" / "processed"
        cls.engine = SupriBusinessTools(data_dir=cls.data_dir)

    def test_01_total_omzet_consistency(self) -> None:
        """Cek total omzet = jumlah transaksi (harga_satuan * qty - diskon)."""
        summary = self.engine.get_ringkasan_keuangan("all")
        calculated_from_tx = int(
            (
                self.engine.df_tx["qty"] * self.engine.df_tx["harga_satuan"]
                - self.engine.df_tx["diskon"]
            ).sum()
        )
        self.assertEqual(
            summary["total_omzet"],
            calculated_from_tx,
            f"Omzet mismatch: summary={summary['total_omzet']} vs calculated={calculated_from_tx}",
        )
        self.assertGreater(summary["total_omzet"], 1_000_000_000)

    def test_02_margin_tidak_negatif(self) -> None:
        """Cek setiap produk memiliki margin tidak negatif (harga_jual >= harga_beli)."""
        margins = self.engine.get_margin_per_produk()
        for prod in margins:
            self.assertGreaterEqual(
                prod["margin_nominal"],
                0,
                f"Negative margin found on product #{prod['produk_id']} ({prod['nama']}): {prod['margin_nominal']}",
            )
            self.assertGreaterEqual(
                prod["harga_jual"],
                prod["harga_beli"],
                f"Selling price lower than cost price on product #{prod['produk_id']} ({prod['nama']})",
            )
            self.assertGreaterEqual(prod["margin_pct"], 0.0)

    def test_03_tanggal_valid_dan_berurutan(self) -> None:
        """Cek tanggal transaksi dan pengeluaran valid dalam rentang Jan-Sep 2025."""
        tx_dates = pd.to_datetime(self.engine.df_tx["tanggal"])
        min_date = pd.Timestamp("2025-01-01 00:00:00")
        max_date = pd.Timestamp("2025-09-30 23:59:59")

        self.assertGreaterEqual(tx_dates.min(), min_date)
        self.assertLessEqual(tx_dates.max(), max_date)

        if not self.engine.df_exp.empty:
            exp_dates = pd.to_datetime(self.engine.df_exp["tanggal"])
            self.assertGreaterEqual(exp_dates.min(), min_date)
            self.assertLessEqual(exp_dates.max(), max_date)

    def test_04_tidak_ada_duplikat(self) -> None:
        """Cek tidak ada duplikat ID pada produk dan transaksi."""
        # Product IDs must be strictly unique
        prod_ids = self.engine.df_produk["id"]
        self.assertEqual(len(prod_ids), prod_ids.nunique(), "Duplicate Product IDs detected!")

        # Transaction item IDs must be strictly unique
        tx_ids = self.engine.df_tx["id"]
        self.assertEqual(len(tx_ids), tx_ids.nunique(), "Duplicate Transaction Item IDs detected!")

    def test_05_produk_terlaris_ranking(self) -> None:
        """Cek get_produk_terlaris mengembalikan peringkat terurut dan kontribusi omzet valid."""
        top5 = self.engine.get_produk_terlaris("all", 5)
        self.assertEqual(len(top5), 5)

        for i in range(len(top5) - 1):
            self.assertGreaterEqual(
                top5[i]["qty_terjual"],
                top5[i + 1]["qty_terjual"],
                "Top products not ordered by sales qty descending!",
            )

        total_contribution = sum(p["kontribusi_omzet_pct"] for p in top5)
        self.assertLessEqual(total_contribution, 100.0)
        self.assertGreater(total_contribution, 0.0)

    def test_06_stok_menipis_invariants(self) -> None:
        """Cek get_stok_menipis hanya mengembalikan item dengan stok <= stok_minimum."""
        menipis = self.engine.get_stok_menipis()
        for item in menipis:
            self.assertLessEqual(
                item["stok"],
                item["stok_minimum"],
                f"Item {item['nama']} returned in low stock but stock={item['stok']} > min={item['stok_minimum']}",
            )
            self.assertIn(item["status"], ["KRITIS", "MENIPIS"])
            self.assertGreaterEqual(item["defisit"], 0)

    def test_07_tren_penjualan_monthly_sum_matches_total(self) -> None:
        """Cek agregasi tren bulanan memiliki total omzet dan total transaksi yang konsisten."""
        tren_monthly = self.engine.get_tren_penjualan("monthly")
        self.assertEqual(len(tren_monthly), 9)  # 9 months (Jan-Sep 2025)

        sum_omzet_tren = sum(t["omzet"] for t in tren_monthly)
        summary = self.engine.get_ringkasan_keuangan("all")
        self.assertEqual(sum_omzet_tren, summary["total_omzet"])

        sum_items_tren = sum(t["item_terjual"] for t in tren_monthly)
        self.assertEqual(sum_items_tren, summary["total_item_terjual"])

    def test_08_filter_periode_accuracy(self) -> None:
        """Cek akurasi filter periode bulanan dan range tanggal."""
        jan_summary = self.engine.get_ringkasan_keuangan("2025-01")
        self.assertGreater(jan_summary["total_omzet"], 0)
        self.assertLess(jan_summary["total_omzet"], self.engine.get_ringkasan_keuangan("all")["total_omzet"])

        # Compare with monthly trend Jan 2025
        monthly_trend = {t["periode"]: t["omzet"] for t in self.engine.get_tren_penjualan("monthly")}
        self.assertEqual(jan_summary["total_omzet"], monthly_trend["2025-01"])


if __name__ == "__main__":
    unittest.main()
