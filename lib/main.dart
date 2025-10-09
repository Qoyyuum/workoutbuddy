import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/digivice_screen.dart';

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
      home: const DigiviceScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
