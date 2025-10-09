# Digivice - Virtual Pet App

A Flutter-based recreation of the classic Digimon virtual pet toy, featuring procedurally generated pixel art creatures and virtual pet mechanics.

## Features

- **Procedurally Generated Digimon**: Each Digimon is created with unique 16x16 pixel art sprites generated algorithmically
- **Virtual Pet Mechanics**: Feed, train, and battle with your digital companion
- **LCD-Style Display**: Authentic retro LCD screen appearance with classic green monochrome styling
- **Evolution System**: Watch your Digimon grow and evolve as you care for it
- **Interactive Controls**: Three-button interface mimicking the original Digivice hardware
- **Haptic Feedback**: Synthetic "beep" sounds through device vibration

## Gameplay

### Controls
- **A Button (SELECT)**: Execute the current menu action
- **B Button (MENU)**: Cycle through menu options (Status, Feed, Train, Battle)
- **C Button (CANCEL)**: Cancel current action

### Menu Options
1. **STATUS**: View your Digimon's current stats and condition
2. **FEED**: Reduce hunger and increase happiness
3. **TRAIN**: Build strength and potentially trigger evolution
4. **BATTLE**: Test your Digimon's skills in combat

### Stats
- **Level**: Your Digimon's evolution stage
- **HP**: Health points
- **STR**: Strength from training
- **AGE**: How long you've cared for your Digimon

### Status Indicators
- 🍴 Hungry (appears when hunger is high)
- ❤️ Happy (appears when happiness is high)
- ✖️ Sick/Dead (appears when health is critically low)

## Technical Features

- **Procedural Sprite Generation**: Each Digimon sprite is generated using algorithmic patterns
- **Smooth Animations**: Floating animation for sprites using Flutter's animation system
- **Retro Styling**: Authentic LCD display colors and monospace fonts
- **Responsive Design**: Works on various screen sizes

## Getting Started

1. Ensure you have Flutter installed
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── digimon.dart         # Digimon data model and logic
├── screens/
│   └── digivice_screen.dart # Main game screen
├── widgets/
│   ├── lcd_display.dart     # LCD-style display widget
│   ├── pixel_sprite.dart    # Pixel art rendering
│   └── digivice_buttons.dart # Control buttons
└── services/
    └── sound_service.dart   # Haptic feedback system
```

## Future Enhancements

- Real audio synthesis for authentic beep sounds
- Save/load game state
- Multiple Digimon support
- More complex evolution trees
- Mini-games and additional activities
- Multiplayer battles via device connectivity
