import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformUtils {
  /// Check if running on Wear OS
  static bool isWearOS() {
    if (kIsWeb) return false;
    
    // On Android, check for Wear OS characteristics
    if (Platform.isAndroid) {
      // Wear OS typically has small screen dimensions
      // This is a simple heuristic - can be refined
      return false; // Will be detected via screen size in UI
    }
    
    return false;
  }
  
  /// Check if screen is small (watch-like dimensions)
  static bool isSmallScreen(double width, double height) {
    // Wear OS watches are typically under 400x400 pixels
    return width < 500 && height < 500;
  }
  
  /// Check if screen is circular
  static bool isCircularScreen(double width, double height) {
    // If width and height are nearly equal, likely circular
    final ratio = width / height;
    return ratio > 0.9 && ratio < 1.1;
  }
}
