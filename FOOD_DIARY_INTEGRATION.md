# 🍽️ Food Diary Integration Guide

## What's New

Created a **Food Diary Screen** that shows historical food entries before the food entry screen. Users can now:

✅ **Track eating habits** - See all meals grouped by date  
✅ **Monitor calorie deficit/surplus** - Visual indicators for each day  
✅ **View macro breakdowns** - Protein, carbs, fat per day  
✅ **Delete entries** - Long press or swipe to remove mistakes  
✅ **Period selection** - View today, 7 days, 14 days, or 30 days  
✅ **Refresh to update** - Pull down to refresh data  

---

## 📂 Files Created/Modified

### New Files:
- ✅ `lib/screens/food_diary_screen.dart` - Main food diary UI

### Modified Files:
- ✅ `lib/screens/food_entry_screen.dart` - Returns `true` when food added

---

## 🎨 Features

### 1. Daily Summary Cards
Each day shows:
- **Date header** (Today, Yesterday, or formatted date)
- **Calorie progress bar** - Visual comparison to goal
- **Status indicator**:
  - 🟢 **Green** - On target (within 100 cal)
  - 🟠 **Orange** - Deficit (100+ cal under)
  - 🔴 **Red** - Surplus (100+ cal over)
- **Macro breakdown chips** - Protein, Carbs, Fat totals
- **Item count** - Number of foods logged

### 2. Food Entry Cards
Each food shows:
- **Calorie badge** - Quick visual
- **Food name** and **serving size**
- **Timestamp** - When it was logged
- **Delete button** - Remove mistakes

### 3. Empty State
- Friendly message when no food logged
- Large icon illustration
- Clear call-to-action

### 4. Period Selector
Top-right calendar icon allows viewing:
- Today only
- Last 7 days (default)
- Last 14 days
- Last 30 days

---

## 🔗 Navigation Integration

### Option 1: Replace Direct Food Entry (Recommended)

Update your main navigation to show the diary first:

```dart
// In your main app navigation (home_screen.dart or main.dart)

// OLD: Direct to food entry
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FoodEntryScreen(
      workoutBuddy: workoutBuddy,
      onStatUpdate: onStatUpdate,
    ),
  ),
);

// NEW: Show diary first
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FoodDiaryScreen(
      workoutBuddy: workoutBuddy,
      onStatUpdate: onStatUpdate,
    ),
  ),
);
```

### Option 2: Add to Bottom Navigation

If you have a bottom nav bar:

```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workout'),
    BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Food'),  // <-- Opens FoodDiaryScreen
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ],
)
```

### Option 3: Add to Drawer Menu

```dart
ListTile(
  leading: Icon(Icons.restaurant_menu),
  title: Text('Food Diary'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodDiaryScreen(
          workoutBuddy: workoutBuddy,
          onStatUpdate: onStatUpdate,
        ),
      ),
    );
  },
),
```

---

## 📊 Usage Flow

```
User taps "Food" button
    ↓
[Food Diary Screen]
- Shows historical entries grouped by date
- Displays calorie progress for each day
- Shows macro breakdowns
    ↓
User taps "Log Food" FAB
    ↓
[Food Entry Screen]
- Search for food
- Select serving size
- Feed buddy
    ↓
Returns to Food Diary (auto-refreshes)
```

---

## 🎯 Visual Indicators

### Calorie Status Colors:

**🟢 Green (On Target):**
- Within ±100 calories of goal
- Message: "On target"
- Icon: ✓ Check circle

**🟠 Orange (Deficit):**
- 100+ calories below goal
- Message: "Deficit: XXX cal"
- Icon: ↓ Trending down

**🔴 Red (Surplus):**
- 100+ calories above goal
- Message: "Surplus: +XXX cal"
- Icon: ↑ Trending up

### Macro Chips:
- 💪 **Protein** - Red
- 🍞 **Carbs** - Orange
- 🥑 **Fat** - Blue

---

## 🔄 Data Refresh

The screen automatically refreshes when:
- User returns from adding food
- User pulls down to refresh
- User changes period (today/7 days/etc.)

---

## 🛠️ Customization Options

### Change Default Period
```dart
// In food_diary_screen.dart, line 29:
int _selectedDays = 7; // Change to 1, 14, or 30
```

### Adjust Calorie Threshold
```dart
// In _getCalorieStatus method, change ±100 to your preference:
if (difference < -150) { // More strict deficit
if (difference > 150) { // More strict surplus
```

### Modify Colors
```dart
// Date header gradient colors (line 149-152)
colors: [
  status['color'].withOpacity(0.1),
  status['color'].withOpacity(0.05),
],
```

---

## 📱 Example Screenshots (Mockup)

```
┌─────────────────────────────────┐
│  ← Food Diary 📖          📅    │
├─────────────────────────────────┤
│                                 │
│  ┌───────────────────────────┐ │
│  │ Today            ✓ On target│
│  │                             │
│  │ 1,850 / 2,000 cal  3 items │
│  │ ████████████░░░░░░░        │
│  │                             │
│  │ 💪 Protein: 98g             │
│  │ 🍞 Carbs: 220g              │
│  │ 🥑 Fat: 65g                 │
│  └───────────────────────────┘ │
│                                 │
│  📍 540 cal | Chicken Salad    │
│     200g • 12:30 PM        🗑️   │
│                                 │
│  📍 450 cal | Protein Shake    │
│     1 serving • 9:00 AM    🗑️   │
│                                 │
│  ┌───────────────────────────┐ │
│  │ Yesterday    ↑ Surplus: +250│
│  │ 2,250 / 2,000 cal  5 items │
│  └───────────────────────────┘ │
│                                 │
│                                 │
│                  [+ Log Food]   │ ← FAB
└─────────────────────────────────┘
```

---

## ✅ Testing Checklist

- [ ] Navigate to Food Diary from main menu
- [ ] View "No food logged" empty state
- [ ] Add food via FAB button
- [ ] See food entry appear in diary
- [ ] Check calorie progress bar updates
- [ ] Verify macro chips show correct totals
- [ ] Test period selector (today/7d/14d/30d)
- [ ] Delete a food entry
- [ ] Pull to refresh
- [ ] Check deficit/surplus indicators
- [ ] Test with no user profile (should use default 2000 cal goal)

---

## 🐛 Known Considerations

1. **No User Profile**: If user hasn't set up profile, defaults to 2000 cal goal
2. **Date Grouping**: Uses device timezone
3. **Deletion**: Requires confirmation dialog
4. **Refresh**: Pull-to-refresh or auto on return from food entry

---

## 🚀 Future Enhancements

Potential additions:
- Weekly/monthly calorie averages
- Streak tracking (X days hitting goal)
- Favorite foods quick-add
- Meal photos
- Export to CSV
- Macro targets (not just calories)
- Water intake tracking
- Meal timing analysis
- Buddy reactions based on food quality

---

## 📞 Support

The screen uses existing models and services:
- `FoodDiaryEntry` - Already in your models
- `DatabaseService` - Uses existing methods
- `UserProfile` - For calorie goal calculation

No additional dependencies required! ✨
