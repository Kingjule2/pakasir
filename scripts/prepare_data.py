#!/usr/bin/env python3
"""ETL Data Preparation Script for Supri AI Agent (Pakasir UMKM).

Processes raw Mendeley Data (DOI: 10.17632/kcgf45y24m.2) into 4 normalized CSVs:
1. data/processed/produk.csv
2. data/processed/transaksi.csv
3. data/processed/pengeluaran.csv
4. data/processed/restock.csv

Deterministic synthetic generation with fixed random seed (42).
"""

from __future__ import annotations

import argparse
from datetime import datetime, timedelta
import os
from pathlib import Path
import random

import numpy as np
import pandas as pd

RANDOM_SEED = 42


def setup_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Prepare UMKM processed datasets")
    parser.add_argument(
        "--raw-dir",
        type=str,
        default="data/raw",
        help="Directory containing raw Products.csv and Transactions.csv",
    )
    parser.add_argument(
        "--out-dir",
        type=str,
        default="data/processed",
        help="Directory to write processed CSV files",
    )
    return parser.parse_args()


def process_products(raw_dir: Path, out_dir: Path) -> tuple[pd.DataFrame, dict[str, int]]:
    products_file = raw_dir / "Products.csv"
    if not products_file.exists():
        raise FileNotFoundError(f"Raw products file not found: {products_file}")

    df_raw = pd.read_csv(products_file)

    # Deterministic RNG
    rng = np.random.default_rng(RANDOM_SEED)

    # Build standardized name: ProductName (Variant) or ProductName
    df_raw["nama"] = df_raw.apply(
        lambda r: f"{r['ProductName']} ({r['Variant']})"
        if str(r["Variant"]).strip() not in ("-", "", "nan")
        else str(r["ProductName"]).strip(),
        axis=1,
    )

    id_list = df_raw["ProductId"].astype(int).tolist()
    nama_list = df_raw["nama"].tolist()
    kategori_list = df_raw["Category"].astype(str).tolist()
    harga_jual_list = df_raw["Price"].astype(int).tolist()

    harga_beli_list: list[int] = []
    stok_list: list[int] = []
    stok_min_list: list[int] = []

    for price in harga_jual_list:
        if price <= 0:
            # Add on with 0 price
            harga_beli_list.append(0)
            stok_list.append(int(rng.integers(100, 300)))
            stok_min_list.append(50)
        else:
            # Reasonable margin: COGS 50% - 70% of selling price
            cogs_ratio = float(rng.uniform(0.52, 0.68))
            cogs = int(round((price * cogs_ratio) / 500) * 500)
            if cogs >= price:
                cogs = int(price * 0.6)
            harga_beli_list.append(cogs)

            # Realistic current stock & minimum threshold
            stok = int(rng.integers(10, 85))
            stok_min = int(rng.integers(8, 20))
            stok_list.append(stok)
            stok_min_list.append(stok_min)

    processed_df = pd.DataFrame(
        {
            "id": id_list,
            "nama": nama_list,
            "kategori": kategori_list,
            "harga_beli": harga_beli_list,
            "harga_jual": harga_jual_list,
            "stok": stok_list,
            "stok_minimum": stok_min_list,
            "is_synthetic": True,  # Contains synthetic cogs, stock, and stock_min
        }
    )

    out_file = out_dir / "produk.csv"
    processed_df.to_csv(out_file, index=False)
    print(f"[OK] Saved {len(processed_df)} products to {out_file}")

    # Map standardized name to product id
    name_to_id = dict(zip(processed_df["nama"], processed_df["id"]))
    return processed_df, name_to_id


