import 'package:flutter/services.dart';

class SoundService {
  void playBeep() {
    // Generate a synthetic beep sound using haptic feedback
    HapticFeedback.lightImpact();
  }

  void playMenuSound() {
    HapticFeedback.selectionClick();
  }

  void playErrorSound() {
    HapticFeedback.heavyImpact();
  }
}
