import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  late AudioPlayer _audioPlayer;
  
  SoundService() {
    _audioPlayer = AudioPlayer();
    print('🔊 SoundService: AudioPlayer initialized');
  }
  
  void dispose() {
    _audioPlayer.dispose();
    print('🔊 SoundService: AudioPlayer disposed');
  }
  
  Future<void> playBeep() async {
    print('🔊 SoundService: playBeep() called');
    try {
      await _audioPlayer.play(AssetSource('sounds/selectA.mp3'));
      print('🔊 SoundService: selectA.mp3 played successfully');
      // Also add haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      print('❌ SoundService: Failed to play selectA.mp3: $e');
      // Fallback to system sound
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    }
    print('🔊 SoundService: playBeep() completed');
  }

  Future<void> playMenuSound() async {
    print('🔊 SoundService: playMenuSound() called');
    try {
      await _audioPlayer.play(AssetSource('sounds/selectB.mp3'));
      print('🔊 SoundService: selectB.mp3 played successfully');
      // Also add haptic feedback
      HapticFeedback.selectionClick();
    } catch (e) {
      print('❌ SoundService: Failed to play selectB.mp3: $e');
      // Fallback to system sound
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.selectionClick();
    }
    print('🔊 SoundService: playMenuSound() completed');
  }

  Future<void> playErrorSound() async {
    print('🔊 SoundService: playErrorSound() called');
    try {
      await _audioPlayer.play(AssetSource('sounds/selectC.mp3'));
      print('🔊 SoundService: selectC.mp3 played successfully');
      // Also add haptic feedback
      HapticFeedback.heavyImpact();
    } catch (e) {
      print('❌ SoundService: Failed to play selectC.mp3: $e');
      // Fallback to system sound
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.heavyImpact();
    }
    print('🔊 SoundService: playErrorSound() completed');
  }
}
