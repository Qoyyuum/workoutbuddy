import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

class FlameSoundService {
  FlameSoundService() {
    print('🔊 FlameSoundService: Initialized');
  }
  
  void dispose() {
    print('🔊 FlameSoundService: Disposed');
  }
  
  Future<void> playBeep() async {
    print('🔊 FlameSoundService: playBeep() called');
    try {
      await FlameAudio.play('sounds/selectA.mp3');
      print('🔊 FlameSoundService: selectA.mp3 played successfully');
      // Also add haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      print('❌ FlameSoundService: Failed to play selectA.mp3: $e');
      // Fallback to system sound
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    }
    print('🔊 FlameSoundService: playBeep() completed');
  }

  Future<void> playMenuSound() async {
    print('🔊 FlameSoundService: playMenuSound() called');
    try {
      await FlameAudio.play('sounds/selectB.mp3');
      print('🔊 FlameSoundService: selectB.mp3 played successfully');
      // Also add haptic feedback
      HapticFeedback.selectionClick();
    } catch (e) {
      print('❌ FlameSoundService: Failed to play selectB.mp3: $e');
      // Fallback to system sound
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.selectionClick();
    }
    print('🔊 FlameSoundService: playMenuSound() completed');
  }

  Future<void> playErrorSound() async {
    print('🔊 FlameSoundService: playErrorSound() called');
    try {
      await FlameAudio.play('sounds/selectC.mp3');
      print('🔊 FlameSoundService: selectC.mp3 played successfully');
      // Also add haptic feedback
      HapticFeedback.heavyImpact();
    } catch (e) {
      print('❌ FlameSoundService: Failed to play selectC.mp3: $e');
      // Fallback to system sound
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.heavyImpact();
    }
    print('🔊 FlameSoundService: playErrorSound() completed');
  }
}
