#!/usr/bin/env python3
"""Supri AI Edge TTS Service (Natural Male Indonesian Voice: id-ID-ArdiNeural).

Implementation based on Edge TTS for Pakasir SUPRI AI:
- Voice: id-ID-ArdiNeural (Laki-laki Bahasa Indonesia)
- Default Tuning: rate="+8%", pitch="+0Hz"
- Free, zero API key required
- Provides CLI synthesis, Python async API, and FastAPI streaming endpoint (/api/tts).
"""

from __future__ import annotations

import argparse
import asyncio
import io
import re
import sys
from typing import AsyncGenerator, Optional

import edge_tts
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response, StreamingResponse

# Konfigurasi Suara Default SUPRI AI
DEFAULT_VOICE = "id-ID-ArdiNeural"
DEFAULT_RATE = "+8%"
DEFAULT_PITCH = "+0Hz"

# Preset Karakter Suara Supri
PRESETS = {
    "standar": {"rate": "+8%", "pitch": "+0Hz", "desc": "Responsif, jelas, dan natural (Rekomendasi Utama)"},
    "santai": {"rate": "+10%", "pitch": "+2Hz", "desc": "Santai & cepat tanggap"},
    "kalem": {"rate": "+0%", "pitch": "-4Hz", "desc": "Kalem & berwibawa"},
}


def clean_text_for_tts(text: str) -> str:
    """Bersihkan teks dari format markdown dan karakter simbol agar intonasi alami.

    Menghilangkan tanda asterisk, backticks, hashtag, dan merapikan spasi serta tanda baca.
    """
    if not text:
        return ""

    # Hapus blok kode dan inline backtick
    text = re.sub(r"```[\s\S]*?```", "", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)

    # Hapus format markdown bold/italic (**teks**, *teks*, __teks__, _teks_)
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"\*([^*]+)\*", r"\1", text)
    text = re.sub(r"__([^_]+)__", r"\1", text)
    text = re.sub(r"_([^_]+)_", r"\1", text)

    # Hapus header markdown (# Header, ## Subheader)
    text = re.sub(r"^#+\s*", "", text, flags=re.MULTILINE)

    # Ubah bullet points (- item, * item) menjadi jeda koma/titik yang rapi
    text = re.sub(r"^[-*•]\s*", " ", text, flags=re.MULTILINE)

    # Ubah baris bernomor (1. Poin) menjadi format ramah baca
    text = re.sub(r"^\d+\.\s*", " ", text, flags=re.MULTILINE)

    # Hapus simbol khusus yang mengganggu pembacaan
    text = re.sub(r"[#*~`|<>{}\[\]\(\)]", " ", text)
    text = re.sub(r"(?<!\w)_|_(?!\w)", " ", text)
    # Rapikan spasi ganda dan baris baru
    text = re.sub(r"\s+", " ", text).strip()

    # Pastikan diakhiri dengan tanda baca agar intonasi penutup natural
    if text and text[-1] not in ".!?":
        text += "."

    return text


async def stream_audio_chunks(
    text: str,
    voice: str = DEFAULT_VOICE,
    rate: str = DEFAULT_RATE,
    pitch: str = DEFAULT_PITCH,
) -> AsyncGenerator[bytes, None]:
    """Streaming audio chunks MP3 langsung dari Edge TTS."""
    cleaned = clean_text_for_tts(text)
    if not cleaned:
        return

    communicate = edge_tts.Communicate(
        text=cleaned,
        voice=voice,
        rate=rate,
        pitch=pitch,
    )

    async for chunk in communicate.stream():
        if chunk.get("type") == "audio" and "data" in chunk:
            yield chunk["data"]


async def get_audio_bytes(
    text: str,
    voice: str = DEFAULT_VOICE,
    rate: str = DEFAULT_RATE,
    pitch: str = DEFAULT_PITCH,
) -> bytes:
    """Menghasilkan buffer audio MP3 utuh dalam memori."""
    audio_buffer = bytearray()
    async for chunk in stream_audio_chunks(text, voice=voice, rate=rate, pitch=pitch):
        audio_buffer.extend(chunk)
    return bytes(audio_buffer)


async def bicara_supri(
    teks: str,
    nama_file: str = "output_supri.mp3",
    voice: str = DEFAULT_VOICE,
    rate: str = DEFAULT_RATE,
    pitch: str = DEFAULT_PITCH,
) -> str:
    """Menghasilkan file audio MP3 di disk lokal."""
    cleaned = clean_text_for_tts(teks)
    if not cleaned:
        raise ValueError("Teks tidak boleh kosong.")

    communicate = edge_tts.Communicate(
        text=cleaned,
        voice=voice,
        rate=rate,
        pitch=pitch,
    )
    await communicate.save(nama_file)
    return nama_file


