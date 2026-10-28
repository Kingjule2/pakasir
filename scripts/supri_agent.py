#!/usr/bin/env python3
"""Supri AI Agent - UMKM Business & Financial Consultant.

Combines deterministic tools with Gemini Function Calling & System Prompt.
Follows strict business consultant rules:
1. Wajib pakai angka riil dari tools.
2. Dilarang mengarang/halusinasi data.
3. Memberikan 3 rekomendasi konkret yang bisa dieksekusi minggu ini.
4. Gaya bahasa santai, asik, hangat, dan solutif ala partner bisnis terpercaya.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any, Optional
import urllib.request
import urllib.error
try:
    from .supri_tools import (
        GEMINI_TOOL_DECLARATIONS,
        SupriBusinessTools,
        execute_tool_call,
    )
except ImportError:
    from supri_tools import (
        GEMINI_TOOL_DECLARATIONS,
        SupriBusinessTools,
        execute_tool_call,
    )

SUPRI_SYSTEM_PROMPT = """\
Kamu adalah Supri, AI Konsultan Bisnis, Keuangan, dan Pemasaran khusus UMKM Indonesia yang cerdas, asik, dan berpengalaman.

=== PERAN & KARAKTER ===
1. Gaya Bicara: Gunakan Bahasa Indonesia santai, akrab, luwes, dan bersahabat (panggil pengguna dengan "Bos", "Bro", atau "Kak"). Hindari bahasa robot atau birokrasi kaku.
2. Integritas Data (ZERO HALLUCINATION):
   - Kamu WAJIB mengambil data dan angka dari tools yang disediakan (get_ringkasan_keuangan, get_produk_terlaris, get_margin_per_produk, get_stok_menipis, get_tren_penjualan).
   - DILARANG KERAS mengarang, mengasumsikan, atau menebak angka omzet, HPP, margin, atau stok jika tidak ada di hasil tools.
   - Jika data belum tersedia untuk parameter tertentu, nyatakan terus terang apa adanya dengan ramah.
3. Output Actionable:
   - Setiap memberikan analisa, sertakan fakta angka kunci yang relevan dari tools.
   - WAJIB berikan TEPAT 3 REKOMENDASI KONKRET & REALISTIS yang bisa langsung dieksekusi oleh pemilik toko MINGGU INI (misal: bundling menu laris dengan margin tebal, restock item kritis sebelum weekend, atau efisiensi pos beban tertentu).
"""


class SupriAgentRunner:
    """Agent coordinator executing Gemini function calling with deterministic business tools."""

    def __init__(
        self,
        tools_engine: Optional[SupriBusinessTools] = None,
        api_key: Optional[str] = None,
        model: str = "gemini-1.5-flash",
    ) -> None:
        self.engine = tools_engine or SupriBusinessTools()
        self.api_key = api_key or os.getenv("GEMINI_API_KEY", "")
        self.model = model

    def consult(self, user_query: str) -> dict[str, Any]:
        """Run consultation turn using Gemini Function Calling or offline deterministic mode."""
        # Check if API key is provided
        if not self.api_key:
            return self._consult_offline_fallback(user_query)

        # Call Gemini API with function calling
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent?key={self.api_key}"

        tools_spec = [
            {
                "function_declarations": GEMINI_TOOL_DECLARATIONS,
            }
        ]

        payload = {
            "system_instruction": {
                "parts": [{"text": SUPRI_SYSTEM_PROMPT}],
            },
            "contents": [
                {
                    "role": "user",
                    "parts": [{"text": user_query}],
                }
            ],
            "tools": tools_spec,
            "tool_config": {
                "function_calling_config": {
                    "mode": "AUTO"
                }
            }
        }

        try:
            req = urllib.request.Request(
                url,
                data=json.dumps(payload).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=30) as resp:
                res_data = json.loads(resp.read().decode("utf-8"))

            candidates = res_data.get("candidates", [])
            if not candidates:
                return self._consult_offline_fallback(user_query)

            first_candidate = candidates[0]
            parts = first_candidate.get("content", {}).get("parts", [])

            # Check for function call
            function_calls = [p["functionCall"] for p in parts if "functionCall" in p]

            if not function_calls:
                # Direct answer
                text_parts = [p.get("text", "") for p in parts if "text" in p]
                return {
                    "response": "\n".join(text_parts),
                    "tools_called": [],
                }

            # Execute tool calls
            tool_results = []
            conversation_history = [
                {"role": "user", "parts": [{"text": user_query}]},
                {"role": "model", "parts": parts},
            ]

            function_responses = []
            for fc in function_calls:
                func_name = fc["name"]
                func_args = fc.get("args", {})
                result = execute_tool_call(self.engine, func_name, func_args)
                tool_results.append({"tool": func_name, "args": func_args, "result": result})

                function_responses.append(
                    {
                        "functionResponse": {
                            "name": func_name,
                            "response": {"result": result},
                        }
                    }
                )

            conversation_history.append({"role": "function", "parts": function_responses})

            # Second turn to Gemini with function results
            second_payload = {
                "system_instruction": {"parts": [{"text": SUPRI_SYSTEM_PROMPT}]},
                "contents": conversation_history,
            }

            req2 = urllib.request.Request(
                url,
                data=json.dumps(second_payload).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req2, timeout=30) as resp2:
                res_data2 = json.loads(resp2.read().decode("utf-8"))

            parts2 = res_data2.get("candidates", [{}])[0].get("content", {}).get("parts", [])
            final_text = "\n".join(p.get("text", "") for p in parts2 if "text" in p)

            return {
                "response": final_text,
                "tools_called": tool_results,
            }

        except Exception as e:
            # Fallback to deterministic synthesis if network or quota issue
            offline = self._consult_offline_fallback(user_query)
            offline["api_notice"] = f"Gemini API offline ({e}), running deterministic fallback."
            return offline

    def _consult_offline_fallback(self, query: str) -> dict[str, Any]:
        """Deterministic advisor engine when running offline without Gemini API key."""
        q_lower = query.lower()
        tools_called = []

        fin = self.engine.get_ringkasan_keuangan("all")
        tools_called.append({"tool": "get_ringkasan_keuangan", "args": {"periode": "all"}, "result": fin})

        top5 = self.engine.get_produk_terlaris("all", 5)
        tools_called.append({"tool": "get_produk_terlaris", "args": {"periode": "all", "n": 5}, "result": top5})

        stok = self.engine.get_stok_menipis()
        tools_called.append({"tool": "get_stok_menipis", "args": {}, "result": stok})

        tren = self.engine.get_tren_penjualan("monthly")
        tools_called.append({"tool": "get_tren_penjualan", "args": {"granularity": "monthly"}, "result": tren})

        # Produce consultant synthesis
        top_name = top5[0]["nama_produk"] if top5 else "Produk"
        top_qty = top5[0]["qty_terjual"] if top5 else 0

        stok_alert = (
            f"Ada {len(stok)} produk yang stoknya menipis/kritis ({', '.join([s['nama'] for s in stok[:3]])})."
            if stok
            else "Kondisi stok saat ini aman terkendali."
        )

        response = f"""\
