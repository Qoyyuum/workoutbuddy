import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FlameSoundService {
  FlameSoundService() {
    debugPrint('🔊 FlameSoundService: Initialized');
  }
  
  void dispose() {
    debugPrint('🔊 FlameSoundService: Disposed');
  }
  
  Future<void> playBeep() async {
    debugPrint('🔊 FlameSoundService: playBeep() called');
    try {
      await FlameAudio.play('sounds/selectA.mp3');
      debugPrint('🔊 FlameSoundService: selectA.mp3 played successfully');
      // Also add haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('❌ FlameSoundService: Failed to play selectA.mp3: $e');
      // Fallback to system sound
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    }
    debugPrint('🔊 FlameSoundService: playBeep() completed');
  }

  Future<void> playMenuSound() async {
    debugPrint('🔊 FlameSoundService: playMenuSound() called');
    try {
      await FlameAudio.play('sounds/selectB.mp3');
      debugPrint('🔊 FlameSoundService: selectB.mp3 played successfully');
      // Also add haptic feedback
      HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('❌ FlameSoundService: Failed to play selectB.mp3: $e');
      // Fallback to system sound
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.selectionClick();
    }
    debugPrint('🔊 FlameSoundService: playMenuSound() completed');
  }

  Future<void> playErrorSound() async {
    debugPrint('🔊 FlameSoundService: playErrorSound() called');
    try {
      await FlameAudio.play('sounds/selectC.mp3');
      debugPrint('🔊 FlameSoundService: selectC.mp3 played successfully');
      // Also add haptic feedback
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('❌ FlameSoundService: Failed to play selectC.mp3: $e');
      // Fallback to system sound
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.heavyImpact();
    }
    debugPrint('🔊 FlameSoundService: playErrorSound() completed');
  }
}
