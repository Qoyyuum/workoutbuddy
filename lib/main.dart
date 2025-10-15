import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/workoutbuddy_screen.dart';
import 'screens/workoutbuddy_wear_screen.dart';

Future<void> main() async {
  // Load environment variables
  await dotenv.load(fileName: '.env.local');
  
  runApp(const WorkoutBuddyApp());
}

class WorkoutBuddyApp extends StatelessWidget {
  const WorkoutBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Buddy',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: const Color(0xFF2C2C2C),
        fontFamily: 'Pixel Digivolve',
      ),
      home: const PlatformAwareHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Detects screen size and shows appropriate UI
class PlatformAwareHome extends StatelessWidget {
  const PlatformAwareHome({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        
        // If screen is small (watch-sized), use Wear UI
        final isSmallScreen = width < 500 && height < 500;
        
        if (isSmallScreen) {
          debugPrint('🕐 Wear OS detected ($width x $height) - Using simplified UI');
          return const WorkoutbuddyWearScreen();
        } else {
          debugPrint('📱 Phone/Tablet detected ($width x $height) - Using full UI');
          return const WorkoutbuddyScreen();
        }
      },
    );
  }
}
