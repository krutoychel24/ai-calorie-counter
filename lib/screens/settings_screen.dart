import 'package:calorie_counter_app/screens/setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Gender { male, female }
enum WeightGoal { lose, maintain, gain }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late SharedPreferences _prefs;
  bool _isLoading = true;

  // Profile Controllers & State
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  Gender? _selectedGender;
  String? _selectedActivityLevel;

  // Goal Controllers & State
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  bool _autoCalculateGoals = true;
  WeightGoal _weightGoal = WeightGoal.maintain;

  final Map<String, String> _activityLevels = {
    'sedentary': 'Sedentary: little or no exercise',
    'light': 'Lightly active: 1-3 days/week',
    'moderate': 'Moderately active: 3-5 days/week',
    'active': 'Active: 6-7 days/week',
    'very_active': 'Very active: hard exercise 6-7 days/week',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load profile
      _ageController.text = _prefs.getInt('age')?.toString() ?? '';
      _weightController.text = _prefs.getDouble('weight')?.toString() ?? '';
      _heightController.text = _prefs.getDouble('height')?.toString() ?? '';
      final genderString = _prefs.getString('gender');
      _selectedGender = genderString != null ? Gender.values.firstWhere((e) => e.name == genderString, orElse: () => Gender.male) : null;
      _selectedActivityLevel = _prefs.getString('activityLevel');

      // Load goals
      _autoCalculateGoals = _prefs.getBool('autoCalculateGoals') ?? true;
      final goalString = _prefs.getString('weightGoal') ?? 'maintain';
      _weightGoal = WeightGoal.values.firstWhere((e) => e.name == goalString, orElse: () => WeightGoal.maintain);
      
      if (_autoCalculateGoals) {
        _calculateAndSetGoals();
      } else {
        _caloriesController.text = (_prefs.getDouble('calorieGoal') ?? 2200).toStringAsFixed(0);
        _proteinController.text = (_prefs.getDouble('proteinGoal') ?? 150).toStringAsFixed(0);
        _carbsController.text = (_prefs.getDouble('carbGoal') ?? 250).toStringAsFixed(0);
        _fatController.text = (_prefs.getDouble('fatGoal') ?? 70).toStringAsFixed(0);
      }

      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Save Profile
    await _prefs.setInt('age', int.tryParse(_ageController.text) ?? 0);
    await _prefs.setDouble('weight', double.tryParse(_weightController.text) ?? 0);
    await _prefs.setDouble('height', double.tryParse(_heightController.text) ?? 0);
    if (_selectedGender != null) await _prefs.setString('gender', _selectedGender!.name);
    if (_selectedActivityLevel != null) await _prefs.setString('activityLevel', _selectedActivityLevel!);

    // Save Goals
    await _prefs.setBool('autoCalculateGoals', _autoCalculateGoals);
    await _prefs.setString('weightGoal', _weightGoal.name);
    await _prefs.setDouble('calorieGoal', double.tryParse(_caloriesController.text) ?? 2200);
    await _prefs.setDouble('proteinGoal', double.tryParse(_proteinController.text) ?? 150);
    await _prefs.setDouble('carbGoal', double.tryParse(_carbsController.text) ?? 250);
    await _prefs.setDouble('fatGoal', double.tryParse(_fatController.text) ?? 70);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully!')));
    Navigator.pop(context, true); // Pop with a result to indicate changes were made
  }

  void _calculateAndSetGoals() {
    if (!_autoCalculateGoals) return;

    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (age == null || weight == null || height == null || _selectedGender == null || _selectedActivityLevel == null) {
      return;
    }

    // Mifflin-St Jeor Equation for BMR
    double bmr;
    if (_selectedGender == Gender.male) {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    const activityMultipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };

    final multiplier = activityMultipliers[_selectedActivityLevel] ?? 1.2;
    double dailyCalories = bmr * multiplier;

    // Adjust for weight goal
    switch (_weightGoal) {
      case WeightGoal.lose:
        dailyCalories -= 500;
        break;
      case WeightGoal.gain:
        dailyCalories += 500;
        break;
      case WeightGoal.maintain:
        break;
    }

    // Simple macro split (40% C, 30% P, 30% F)
    final carbs = (dailyCalories * 0.40) / 4;
    final protein = (dailyCalories * 0.30) / 4;
    final fat = (dailyCalories * 0.30) / 9;

    setState(() {
      _caloriesController.text = dailyCalories.toStringAsFixed(0);
      _proteinController.text = protein.toStringAsFixed(0);
      _carbsController.text = carbs.toStringAsFixed(0);
      _fatController.text = fat.toStringAsFixed(0);
    });
  }

  Future<void> _resetOnboarding() async {
    await _prefs.setBool('isSetupComplete', false);
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SetupScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  _buildSectionHeader(theme, 'User Profile'),
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(theme, 'Daily Goals'),
                  _buildGoalsCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(theme, 'Application'),
                  _buildAppCard(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSettings,
        label: const Text('Save Settings'),
        icon: const Icon(Icons.save_alt_outlined),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 8.0),
      child: Text(title.toUpperCase(), style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
    );
  }

  Widget _buildProfileCard() {
    final theme = Theme.of(context);
    
    Widget genderIcon;
    if (_selectedGender == Gender.male) {
      genderIcon = Icon(Icons.male, color: Colors.blue.shade300);
    } else if (_selectedGender == Gender.female) {
      genderIcon = Icon(Icons.female, color: Colors.pink.shade200);
    } else {
      genderIcon = const Icon(Icons.person_search_outlined);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<Gender>(
              value: _selectedGender,
              items: Gender.values.map((g) => DropdownMenuItem(value: g, child: Text(g.name[0].toUpperCase() + g.name.substring(1)))).toList(),
              onChanged: (val) => setState(() {
                _selectedGender = val;
                _calculateAndSetGoals();
              }),
              decoration: InputDecoration(labelText: 'Gender', prefixIcon: genderIcon),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _ageController, decoration: InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake_outlined, color: theme.colorScheme.tertiary)), keyboardType: TextInputType.number, onChanged: (_) => _calculateAndSetGoals())),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(controller: _weightController, decoration: InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.monitor_weight_outlined, color: theme.colorScheme.primaryContainer)), keyboardType: TextInputType.number, onChanged: (_) => _calculateAndSetGoals())),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(controller: _heightController, decoration: InputDecoration(labelText: 'Height (cm)', prefixIcon: Icon(Icons.height_outlined, color: theme.colorScheme.secondaryContainer)), keyboardType: TextInputType.number, onChanged: (_) => _calculateAndSetGoals())),
              ],
            ),
            const Divider(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedActivityLevel,
              items: _activityLevels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.split(':')[0]))).toList(),
              onChanged: (val) => setState(() {
                _selectedActivityLevel = val;
                _calculateAndSetGoals();
              }),
              decoration: const InputDecoration(labelText: 'Activity Level', prefixIcon: Icon(Icons.directions_run_outlined)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsCard() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Auto-calculate Goals'),
              subtitle: const Text('Based on your profile and goal'),
              value: _autoCalculateGoals,
              onChanged: (val) => setState(() {
                _autoCalculateGoals = val;
                if (val) _calculateAndSetGoals();
              }),
              activeColor: theme.colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 24),
            SegmentedButton<WeightGoal>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                selectedForegroundColor: theme.colorScheme.primary,
              ),
              segments: const [
                ButtonSegment(value: WeightGoal.lose, label: Text('Lose'), icon: Icon(Icons.trending_down)),
                ButtonSegment(value: WeightGoal.maintain, label: Text('Maintain'), icon: Icon(Icons.trending_flat)),
                ButtonSegment(value: WeightGoal.gain, label: Text('Gain'), icon: Icon(Icons.trending_up)),
              ],
              selected: {_weightGoal},
              onSelectionChanged: (newSelection) => setState(() {
                _weightGoal = newSelection.first;
                _calculateAndSetGoals();
              }),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildGoalTextField(_caloriesController, 'Calories', 'kcal', !_autoCalculateGoals)),
                const SizedBox(width: 16),
                Expanded(child: _buildGoalTextField(_proteinController, 'Protein', 'g', !_autoCalculateGoals)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildGoalTextField(_carbsController, 'Carbs', 'g', !_autoCalculateGoals)),
                const SizedBox(width: 16),
                Expanded(child: _buildGoalTextField(_fatController, 'Fat', 'g', !_autoCalculateGoals)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTextField(TextEditingController controller, String label, String unit, bool enabled) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(labelText: label, suffixText: unit),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildAppCard() {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.language_outlined, color: theme.colorScheme.primary),
            title: const Text('Language'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () { /* TODO: Navigate to language selection */ },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.dark_mode_outlined, color: theme.colorScheme.tertiary),
            title: const Text('Theme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () { /* TODO: Navigate to theme selection */ },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.restart_alt, color: theme.colorScheme.error),
            title: const Text('Reset Onboarding'),
            subtitle: const Text('Show first-time setup again'),
            onTap: _resetOnboarding,
          ),
        ],
      ),
    );
  }
}