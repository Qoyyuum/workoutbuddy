import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  late AudioPlayer _audioPlayer;
  
  SoundService() {
    _audioPlayer = AudioPlayer();
    debugPrint('🔊 SoundService: AudioPlayer initialized');
  }
  
  void dispose() {
    _audioPlayer.dispose();
    debugPrint('🔊 SoundService: AudioPlayer disposed');
  }
  
  Future<void> playBeep() async {
    debugPrint('🔊 SoundService: playBeep() called');
    try {
      await _audioPlayer.play(AssetSource('audio/sounds/selectA.mp3'));
      debugPrint('🔊 SoundService: selectA.mp3 played successfully');
      // Also add haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('❌ SoundService: Failed to play selectA.mp3: $e');
      // Fallback to system sound
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    }
    debugPrint('🔊 SoundService: playBeep() completed');
  }

  Future<void> playMenuSound() async {
    debugPrint('🔊 SoundService: playMenuSound() called');
    try {
      await _audioPlayer.play(AssetSource('audio/sounds/selectB.mp3'));
      debugPrint('🔊 SoundService: selectB.mp3 played successfully');
      // Also add haptic feedback
      HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('❌ SoundService: Failed to play selectB.mp3: $e');
      // Fallback to system sound
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.selectionClick();
    }
    debugPrint('🔊 SoundService: playMenuSound() completed');
  }

  Future<void> playErrorSound() async {
    debugPrint('🔊 SoundService: playErrorSound() called');
    try {
      await _audioPlayer.play(AssetSource('audio/sounds/selectC.mp3'));
      debugPrint('🔊 SoundService: selectC.mp3 played successfully');
      // Also add haptic feedback
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('❌ SoundService: Failed to play selectC.mp3: $e');
      // Fallback to system sound
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.heavyImpact();
    }
    debugPrint('🔊 SoundService: playErrorSound() completed');
  }
}