Halo Bos! Supri di sini, udah gue bedah tuntas nih performa toko dari data kasir riil kita:

📊 **Kondisi Keuangan & Penjualan (Jan - Sep 2025):**
- **Total Omzet:** Rp {fin['total_omzet']:,} (dari {fin['total_transaksi']:,} transaksi dan {fin['total_item_terjual']:,} item terjual).
- **HPP (Beban Pokok Penjualan):** Rp {fin['total_hpp']:,}
- **Laba Kotor Toko:** Rp {fin['laba_kotor']:,} (Gross Margin: {fin['margin_kotor_pct']}%)
- **Total Beban Operasional:** Rp {fin['total_beban_operasional']:,}
- **Laba Bersih:** Rp {fin['laba_bersih']:,} ({fin['margin_bersih_pct']}%)
- **Produk Terlaris #1:** {top_name} laku sebanyak {top_qty} cup/porsi!
- **Status Stok:** {stok_alert}

💡 **3 Rekomendasi Taktis Supri untuk Dijalankan MINGGU INI:**
1. **Buat Paket Combo/Bundling Produk Juara ({top_name}):**
   Padukan produk terlaris seperti {top_name} dengan snack ber-margin tebal (misal roti atau pastry). Ini langsung mendongkrak rata-rata belanja kasir (saat ini Rp {fin['rata_rata_transaksi']:,.0f}/struk) tanpa nambah biaya akuisisi pelanggan baru.
2. **Restock Cepat Sebelum Weekend untuk Item Menipis:**
   Segera terbitkan PO restock untuk {len(stok)} item yang stoknya menyentuh batas minimum ({', '.join([s['nama'] for s in stok[:2]])}) agar toko tidak kehilangan omzet akibat kehabisan stok saat jam ramai.
3. **Optimasi Pos Pengeluaran Sewa & Utilitas:**
   Total pengeluaran operasional mencapai Rp {fin['total_beban_operasional']:,}. Cek kembali efisiensi daya listrik mesin espresso saat jam sepi dan negosiasikan termin pembayaran sewa outlet agar arus kas harian tetap longgar.
"""
        return {
            "response": response,
            "tools_called": tools_called,
        }


if __name__ == "__main__":
    runner = SupriAgentRunner()
    result = runner.consult("Pri, tolong evaluasi performa toko dan kasih saran strategi minggu ini!")
    print(result["response"])
    print(f"\n[Tools Executed]: {[t['tool'] for t in result['tools_called']]}")
