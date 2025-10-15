# Workout Gamification System

## Overview
The workout system gamifies your exercise routine by having your WorkoutBuddy mirror your workouts and gain stats based on your performance.

## Features

### 1. **Workout Types**
10 different workout types are supported:
- **Strength-based**: Push-ups, Pull-ups, Sit-ups, Squats, Lunges
- **Cardio-based**: Running, Walking, Jumping Jacks
- **Endurance-based**: Plank, Burpees

### 2. **Stat System**
Three main workout stats with temporary buffs:

#### **💪 Strength**
- Gained from: Push-ups, Pull-ups, Sit-ups, Squats, Lunges
- 1 point per rep

#### **⚡ Agility**
- Gained from: Running, Jumping Jacks
- 1 point per minute (running) or 2 points per rep (jumping)

#### **🏃 Endurance**
- Gained from: Walking, Plank, Burpees
- 1 point per minute

### 3. **Stat Buff System**
- **Temporary Buffs**: All workout gains are temporary buffs that last 2 hours
- **Decay Over Time**: Buffs gradually decay linearly over the 2-hour period
- **Stackable**: Multiple workouts stack their buffs
- **Base Stats**: Your permanent stats remain unchanged; buffs are additive

Example:
```
Base Strength: 10
After 10 push-ups: Strength = 10 (base) + 10 (buff) = 20
After 1 hour: Strength = 10 (base) + 5 (decayed buff) = 15
After 2 hours: Strength = 10 (base) + 0 (expired) = 10
```

### 4. **Animated Workout Buddy**
Your buddy performs different animations based on the workout:
- **Push-ups**: Pulsing scale animation with red glow
- **Sit-ups**: Rotation animation with orange glow
- **Squats**: Vertical compression with purple glow
- **Running**: Horizontal movement with green glow
- **Jumping**: Bounce animation with yellow glow
- **Walking**: Slow horizontal movement with light green border
- **Plank**: Static hold with brown border
- **Burpees**: Combined scale + bounce with intense red glow
- **Pull-ups**: Vertical bounce with blue glow
- **Lunges**: Side-to-side movement with indigo border

### 5. **Stat Gain Visualizations**
- **+X Animations**: See pixel-art style "+X" popups when you gain stats
- **Color-coded**: Each stat has its own color (Strength=Red, Agility=Yellow, Endurance=Green)
- **Floating Effect**: Stats float up and fade out for satisfying visual feedback
- **Staggered Display**: Multiple stat gains appear with a 200ms delay between each

## How to Use

### Starting a Workout
1. Press **Button B** to navigate to the **TRAIN** menu
2. Press **Button A** to open the workout screen
3. Select a workout type from the grid
4. Your buddy will start animating!

### During Workout
- **Manual Mode**: Press "Add Rep" button to log each rep
- **Auto Detection** (simulated): Reps are automatically detected every 3 seconds for testing
- **Timer**: Duration is tracked automatically
- **Stop**: Press "Stop" button when finished

### After Workout
- View your workout summary with total reps and duration
- See all stat gains listed
- Stats are automatically applied to your WorkoutBuddy
- Return to main screen to see updated stats on LCD display

## Technical Details

### File Structure
```
lib/
├── models/
│   ├── workout_type.dart          # Workout types, stat types, and buff system
│   ├── workout_session.dart       # Workout session data model
│   └── workout_buddy.dart         # Updated with agility, endurance, and buff system
├── services/
│   └── workout_detection_service.dart  # Workout detection and tracking
├── screens/
│   └── workout_screen.dart        # Main workout interface
└── widgets/
    ├── animated_workout_buddy.dart     # Animated buddy for each workout
    └── stat_gain_animation.dart        # Floating stat gain effects
```

### Key Classes

#### `WorkoutType` (Enum)
Defines all available workout types with their properties:
- `displayName`: User-friendly name
- `primaryStat`: Main stat affected
- `secondaryStat`: Optional secondary stat
- `primaryStatGain`: Points per rep/minute
- `secondaryStatGain`: Secondary points per rep/minute

#### `StatBuff` (Class)
Manages temporary stat buffs:
- `amount`: Initial buff amount
- `createdAt`: When buff was created
- `duration`: How long buff lasts (default 2 hours)
- `decayFactor`: Current decay multiplier (1.0 to 0.0)
- `currentAmount`: Current buff value after decay

#### `WorkoutSession` (Class)
Records workout data:
- `type`: Workout type performed
- `reps`: Number of reps completed
- `duration`: Total workout duration
- `statGains`: Map of stat gains earned

#### `WorkoutDetectionService` (Service)
Handles workout tracking:
- `startWorkoutDetection()`: Begin tracking a workout
- `stopWorkoutDetection()`: End workout and return session
- `addRep()`: Manually add a rep
- Platform-specific detection (Android/iOS/Web)

### Platform Support

#### Android
- ✅ Manual input mode (current)
- 🚧 Health Connect integration (planned)
- 🚧 Accelerometer-based detection (planned)

#### iOS
- ✅ Manual input mode (current)
- 🚧 HealthKit integration (planned)
- 🚧 Accelerometer-based detection (planned)

#### Web/Desktop
- ✅ Manual input mode (current)
- 🚧 Web sensor API integration (planned)

## Future Enhancements

### Planned Features
1. **Food Buffs/Debuffs**: Eating certain foods will buff or debuff stat gains
2. **Workout History**: Track and visualize workout progress over time
3. **Achievements**: Unlock badges for workout milestones
4. **Buddy Evolution**: Level up and evolve based on consistent workouts
5. **Real Sensor Integration**: Use device accelerometer for automatic rep detection
6. **Health Connect**: Sync with Google Health Connect on Android
7. **HealthKit**: Sync with Apple HealthKit on iOS
8. **Workout Programs**: Pre-defined workout routines
9. **Social Features**: Share workouts with friends
10. **Custom Workouts**: Create your own workout types

### Food System Integration (Next Phase)
The food diary system will be enhanced to provide:
- **Protein-rich foods**: +20% strength gains for 1 hour
- **Carb-rich foods**: +20% endurance gains for 1 hour
- **Healthy fats**: +20% agility gains for 1 hour
- **Junk food**: -10% all stat gains for 30 minutes
- **Hydration**: Prevents stat decay for 30 minutes

## Development Notes

### Testing
- Currently uses simulated rep detection for easy testing
- Manual "Add Rep" button available for precise control
- All platforms use same manual input mode for consistency

### Performance
- Animations run at 60 FPS using Flutter's AnimationController
- Stat calculations are O(1) complexity
- Buff decay is calculated on-demand, not continuously

### Customization
To adjust buff duration, edit `workout_buddy.dart`:
```dart
final buff = StatBuff(
  amount: amount,
  createdAt: DateTime.now(),
  duration: const Duration(hours: 2), // Change this value
);
```

To adjust stat gains per workout, edit `workout_type.dart`:
```dart
int get primaryStatGain {
  switch (this) {
    case WorkoutType.pushUp:
      return 1; // Change this value
    // ...
  }
}
```

## Credits
Built with Flutter and love for fitness! 💪🏃‍♂️⚡
