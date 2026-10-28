// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class TtsPlatformService {
  static html.AudioElement? _activeAudio;

  static String _cleanText(String text) {
    if (text.isEmpty) return '';
    return text
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^[-*•]\s*', multiLine: true), ' ')
        .replaceAll(RegExp(r'^\d+\.\s*', multiLine: true), ' ')
        .replaceAll(RegExp(r'[#*_~`|<>{}\[\]]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static void speakNaturalMaleIndonesian(String text, {VoidCallback? onComplete}) {
    stop();
    final clean = _cleanText(text);
    if (clean.isEmpty) {
      onComplete?.call();
      return;
    }

    bool completed = false;
    void finish() {
      if (!completed) {
        completed = true;
        _activeAudio = null;
        onComplete?.call();
      }
    }

    void fallbackSpeechSynthesis() {
      try {
        if (html.window.speechSynthesis == null) {
          finish();
          return;
        }

        html.window.speechSynthesis!.cancel();
        final utterance = html.SpeechSynthesisUtterance(clean);
        utterance.lang = 'id-ID';
        // Pitch 0.88 - 0.90 gives a deeper, natural masculine tone in Indonesian SpeechSynthesis
        utterance.pitch = 0.88;
        utterance.rate = 1.0;

        // Select natural male voice if registered in browser voice list
        final voices = html.window.speechSynthesis!.getVoices();
        for (final v in voices) {
          final name = (v.name ?? '').toLowerCase();
          final lang = (v.lang ?? '').toLowerCase();
          if (lang.contains('id') || lang.contains('indonesia')) {
            if (name.contains('ardi') ||
                name.contains('natural') ||
                name.contains('male') ||
                name.contains('pria') ||
                name.contains('cowo') ||
                name.contains('david') ||
                name.contains('budi')) {
              utterance.voice = v;
              break;
            }
          }
        }

        utterance.onEnd.listen((_) => finish());
        utterance.onError.listen((_) => finish());
        html.window.speechSynthesis!.speak(utterance);
      } catch (_) {
        finish();
      }
    }

    // Panggil Endpoint Edge TTS (id-ID-ArdiNeural, rate=+8%, pitch=+0Hz)
    final queryParams =
        'text=${Uri.encodeComponent(clean)}&voice=id-ID-ArdiNeural&rate=%2B8%25&pitch=%2B0Hz&preset=standar';
    final candidateUrls = [
      '/api/tts?$queryParams',
      'http://127.0.0.1:8001/api/tts?$queryParams',
      'http://localhost:8000/api/tts?$queryParams',
    ];

    int candidateIdx = 0;
    void tryCandidate() {
      if (candidateIdx < candidateUrls.length) {
        final url = candidateUrls[candidateIdx++];
        try {
          final audio = html.AudioElement(url);
          _activeAudio = audio;

          audio.onEnded.listen((_) => finish());
          audio.onError.listen((_) {
            _activeAudio = null;
            tryCandidate();
          });

          audio.play().catchError((_) {
            _activeAudio = null;
            tryCandidate();
          });
        } catch (_) {
          tryCandidate();
        }
      } else {
        fallbackSpeechSynthesis();
      }
    }

    tryCandidate();
  }

  static void stop() {
    try {
      if (_activeAudio != null) {
        _activeAudio!.pause();
        _activeAudio!.currentTime = 0;
        _activeAudio = null;
      }
      html.window.speechSynthesis?.cancel();
    } catch (_) {}
  }
}