# Inisialisasi FastAPI App
app = FastAPI(
    title="Pakasir SUPRI AI Edge TTS API",
    description="Layanan Text-to-Speech gratis dan natural suara laki-laki Bahasa Indonesia (id-ID-ArdiNeural).",
    version="1.0.0",
)

# Aktifkan CORS agar frontend Web & Mobile dapat mengakses langsung
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
@app.get("/api/health")
async def health_check():
    return {
        "status": "ok",
        "service": "supri-edge-tts",
        "default_voice": DEFAULT_VOICE,
        "default_rate": DEFAULT_RATE,
        "default_pitch": DEFAULT_PITCH,
        "presets": PRESETS,
    }


@app.get("/api/tts")
async def tts_stream(
    text: str = Query(..., description="Teks yang akan diucapkan SUPRI"),
    preset: Optional[str] = Query(None, description="Preset gaya bicara: standar | santai | kalem"),
    voice: Optional[str] = Query(None, description="ID Suara (default: id-ID-ArdiNeural)"),
    rate: Optional[str] = Query(None, description="Kecepatan bicara (default: +8%)"),
    pitch: Optional[str] = Query(None, description="Tinggi nada suara (default: +0Hz)"),
):
    """Streaming audio MP3 langsung tanpa menyimpan file ke disk."""
    if not text or not text.strip():
        raise HTTPException(status_code=400, detail="Parameter 'text' tidak boleh kosong.")

    v = voice or DEFAULT_VOICE
    r = rate
    p = pitch

    if preset and preset.lower() in PRESETS:
        conf = PRESETS[preset.lower()]
        r = r or conf["rate"]
        p = p or conf["pitch"]

    r = r or DEFAULT_RATE
    p = p or DEFAULT_PITCH

    try:
        audio_stream = stream_audio_chunks(text, voice=v, rate=r, pitch=p)
        return StreamingResponse(
            audio_stream,
            media_type="audio/mpeg",
            headers={
                "Cache-Control": "public, max-age=3600",
                "Content-Disposition": 'inline; filename="supri_speech.mp3"',
                "X-Supri-Voice": v,
                "X-Supri-Rate": r,
                "X-Supri-Pitch": p,
            },
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gagal memproses Edge TTS: {str(e)}")


def main():
    parser = argparse.ArgumentParser(description="Supri AI Edge TTS CLI & API Server")
    parser.add_argument("--text", type=str, help="Teks yang ingin diucapkan oleh SUPRI")
    parser.add_argument("--output", type=str, default="output_supri.mp3", help="Nama file audio output (.mp3)")
    parser.add_argument("--voice", type=str, default=DEFAULT_VOICE, help="Voice ID (default: %(default)s)")
    parser.add_argument("--rate", type=str, default=DEFAULT_RATE, help="Rate suara (default: %(default)s)")
    parser.add_argument("--pitch", type=str, default=DEFAULT_PITCH, help="Pitch suara (default: %(default)s)")
    parser.add_argument("--preset", type=str, choices=list(PRESETS.keys()), help="Preset gaya bicara (standar, santai, kalem)")
    parser.add_argument("--serve", action="store_true", help="Jalankan server API FastAPI")
    parser.add_argument("--host", type=str, default="127.0.0.1", help="Host untuk server API")
    parser.add_argument("--port", type=int, default=8000, help="Port untuk server API")
    parser.add_argument("--stdout", action="store_true", help="Output audio biner langsung ke stdout")
    parser.add_argument("--stdin", action="store_true", help="Baca teks input dari stdin")

    args = parser.parse_args()

    if args.serve:
        import uvicorn
        print(f"Menjalankan SUPRI Edge TTS Server di http://{args.host}:{args.port}")
        uvicorn.run(app, host=args.host, port=args.port)
        return

    # Jika ada preset yang dipilih
    rate = args.rate
    pitch = args.pitch
    if args.preset:
        rate = PRESETS[args.preset]["rate"]
        pitch = PRESETS[args.preset]["pitch"]

    if args.stdin:
        text_to_speak = sys.stdin.read().strip()
    else:
        text_to_speak = args.text or "Halo! Saya Supri, asisten AI kamu. Ada yang bisa saya bantu hari ini?"

    if args.stdout:
        async def _stream_stdout():
            async for chunk in stream_audio_chunks(
                text_to_speak,
                voice=args.voice,
                rate=rate,
                pitch=pitch,
            ):
                sys.stdout.buffer.write(chunk)
            sys.stdout.buffer.flush()

        asyncio.run(_stream_stdout())
        return

    print(f"Mengonversi teks ke audio menggunakan suara '{args.voice}' (rate: {rate}, pitch: {pitch})...")
    print(f"Teks: \"{text_to_speak}\"")

    asyncio.run(bicara_supri(
        teks=text_to_speak,
        nama_file=args.output,
        voice=args.voice,
        rate=rate,
        pitch=pitch,
    ))
    print(f"Audio berhasil disimpan di: {args.output}")


if __name__ == "__main__":
    main()