def process_transactions(
    raw_dir: Path, out_dir: Path, name_to_id: dict[str, int], prod_df: pd.DataFrame
) -> pd.DataFrame:
    tx_file = raw_dir / "Transactions.csv"
    if not tx_file.exists():
        raise FileNotFoundError(f"Raw transactions file not found: {tx_file}")

    df_raw = pd.read_csv(tx_file)

    id_to_price = dict(zip(prod_df["id"], prod_df["harga_jual"]))

    records: list[dict] = []
    item_counter = 1

    for _, row in df_raw.iterrows():
        receipt = str(row["ReceiptNumber"]).strip()
        date_str = str(row["Date"]).strip()
        time_str = str(row["Time"]).strip()
        full_timestamp = f"{date_str} {time_str}"
        pay_method = str(row["PaymentMethod"]).strip()
        raw_items_str = str(row["Items"]).strip()

        # Split items by comma
        item_names = [p.strip() for p in raw_items_str.split(",") if p.strip()]

        for item_name in item_names:
            pid = name_to_id.get(item_name)
            if pid is None:
                # Fallback search if exact match fails
                matched = [p for p in name_to_id.keys() if p.lower() == item_name.lower()]
                if matched:
                    pid = name_to_id[matched[0]]
                else:
                    raise KeyError(f"Item not found in products: '{item_name}'")

            unit_price = id_to_price.get(pid, 0)

            records.append(
                {
                    "id": f"TRX-{item_counter:06d}",
                    "receipt_number": receipt,
                    "tanggal": full_timestamp,
                    "produk_id": pid,
                    "qty": 1,
                    "harga_satuan": unit_price,
                    "diskon": 0,
                    "metode_bayar": pay_method,
                    "is_synthetic": False,  # Real POS transaction data
                }
            )
            item_counter += 1

    tx_df = pd.DataFrame(records)
    out_file = out_dir / "transaksi.csv"
    tx_df.to_csv(out_file, index=False)
    print(f"[OK] Saved {len(tx_df)} transaction items to {out_file}")
    return tx_df


def generate_expenses(tx_df: pd.DataFrame, out_dir: Path) -> pd.DataFrame:
    """Generate realistic operational expenses for UMKM F&B across active period."""
    rng = np.random.default_rng(RANDOM_SEED)

    min_date = pd.to_datetime(tx_df["tanggal"].str[:10].min())
    max_date = pd.to_datetime(tx_df["tanggal"].str[:10].max())

    # Generate monthly recurring expenses
    months = pd.date_range(min_date.replace(day=1), max_date.replace(day=1), freq="MS")

    records: list[dict] = []

    for month_start in months:
        m_str = month_start.strftime("%Y-%m")

        # 1. Sewa Tempat 3 Outlet (~Rp 8jt - 12jt per outlet)
        sewa_tgl = f"{m_str}-01"
        records.append(
            {
                "tanggal": sewa_tgl,
                "kategori": "Sewa Tempat",
                "jumlah": int(rng.integers(24_000_000, 30_000_000)),
                "is_synthetic": True,
            }
        )

        # 2. Gaji Karyawan (~Rp 18jt - 22jt per bulan)
        gaji_tgl = f"{m_str}-28" if month_start.month == 2 else f"{m_str}-25"
        records.append(
            {
                "tanggal": gaji_tgl,
                "kategori": "Gaji Karyawan",
                "jumlah": int(rng.integers(19_000_000, 23_000_000)),
                "is_synthetic": True,
            }
        )

        # 3. Listrik & Utilitas (~Rp 3.5jt - 5jt)
        listrik_tgl = f"{m_str}-10"
        records.append(
            {
                "tanggal": listrik_tgl,
                "kategori": "Listrik & Air",
                "jumlah": int(rng.integers(3_800_000, 5_200_000)),
                "is_synthetic": True,
            }
        )

        # 4. Internet & Langganan SaaS POS (~Rp 800rb - 1.2jt)
        internet_tgl = f"{m_str}-05"
        records.append(
            {
                "tanggal": internet_tgl,
                "kategori": "Internet & Software",
                "jumlah": int(rng.integers(850_000, 1_250_000)),
                "is_synthetic": True,
            }
        )

        # 5. Marketing, Promosi & Ads (~Rp 2jt - 4jt)
        mkt_tgl = f"{m_str}-15"
        records.append(
            {
                "tanggal": mkt_tgl,
                "kategori": "Marketing & Iklan",
                "jumlah": int(rng.integers(2_000_000, 3_800_000)),
                "is_synthetic": True,
            }
        )

        # 6. Perlengkapan Habis Pakai & Packaging (~Rp 2.5jt - 4.5jt)
        pack_tgl = f"{m_str}-18"
        records.append(
            {
                "tanggal": pack_tgl,
                "kategori": "Packaging & Perlengkapan",
                "jumlah": int(rng.integers(2_800_000, 4_500_000)),
                "is_synthetic": True,
            }
        )

        # 7. Pemeliharaan Mesin & Operasional Lain (random ~500rb - 1.5jt)
        maint_tgl = f"{m_str}-22"
        records.append(
            {
                "tanggal": maint_tgl,
                "kategori": "Maintenance & Reparasi",
                "jumlah": int(rng.integers(600_000, 1_800_000)),
                "is_synthetic": True,
            }
        )

    exp_df = pd.DataFrame(records).sort_values("tanggal").reset_index(drop=True)
    out_file = out_dir / "pengeluaran.csv"
    exp_df.to_csv(out_file, index=False)
    print(f"[OK] Saved {len(exp_df)} expense records to {out_file}")
    return exp_df


