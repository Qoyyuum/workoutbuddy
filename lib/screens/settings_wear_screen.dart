import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';

/// Wear OS optimized settings screen
/// Simplified to show only essential calorie goal setting
class SettingsWearScreen extends StatefulWidget {
  const SettingsWearScreen({super.key});

  @override
  State<SettingsWearScreen> createState() => _SettingsWearScreenState();
}

class _SettingsWearScreenState extends State<SettingsWearScreen> {
  final _customCalorieController = TextEditingController();
  
  bool _useCustomCalories = false;
  bool _isLoading = true;
  bool _isSaving = false;
  UserProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _customCalorieController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final db = DatabaseService.instance;
      final profileData = <String, String>{};
      
      final keys = [
        'weight_kg', 'height_cm', 'age', 'is_male',
        'activity_level', 'fitness_goal', 'custom_calorie_goal'
      ];
      
      for (final key in keys) {
        final value = await db.getSetting(key);
        if (value != null && value.isNotEmpty) {
          profileData[key] = value;
        }
      }

      if (profileData.isNotEmpty) {
        _currentProfile = UserProfile.fromMap(profileData);
        
        if (_currentProfile!.customCalorieGoal != null) {
          _useCustomCalories = true;
          _customCalorieController.text = _currentProfile!.customCalorieGoal!.toInt().toString();
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _saveCalorieGoal() async {
    setState(() => _isSaving = true);

    try {
      final db = DatabaseService.instance;
      
      if (_useCustomCalories && _customCalorieController.text.isNotEmpty) {
        final customGoal = double.tryParse(_customCalorieController.text);
        if (customGoal != null) {
          await db.saveSetting('custom_calorie_goal', customGoal.toString());
        }
      } else {
        // Clear custom calorie goal by saving empty string (filtered on load)
        await db.saveSetting('custom_calorie_goal', '');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calorie goal saved!'),
            duration: Duration(seconds: 1),
          ),
        );
        
        // Pop back after short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final calculatedGoal = _currentProfile?.getCalorieGoal().toInt() ?? 2000;

    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF9CB4A8)),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'SETTINGS',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: size.width * 0.055,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Info card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A3A3A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF9CB4A8).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Current Goal',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: size.width * 0.04,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$calculatedGoal',
                                  style: TextStyle(
                                    color: const Color(0xFF9CB4A8),
                                    fontSize: size.width * 0.12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'calories/day',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: size.width * 0.035,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: size.height * 0.02),
                          
                          // Custom calorie toggle
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A3A3A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _useCustomCalories
                                    ? const Color(0xFF9CB4A8)
                                    : const Color(0xFF9CB4A8).withValues(alpha: 0.5),
                                width: _useCustomCalories ? 2 : 1,
                              ),
                            ),
                            child: SwitchListTile(
                              title: Text(
                                'Custom Goal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: size.width * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Set your own target',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: size.width * 0.035,
                                ),
                              ),
                              value: _useCustomCalories,
                              onChanged: (value) {
                                setState(() {
                                  _useCustomCalories = value;
                                });
                              },
                              activeTrackColor: const Color(0xFF9CB4A8),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                          ),
                          
                          if (_useCustomCalories) ...[
                            SizedBox(height: size.height * 0.02),
                            
                            // Custom calorie input
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A3A3A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF9CB4A8),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daily Goal',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: size.width * 0.04,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _customCalorieController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: size.width * 0.05,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 2000',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.3),
                                      ),
                                      suffixText: 'cal',
                                      suffixStyle: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF9CB4A8),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: const Color(0xFF9CB4A8).withValues(alpha: 0.5),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF9CB4A8),
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  // Save button
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: GestureDetector(
                      onTap: _isSaving ? null : _saveCalorieGoal,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isSaving
                              ? Colors.grey
                              : const Color(0xFF9CB4A8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: _isSaving
                            ? const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Text(
                                'SAVE',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: size.width * 0.05,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
