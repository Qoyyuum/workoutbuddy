import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../services/calorie_calculator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _customCalorieController = TextEditingController();
  
  bool? _isMale;
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;
  FitnessGoal _fitnessGoal = FitnessGoal.maintain;
  bool _useCustomCalories = false;
  bool _isLoading = true;
  
  UserProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _customCalorieController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final db = DatabaseService.instance;
      final profileData = <String, String>{};
      
      // Load all profile settings
      final keys = [
        'name', 'weight_kg', 'height_cm', 'age', 'is_male',
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
        
        // Populate form fields
        _nameController.text = _currentProfile!.name ?? '';
        _weightController.text = _currentProfile!.weightKg?.toString() ?? '';
        _heightController.text = _currentProfile!.heightCm?.toString() ?? '';
        _ageController.text = _currentProfile!.age?.toString() ?? '';
        _isMale = _currentProfile!.isMale;
        _activityLevel = _currentProfile!.activityLevel;
        _fitnessGoal = _currentProfile!.fitnessGoal;
        
        if (_currentProfile!.customCalorieGoal != null) {
          _useCustomCalories = true;
          _customCalorieController.text = _currentProfile!.customCalorieGoal!.toInt().toString();
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = UserProfile(
      name: _nameController.text.isEmpty ? null : _nameController.text,
      weightKg: _weightController.text.isEmpty 
          ? null 
          : double.tryParse(_weightController.text),
      heightCm: _heightController.text.isEmpty 
          ? null 
          : double.tryParse(_heightController.text),
      age: _ageController.text.isEmpty 
          ? null 
          : int.tryParse(_ageController.text),
      isMale: _isMale,
      activityLevel: _activityLevel,
      fitnessGoal: _fitnessGoal,
      customCalorieGoal: _useCustomCalories && _customCalorieController.text.isNotEmpty
          ? double.tryParse(_customCalorieController.text)
          : null,
    );

    try {
      final db = DatabaseService.instance;
      final profileMap = profile.toMap();
      
      // Save each setting
      for (final entry in profileMap.entries) {
        await db.saveSetting(entry.key, entry.value);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Color(0xFF9CB4A8),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _calculateEstimatedCalories() {
    final profile = UserProfile(
      weightKg: double.tryParse(_weightController.text),
      heightCm: double.tryParse(_heightController.text),
      age: int.tryParse(_ageController.text),
      isMale: _isMale,
      activityLevel: _activityLevel,
      fitnessGoal: _fitnessGoal,
    );
    return profile.getCalorieGoal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Pixel Digivolve',
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9CB4A8)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Section
                  _buildSectionHeader('Profile', Icons.person),
                  _buildCard([
                    _buildTextField(
                      controller: _nameController,
                      label: 'Name (Optional)',
                      icon: Icons.badge,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Body Metrics Section
                  _buildSectionHeader('Body Metrics', Icons.fitness_center),
                  _buildCard([
                    // Gender Selection
                    const Text(
                      'Gender',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Pixel Digivolve',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGenderButton('Male', true),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGenderButton('Female', false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.cake,
                      keyboardType: TextInputType.number,
                      suffix: 'years',
                    ),
                    const SizedBox(height: 12),
                    
                    _buildTextField(
                      controller: _weightController,
                      label: 'Weight',
                      icon: Icons.monitor_weight,
                      keyboardType: TextInputType.number,
                      suffix: 'kg',
                    ),
                    const SizedBox(height: 12),
                    
                    _buildTextField(
                      controller: _heightController,
                      label: 'Height',
                      icon: Icons.height,
                      keyboardType: TextInputType.number,
                      suffix: 'cm',
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Activity Level Section
                  _buildSectionHeader('Activity Level', Icons.directions_run),
                  _buildCard([
                    _buildDropdown<ActivityLevel>(
                      value: _activityLevel,
                      items: ActivityLevel.values,
                      onChanged: (value) => setState(() => _activityLevel = value!),
                      getLabel: (level) => level.description,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Fitness Goal Section
                  _buildSectionHeader('Fitness Goal', Icons.track_changes),
                  _buildCard([
                    _buildDropdown<FitnessGoal>(
                      value: _fitnessGoal,
                      items: FitnessGoal.values,
                      onChanged: (value) => setState(() => _fitnessGoal = value!),
                      getLabel: (goal) => goal.description,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Calorie Goal Section
                  _buildSectionHeader('Calorie Goal', Icons.local_fire_department),
                  _buildCard([
                    // Calculated Calories Display
                    if (!_useCustomCalories) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9CB4A8).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF9CB4A8).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Recommended Daily Calories',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontFamily: 'Pixel Digivolve',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_calculateEstimatedCalories().toInt()} cal',
                              style: const TextStyle(
                                color: Color(0xFF9CB4A8),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Pixel Digivolve',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Custom Calories Toggle
                    SwitchListTile(
                      title: const Text(
                        'Use Custom Calorie Goal',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Pixel Digivolve',
                        ),
                      ),
                      value: _useCustomCalories,
                      onChanged: (value) => setState(() => _useCustomCalories = value),
                      activeTrackColor: const Color(0xFF9CB4A8),
                      activeThumbColor: const Color(0xFF9CB4A8),
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    if (_useCustomCalories) ...[
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _customCalorieController,
                        label: 'Custom Daily Calories',
                        icon: Icons.edit,
                        keyboardType: TextInputType.number,
                        suffix: 'cal',
                      ),
                    ],
                  ]),
                  const SizedBox(height: 24),

                  // Future Features Section
                  _buildSectionHeader('Cloud Backup', Icons.cloud),
                  _buildCard([
                    ListTile(
                      leading: const Icon(Icons.cloud_off, color: Colors.white54),
                      title: const Text(
                        'Google Drive Backup',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Pixel Digivolve',
                        ),
                      ),
                      subtitle: const Text(
                        'Coming soon!',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontFamily: 'Pixel Digivolve',
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ]),
                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9CB4A8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SAVE PROFILE',
                      style: TextStyle(
                        fontFamily: 'Pixel Digivolve',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9CB4A8), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9CB4A8),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pixel Digivolve',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A4A4A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontFamily: 'Pixel Digivolve'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontFamily: 'Pixel Digivolve'),
        prefixIcon: Icon(icon, color: const Color(0xFF9CB4A8)),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: Colors.white54, fontFamily: 'Pixel Digivolve'),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A4A4A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF9CB4A8), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
      ),
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
          : null,
    );
  }

  Widget _buildGenderButton(String label, bool isMale) {
    final isSelected = _isMale == isMale;
    
    return GestureDetector(
      onTap: () => setState(() => _isMale = isMale),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9CB4A8) : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF9CB4A8) : const Color(0xFF4A4A4A),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pixel Digivolve',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) getLabel,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            getLabel(item),
            style: const TextStyle(fontFamily: 'Pixel Digivolve'),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A4A4A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF9CB4A8), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
      ),
      dropdownColor: const Color(0xFF3A3A3A),
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Pixel Digivolve',
      ),
    );
  }
}
