#!/usr/bin/env python3
"""Deterministic Financial & Business Analytics Tools for Supri AI Agent.

Calculates all numbers in pure Python/Pandas (zero LLM hallucination).
Provides Gemini function calling tool declarations and dispatchers.

Tools:
1. get_ringkasan_keuangan(periode)
2. get_produk_terlaris(periode, n)
3. get_margin_per_produk()
4. get_stok_menipis()
5. get_tren_penjualan(granularity)
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Optional

import pandas as pd


class SupriBusinessTools:
    """Deterministic business analytics engine reading from processed CSVs."""

    def __init__(self, data_dir: str | Path = "data/processed") -> None:
        self.data_dir = Path(data_dir)
        self.load_data()

    def load_data(self) -> None:
        produk_path = self.data_dir / "produk.csv"
        tx_path = self.data_dir / "transaksi.csv"
        exp_path = self.data_dir / "pengeluaran.csv"
        restock_path = self.data_dir / "restock.csv"

        if not (produk_path.exists() and tx_path.exists()):
            raise FileNotFoundError(
                f"Data files not found in {self.data_dir}. Run prepare_data.py first."
            )

        self.df_produk = pd.read_csv(produk_path)
        self.df_tx = pd.read_csv(tx_path)
        self.df_exp = pd.read_csv(exp_path) if exp_path.exists() else pd.DataFrame()
        self.df_restock = pd.read_csv(restock_path) if restock_path.exists() else pd.DataFrame()

        # Precompute mappings for fast joins
        self.cogs_map = dict(zip(self.df_produk["id"], self.df_produk["harga_beli"]))
        self.price_map = dict(zip(self.df_produk["id"], self.df_produk["harga_jual"]))
        self.name_map = dict(zip(self.df_produk["id"], self.df_produk["nama"]))
        self.category_map = dict(zip(self.df_produk["id"], self.df_produk["kategori"]))

        # Normalize dates
        self.df_tx["tanggal_dt"] = pd.to_datetime(self.df_tx["tanggal"])
        self.df_tx["date_only"] = self.df_tx["tanggal"].str[:10]
        self.df_tx["cogs_satuan"] = self.df_tx["produk_id"].map(self.cogs_map).fillna(0)

        if not self.df_exp.empty:
            self.df_exp["tanggal_dt"] = pd.to_datetime(self.df_exp["tanggal"])
            self.df_exp["date_only"] = self.df_exp["tanggal"].str[:10]

    def _filter_period(
        self, df: pd.DataFrame, date_col: str, periode: str
    ) -> pd.DataFrame:
        """Filter dataframe by period string: 'all', 'YYYY-MM', 'YYYY-Qx', or 'YYYY-MM-DD:YYYY-MM-DD'."""
        if not periode or periode.lower() == "all":
            return df

        periode = periode.strip()

        # Date range YYYY-MM-DD:YYYY-MM-DD
        if ":" in periode:
            start_str, end_str = periode.split(":", 1)
            start_dt = pd.to_datetime(start_str.strip())
            end_dt = pd.to_datetime(end_str.strip())
            return df[(df[date_col] >= start_dt) & (df[date_col] <= end_dt)]

        # Quarter YYYY-Q1
        if "-q" in periode.lower():
            year_str, q_str = periode.lower().split("-q")
            year = int(year_str)
            q = int(q_str)
            start_month = (q - 1) * 3 + 1
            end_month = start_month + 2
            start_dt = pd.Timestamp(year, start_month, 1)
            end_dt = (
                pd.Timestamp(year, end_month + 1, 1) - pd.Timedelta(days=1)
                if end_month < 12
                else pd.Timestamp(year, 12, 31)
            )
            return df[(df[date_col] >= start_dt) & (df[date_col] <= end_dt)]

        # Monthly YYYY-MM
        if len(periode) == 7 and periode[4] == "-":
            return df[df[date_col].dt.strftime("%Y-%m") == periode]

        # Specific day YYYY-MM-DD
        if len(periode) == 10 and periode[4] == "-" and periode[7] == "-":
            return df[df[date_col].dt.strftime("%Y-%m-%d") == periode]

        return df

    def get_ringkasan_keuangan(self, periode: str = "all") -> dict[str, Any]:
        """Menghitung ringkasan laba rugi lengkap UMKM untuk periode tertentu."""
        tx_filtered = self._filter_period(self.df_tx, "tanggal_dt", periode)
        exp_filtered = (
            self._filter_period(self.df_exp, "tanggal_dt", periode)
            if not self.df_exp.empty
            else pd.DataFrame()
        )

        total_omzet = int(
            (tx_filtered["qty"] * tx_filtered["harga_satuan"] - tx_filtered["diskon"]).sum()
        )
        total_hpp = int((tx_filtered["qty"] * tx_filtered["cogs_satuan"]).sum())
        laba_kotor = total_omzet - total_hpp
        margin_kotor_pct = round((laba_kotor / total_omzet * 100), 2) if total_omzet > 0 else 0.0

        total_beban_operasional = (
            int(exp_filtered["jumlah"].sum()) if not exp_filtered.empty else 0
        )
        laba_bersih = laba_kotor - total_beban_operasional
        margin_bersih_pct = (
            round((laba_bersih / total_omzet * 100), 2) if total_omzet > 0 else 0.0
        )

        total_transaksi = int(tx_filtered["receipt_number"].nunique())
        total_item_terjual = int(tx_filtered["qty"].sum())
        avg_basket_size = (
            round(total_omzet / total_transaksi, 2) if total_transaksi > 0 else 0.0
        )

        breakdown_beban = (
            exp_filtered.groupby("kategori")["jumlah"].sum().to_dict()
            if not exp_filtered.empty
            else {}
        )

        metode_bayar = tx_filtered["metode_bayar"].value_counts().to_dict()

        return {
            "periode": periode,
            "total_omzet": total_omzet,
            "total_hpp": total_hpp,
            "laba_kotor": laba_kotor,
            "margin_kotor_pct": margin_kotor_pct,
            "total_beban_operasional": total_beban_operasional,
            "laba_bersih": laba_bersih,
            "margin_bersih_pct": margin_bersih_pct,
            "total_transaksi": total_transaksi,
            "total_item_terjual": total_item_terjual,
            "rata_rata_transaksi": avg_basket_size,
            "rincian_beban": breakdown_beban,
            "metode_pembayaran": metode_bayar,
        }

    def get_produk_terlaris(
        self, periode: str = "all", n: int = 5
    ) -> list[dict[str, Any]]:
        """Mendapatkan daftar n produk terlaris berdasarkan kuantitas terjual."""
        tx_filtered = self._filter_period(self.df_tx, "tanggal_dt", periode)
        total_omzet_periode = (
            tx_filtered["qty"] * tx_filtered["harga_satuan"] - tx_filtered["diskon"]
        ).sum()

        grouped = (
            tx_filtered.groupby("produk_id")
            .agg(
                qty_terjual=("qty", "sum"),
                omzet=(
                    "harga_satuan",
                    lambda s: (s * tx_filtered.loc[s.index, "qty"]).sum(),
                ),
            )
            .reset_index()
        )

        grouped = grouped.sort_values(
            by=["qty_terjual", "omzet"], ascending=[False, False]
        ).head(n)

        results: list[dict[str, Any]] = []
        for rank, (_, row) in enumerate(grouped.iterrows(), start=1):
            pid = int(row["produk_id"])
            qty = int(row["qty_terjual"])
            omzet = int(row["omzet"])
            kontribusi = (
                round((omzet / total_omzet_periode * 100), 2)
                if total_omzet_periode > 0
                else 0.0
            )

            results.append(
                {
                    "peringkat": rank,
                    "produk_id": pid,
                    "nama_produk": self.name_map.get(pid, f"Produk #{pid}"),
                    "kategori": self.category_map.get(pid, "-"),
                    "harga_jual": self.price_map.get(pid, 0),
                    "qty_terjual": qty,
                    "total_omzet": omzet,
                    "kontribusi_omzet_pct": kontribusi,
                }
            )

        return results

    def get_margin_per_produk(self) -> list[dict[str, Any]]:
        """Menghitung margin keuntungan nominal dan persentase untuk setiap produk."""
        results: list[dict[str, Any]] = []

        for _, prod in self.df_produk.iterrows():
            pid = int(prod["id"])
            nama = str(prod["nama"])
            kategori = str(prod["kategori"])
            hb = int(prod["harga_beli"])
            hj = int(prod["harga_jual"])
            margin_nom = hj - hb
            margin_pct = round((margin_nom / hj * 100), 2) if hj > 0 else 0.0

            results.append(
                {
                    "produk_id": pid,
                    "nama": nama,
                    "kategori": kategori,
                    "harga_beli": hb,
                    "harga_jual": hj,
                    "margin_nominal": margin_nom,
                    "margin_pct": margin_pct,
                }
            )

        # Sort by margin_pct descending
        results.sort(key=lambda x: x["margin_pct"], reverse=True)
        return results

    def get_stok_menipis(self) -> list[dict[str, Any]]:
        """Mendeteksi produk yang stoknya sudah di bawah atau sama dengan stok minimum."""
        menipis = self.df_produk[
            self.df_produk["stok"] <= self.df_produk["stok_minimum"]
        ].copy()

        results: list[dict[str, Any]] = []
        for _, prod in menipis.iterrows():
            stok = int(prod["stok"])
            stok_min = int(prod["stok_minimum"])
            defisit = stok_min - stok
            status = "KRITIS" if stok <= int(stok_min * 0.5) else "MENIPIS"

            results.append(
                {
                    "produk_id": int(prod["id"]),
                    "nama": str(prod["nama"]),
                    "kategori": str(prod["kategori"]),
                    "stok": stok,
                    "stok_minimum": stok_min,
                    "defisit": defisit,
                    "status": status,
                    "rekomendasi_restock_qty": max(20, stok_min * 3 - stok),
                }
            )

        results.sort(key=lambda x: x["stok"])
        return results

    def get_tren_penjualan(
        self, granularity: str = "daily"
    ) -> list[dict[str, Any]]:
        """Menganalisis tren penjualan berdasarkan granularity ('daily', 'weekly', 'monthly')."""
        df = self.df_tx.copy()

        if granularity == "monthly":
            df["period"] = df["tanggal_dt"].dt.strftime("%Y-%m")
        elif granularity == "weekly":
            df["period"] = df["tanggal_dt"].dt.to_period("W").dt.start_time.dt.strftime("%Y-%m-%d")
        else:  # daily
            df["period"] = df["tanggal_dt"].dt.strftime("%Y-%m-%d")

        grouped = (
            df.groupby("period")
            .agg(
                omzet=(
                    "harga_satuan",
                    lambda s: int((s * df.loc[s.index, "qty"] - df.loc[s.index, "diskon"]).sum()),
                ),
                total_transaksi=("receipt_number", "nunique"),
                item_terjual=("qty", "sum"),
            )
            .reset_index()
        )

        results: list[dict[str, Any]] = []
        for _, row in grouped.iterrows():
            tx_count = int(row["total_transaksi"])
            omzet = int(row["omzet"])
            avg_basket = round(omzet / tx_count, 2) if tx_count > 0 else 0.0

            results.append(
                {
                    "periode": str(row["period"]),
                    "omzet": omzet,
                    "total_transaksi": tx_count,
                    "item_terjual": int(row["item_terjual"]),
                    "rata_rata_basket": avg_basket,
                }
            )

        return results


# ============================================================================
# GEMINI FUNCTION CALLING TOOL DECLARATIONS
# ============================================================================

GEMINI_TOOL_DECLARATIONS = [
    {
        "name": "get_ringkasan_keuangan",
        "description": (
            "Menghitung metrik laba rugi, omzet, HPP, margin kotor, beban operasional, "
            "dan laba bersih UMKM secara deterministik. Parameter periode bisa 'all', "
            "'2025-01' (bulanan), '2025-Q1' (kuartal), atau '2025-01-01:2025-03-31'."
        ),
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "periode": {
                    "type": "STRING",
                    "description": "Periode kalkulasi (misal: 'all', '2025-01', '2025-Q1', atau 'YYYY-MM-DD:YYYY-MM-DD')",
                }
            },
            "required": ["periode"],
        },
    },
    {
        "name": "get_produk_terlaris",
        "description": (
            "Mengambil n produk dengan volume penjualan tertinggi pada periode tertentu "
            "beserta total omzet dan kontribusinya terhadap omzet toko."
        ),
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "periode": {
                    "type": "STRING",
                    "description": "Periode penjualan (default: 'all')",
                },
                "n": {
                    "type": "INTEGER",
                    "description": "Jumlah produk terlaris yang diambil (default: 5)",
                },
            },
            "required": [],
        },
    },
    {
        "name": "get_margin_per_produk",
        "description": (
            "Menghitung margin keuntungan nominal dan margin persentase untuk setiap produk "
            "dari harga jual dan harga beli."
        ),
        "parameters": {
            "type": "OBJECT",
            "properties": {},
        },
    },
    {
        "name": "get_stok_menipis",
        "description": (
            "Mendeteksi produk-produk yang stoknya saat ini berada di bawah atau sama dengan stok minimum, "
            "lengkap dengan status kritis dan rekomendasi restock."
        ),
        "parameters": {
            "type": "OBJECT",
            "properties": {},
        },
    },
    {
        "name": "get_tren_penjualan",
        "description": (
            "Menganalisis tren penjualan historis (omzet, jumlah transaksi, item terjual, basket size) "
            "dengan agregasi harian ('daily'), mingguan ('weekly'), atau bulanan ('monthly')."
        ),
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "granularity": {
                    "type": "STRING",
                    "description": "Tingkat agregasi tren: 'daily', 'weekly', atau 'monthly'",
                    "enum": ["daily", "weekly", "monthly"],
                }
            },
            "required": ["granularity"],
        },
    },
]


def execute_tool_call(
    engine: SupriBusinessTools, tool_name: str, arguments: dict[str, Any]
) -> dict[str, Any]:
    """Execute tool call from Gemini and return JSON-serializable summary."""
    if tool_name == "get_ringkasan_keuangan":
        return engine.get_ringkasan_keuangan(arguments.get("periode", "all"))
    elif tool_name == "get_produk_terlaris":
        return engine.get_produk_terlaris(
            arguments.get("periode", "all"), int(arguments.get("n", 5))
        )
    elif tool_name == "get_margin_per_produk":
        return {"produk": engine.get_margin_per_produk()}
    elif tool_name == "get_stok_menipis":
        return {"stok_menipis": engine.get_stok_menipis()}
    elif tool_name == "get_tren_penjualan":
        return {"tren": engine.get_tren_penjualan(arguments.get("granularity", "daily"))}
    else:
        raise ValueError(f"Unknown tool name: {tool_name}")


if __name__ == "__main__":
    print("Testing SupriBusinessTools...")
    engine = SupriBusinessTools()

    fin = engine.get_ringkasan_keuangan("all")
    print("\n--- Ringkasan Keuangan (All) ---")
    print(f"Omzet: Rp {fin['total_omzet']:,}")
    print(f"HPP: Rp {fin['total_hpp']:,}")
    print(f"Laba Kotor: Rp {fin['laba_kotor']:,} ({fin['margin_kotor_pct']}%)")
    print(f"Beban Operasional: Rp {fin['total_beban_operasional']:,}")
    print(f"Laba Bersih: Rp {fin['laba_bersih']:,} ({fin['margin_bersih_pct']}%)")

    top5 = engine.get_produk_terlaris("all", 5)
    print("\n--- Top 5 Produk Terlaris ---")
    for p in top5:
        print(f"#{p['peringkat']} {p['nama_produk']}: {p['qty_terjual']} pcs | Rp {p['total_omzet']:,}")

    menipis = engine.get_stok_menipis()
    print(f"\n--- Produk Stok Menipis ({len(menipis)} item) ---")
    for m in menipis[:5]:
        print(f"[{m['status']}] {m['nama']}: Stok {m['stok']} / Min {m['stok_minimum']}")

    monthly_tren = engine.get_tren_penjualan("monthly")
    print(f"\n--- Tren Bulanan ({len(monthly_tren)} bulan) ---")
    for t in monthly_tren:
        print(f"{t['periode']}: Omzet Rp {t['omzet']:,} | {t['total_transaksi']} trx")
