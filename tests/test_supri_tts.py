#!/usr/bin/env python3
"""Unit and Integration Tests for Supri AI Edge TTS Service.

Tests cover:
1. Text normalization & markdown stripping for natural conversational pauses.
2. Voice configuration constants (Voice ID: id-ID-ArdiNeural, rate: +8%, pitch: +0Hz).
3. Presets (standar, santai, kalem).
4. FastAPI Endpoints (/health, /api/tts streaming, validation).
5. Audio generation (MP3 chunks and file generation).
"""

from __future__ import annotations

import asyncio
import os
from pathlib import Path
import sys
import unittest

# Ensure scripts directory is available in path
REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPTS_DIR = REPO_ROOT / "scripts"
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

from fastapi.testclient import TestClient

from supri_tts import (
    DEFAULT_PITCH,
    DEFAULT_RATE,
    DEFAULT_VOICE,
    PRESETS,
    app,
    bicara_supri,
    clean_text_for_tts,
    get_audio_bytes,
)


class TestSupriTts(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.client = TestClient(app)

    def test_01_voice_constants_and_presets(self) -> None:
        """Verifikasi spesifikasi suara default dan tuning untuk SUPRI AI."""
        self.assertEqual(DEFAULT_VOICE, "id-ID-ArdiNeural")
        self.assertEqual(DEFAULT_RATE, "+8%")
        self.assertEqual(DEFAULT_PITCH, "+0Hz")

        self.assertIn("standar", PRESETS)
        self.assertIn("santai", PRESETS)
        self.assertIn("kalem", PRESETS)

        self.assertEqual(PRESETS["standar"]["rate"], "+8%")
        self.assertEqual(PRESETS["standar"]["pitch"], "+0Hz")
        self.assertEqual(PRESETS["santai"]["rate"], "+10%")
        self.assertEqual(PRESETS["santai"]["pitch"], "+2Hz")
        self.assertEqual(PRESETS["kalem"]["rate"], "+0%")
        self.assertEqual(PRESETS["kalem"]["pitch"], "-4Hz")

    def test_02_clean_text_for_tts(self) -> None:
        """Verifikasi pembersihan markdown dan format AI agar intonasi jelas."""
        raw_markdown = """\
# Laporan Penjualan
Halo **Bos**! Berikut ringkasannya:
- **Total Omzet:** Rp 1.500.000
- **Laba Bersih:** Rp 450.000
```json
{"status": "ok"}
```
Gunakan kode `RESTOCK_NOW` untuk pesan ulang."""

        cleaned = clean_text_for_tts(raw_markdown)

        # Markdown asterisks, backticks, and code blocks should be stripped
        self.assertNotIn("**", cleaned)
        self.assertNotIn("```", cleaned)
        self.assertNotIn("`RESTOCK_NOW`", cleaned)
        self.assertNotIn("# Laporan", cleaned)

        # Key text should remain readable
        self.assertIn("Halo Bos!", cleaned)
        self.assertIn("Total Omzet: Rp 1.500.000", cleaned)
        self.assertIn("Gunakan kode RESTOCK_NOW untuk pesan ulang.", cleaned)

        # Ends with proper punctuation
        self.assertTrue(cleaned.endswith("."))

    def test_03_health_endpoint(self) -> None:
        """Verifikasi endpoint health check mengembalikan metadata konfigurasi suara."""
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "ok")
        self.assertEqual(data["default_voice"], "id-ID-ArdiNeural")
        self.assertEqual(data["default_rate"], "+8%")
        self.assertEqual(data["default_pitch"], "+0Hz")

    def test_04_tts_endpoint_validation(self) -> None:
        """Verifikasi validasi input endpoint /api/tts."""
        # Query parameter text wajib ada
        res_empty = self.client.get("/api/tts")
        self.assertEqual(res_empty.status_code, 422)

        # Blank spaces string rejected
        res_blank = self.client.get("/api/tts?text=   ")
        self.assertEqual(res_blank.status_code, 400)

    def test_05_tts_endpoint_streaming(self) -> None:
        """Verifikasi streaming audio MP3 dari endpoint /api/tts."""
        response = self.client.get("/api/tts?text=Halo+bos+tes+suara+Supri")
        self.assertEqual(response.status_code, 200)
        self.assertIn("audio/mpeg", response.headers.get("content-type", ""))
        self.assertEqual(response.headers.get("x-supri-voice"), "id-ID-ArdiNeural")
        self.assertEqual(response.headers.get("x-supri-rate"), "+8%")
        self.assertEqual(response.headers.get("x-supri-pitch"), "+0Hz")
        self.assertGreater(len(response.content), 1000)

    def test_06_tts_endpoint_preset_kalem(self) -> None:
        """Verifikasi preset karakter suara (contoh: kalem) terapkan rate dan pitch sesuai."""
        response = self.client.get("/api/tts?text=Halo+bos&preset=kalem")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.headers.get("x-supri-rate"), "+0%")
        self.assertEqual(response.headers.get("x-supri-pitch"), "-4Hz")
        self.assertGreater(len(response.content), 1000)

    def test_07_python_async_get_audio_bytes(self) -> None:
        """Verifikasi pemanggilan fungsi Python async get_audio_bytes menghasilkan bytes audio MP3."""
        audio_data = asyncio.run(get_audio_bytes("Siap bos, pesanan sudah dicatat."))
        self.assertIsInstance(audio_data, bytes)
        self.assertGreater(len(audio_data), 1000)

    def test_08_python_async_bicara_supri_file(self) -> None:
        """Verifikasi fungsi bicara_supri menyimpan file .mp3 secara lokal."""
        test_file = "test_supri_temp_output.mp3"
        if os.path.exists(test_file):
            os.remove(test_file)

        try:
            saved_path = asyncio.run(
                bicara_supri(
                    teks="Halo! Saya Supri, asisten AI kamu.",
                    nama_file=test_file,
                )
            )
            self.assertEqual(saved_path, test_file)
            self.assertTrue(os.path.exists(test_file))
            size = os.path.getsize(test_file)
            self.assertGreater(size, 1000)
        finally:
            if os.path.exists(test_file):
                os.remove(test_file)


if __name__ == "__main__":
    unittest.main()
