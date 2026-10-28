import 'package:flutter/foundation.dart';
import 'tts_service_stub.dart'
    if (dart.library.html) 'tts_service_web.dart' as impl;

class TtsService {
  /// Spesifikasi Suara Natural Laki-Laki SUPRI AI via Edge TTS
  static const String voiceId = 'id-ID-ArdiNeural';
  static const String defaultRate = '+8%';
  static const String defaultPitch = '+0Hz';

  /// Melakukan Text-to-Speech dengan suara cowo/pria natural Bahasa Indonesia (id-ID-ArdiNeural)
  static void speakNaturalMaleIndonesian(String text, {VoidCallback? onComplete}) {
    impl.TtsPlatformService.speakNaturalMaleIndonesian(text, onComplete: onComplete);
  }

  /// Menghentikan pemutaran suara
  static void stop() {
    impl.TtsPlatformService.stop();
  }
}