def generate_restock(
    prod_df: pd.DataFrame, tx_df: pd.DataFrame, out_dir: Path
) -> pd.DataFrame:
    """Generate periodic restock records based on real sales velocity."""
    rng = np.random.default_rng(RANDOM_SEED)

    # Get product sales counts
    sales_velocity = tx_df["produk_id"].value_counts().to_dict()

    dates = pd.date_range("2025-01-05", "2025-09-28", freq="W-MON")

    records: list[dict] = []

    for restock_date in dates:
        d_str = restock_date.strftime("%Y-%m-%d")

        # Pick 10-25 products to restock each week
        active_products = prod_df[prod_df["harga_jual"] > 0].copy()
        sampled = active_products.sample(n=rng.integers(12, 24), random_state=int(rng.integers(1, 99999)))

        for _, prod in sampled.iterrows():
            pid = int(prod["id"])
            cogs = int(prod["harga_beli"])
            velocity = sales_velocity.get(pid, 10)

            # Restock qty proportional to demand (weekly sales * 1.5 - 3x)
            weekly_est = max(5, int(velocity / 38))
            qty = int(rng.integers(weekly_est * 2, weekly_est * 4 + 10))

            records.append(
                {
                    "tanggal": d_str,
                    "produk_id": pid,
                    "qty": qty,
                    "harga_beli": cogs,
                    "is_synthetic": True,
                }
            )

    restock_df = pd.DataFrame(records).sort_values("tanggal").reset_index(drop=True)
    out_file = out_dir / "restock.csv"
    restock_df.to_csv(out_file, index=False)
    print(f"[OK] Saved {len(restock_df)} restock records to {out_file}")
    return restock_df


def main() -> None:
    args = setup_args()
    raw_dir = Path(args.raw_dir)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    print("=== Starting ETL Data Pipeline ===")
    print(f"Raw Dir: {raw_dir.resolve()}")
    print(f"Out Dir: {out_dir.resolve()}")

    prod_df, name_to_id = process_products(raw_dir, out_dir)
    tx_df = process_transactions(raw_dir, out_dir, name_to_id, prod_df)
    exp_df = generate_expenses(tx_df, out_dir)
    restock_df = generate_restock(prod_df, tx_df, out_dir)

    print("\n=== ETL Validation Checks ===")
    print(f"1. Produk count: {len(prod_df)} rows")
    print(f"2. Transaksi items count: {len(tx_df)} rows")
    print(f"3. Pengeluaran count: {len(exp_df)} rows | Total: Rp {exp_df['jumlah'].sum():,}")
    print(f"4. Restock count: {len(restock_df)} rows | Total qty: {restock_df['qty'].sum():,}")

    # Check for negative margins
    margins = prod_df["harga_jual"] - prod_df["harga_beli"]
    negative_margins = (margins < 0).sum()
    print(f"5. Produk dengan margin negatif: {negative_margins} (Must be 0)")
    assert negative_margins == 0, "Error: Found negative margins in products!"

    # Check missing values
    for name, df in [
        ("produk", prod_df),
        ("transaksi", tx_df),
        ("pengeluaran", exp_df),
        ("restock", restock_df),
    ]:
        nulls = df.isnull().sum().sum()
        print(f"6. Total nulls in {name}: {nulls}")
        assert nulls == 0, f"Error: Found null values in {name}!"

    print("\n=== ETL Pipeline Completed Successfully! ===")


if __name__ == "__main__":
    main()
