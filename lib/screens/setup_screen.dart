import 'package:calorie_counter_app/screens/home_screen.dart';
import 'package:calorie_counter_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';

enum Gender { male, female }

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final PageController _pageController = PageController();
  final _firestoreService = FirestoreService();
  int _currentPage = 0;
  bool _isLoading = false;

  // Page data
  final List<String> _animationPaths = [
    'assets/lottie/welcome.json',
    'assets/lottie/profile.json',
    'assets/lottie/activity.json',
  ];

  // Page 1: Language
  String? _selectedLanguage;
  final Map<String, String> _supportedLanguages = {
    'en': '🇬🇧  English',
    'ru': '🇷🇺  Русский',
    'de': '🇩🇪  Deutsch',
    'fr': '🇫🇷  Français',
    'es': '🇪🇸  Español',
  };

  // Page 2: Profile
  Gender? _selectedGender;
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  // Page 3: Activity Level
  String? _selectedActivityLevel;
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
    _setDefaultLanguage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _setDefaultLanguage() {
    try {
      final String systemLocale = Platform.localeName.split('_')[0];
      if (_supportedLanguages.containsKey(systemLocale)) {
        setState(() {
          _selectedLanguage = systemLocale;
        });
      }
    } catch (e) {
      // Fallback to english if locale parsing fails
      _selectedLanguage = 'en';
    }
  }

  Future<void> _saveAndFinish() async {
    if (_selectedGender == null || _ageController.text.isEmpty || _weightController.text.isEmpty || _heightController.text.isEmpty || _selectedActivityLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields to finish.')),
      );
      return;
    }
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return; // Should not happen
    }

    // Calculate goals
    final age = int.tryParse(_ageController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    double bmr = (_selectedGender == Gender.male)
        ? (10 * weight + 6.25 * height - 5 * age + 5)
        : (10 * weight + 6.25 * height - 5 * age - 161);
    const multipliers = {'sedentary': 1.2, 'light': 1.375, 'moderate': 1.55, 'active': 1.725, 'very_active': 1.9};
    double dailyCalories = bmr * (multipliers[_selectedActivityLevel] ?? 1.2);

    final userData = {
      'userLanguage': _selectedLanguage,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': _selectedGender?.name,
      'activityLevel': _selectedActivityLevel,
      'autoCalculateGoals': true,
      'calorieGoal': dailyCalories,
      'proteinGoal': (dailyCalories * 0.30) / 4,
      'carbGoal': (dailyCalories * 0.40) / 4,
      'fatGoal': (dailyCalories * 0.30) / 9,
    };

    await _firestoreService.saveUserSetup(user.uid, userData);
    _navigateToHome();
  }

  Future<void> _skipSetup() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    final userData = {
      'userLanguage': _selectedLanguage ?? 'en',
      // Set default placeholder values
      'age': 25,
      'weight': 70,
      'height': 175,
      'gender': 'male',
      'activityLevel': 'moderate',
      'autoCalculateGoals': true,
      'calorieGoal': 2200.0,
      'proteinGoal': 165.0,
      'carbGoal': 220.0,
      'fatGoal': 73.0,
    };
    await _firestoreService.saveUserSetup(user.uid, userData);
    _navigateToHome();
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(onPressed: _skipSetup, child: const Text('Skip')),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Lottie.asset(
                _animationPaths[_currentPage],
                key: ValueKey<int>(_currentPage),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildLanguagePage(theme),
                _buildProfilePage(theme),
                _buildActivityPage(theme),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(3, (index) => _buildDot(index, theme)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            onPressed: _isLoading ? null : () {
              if (_currentPage < 2) {
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
              } else {
                _saveAndFinish();
              }
            },
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_currentPage < 2 ? 'Next' : 'Finish'),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? theme.colorScheme.primary : theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPage({required String title, required String subtitle, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.secondary)),
          const SizedBox(height: 40),
          child,
        ],
      ),
    );
  }

  Widget _buildLanguagePage(ThemeData theme) {
    return _buildPage(
      title: 'Language',
      subtitle: 'Choose your preferred language for dish names.',
      child: DropdownButtonFormField<String>(
        value: _selectedLanguage,
        items: _supportedLanguages.entries.map((entry) {
          return DropdownMenuItem<String>(value: entry.key, child: Text(entry.value));
        }).toList(),
        onChanged: (value) => setState(() => _selectedLanguage = value),
        decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder(), prefixIcon: Icon(Icons.language_outlined)),
      ),
    );
  }

  Widget _buildProfilePage(ThemeData theme) {
    return _buildPage(
      title: 'Your Profile',
      subtitle: 'This helps in calculating your personalized goals.',
      child: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<Gender>(
              value: _selectedGender,
              items: Gender.values.map((gender) {
                return DropdownMenuItem<Gender>(value: gender, child: Text(gender.name[0].toUpperCase() + gender.name.substring(1)));
              }).toList(),
              onChanged: (value) => setState(() => _selectedGender = value),
              decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_search_outlined)),
              validator: (v) => v == null ? 'Please select a gender' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(controller: _ageController, decoration: InputDecoration(labelText: 'Age', border: const OutlineInputBorder(), prefixIcon: Icon(Icons.cake_outlined, color: theme.colorScheme.tertiary)), keyboardType: TextInputType.number, validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid age' : null),
            const SizedBox(height: 20),
            TextFormField(controller: _weightController, decoration: InputDecoration(labelText: 'Weight (kg)', border: const OutlineInputBorder(), prefixIcon: Icon(Icons.monitor_weight_outlined, color: theme.colorScheme.primaryContainer)), keyboardType: TextInputType.number, validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid weight' : null),
            const SizedBox(height: 20),
            TextFormField(controller: _heightController, decoration: InputDecoration(labelText: 'Height (cm)', border: const OutlineInputBorder(), prefixIcon: Icon(Icons.height_outlined, color: theme.colorScheme.secondaryContainer)), keyboardType: TextInputType.number, validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid height' : null),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityPage(ThemeData theme) {
    final activityIcons = {
      'sedentary': Icon(Icons.weekend_outlined, color: Colors.grey.shade400),
      'light': Icon(Icons.directions_walk, color: Colors.green.shade300),
      'moderate': Icon(Icons.directions_run, color: Colors.orange.shade300),
      'active': Icon(Icons.fitness_center, color: Colors.blue.shade300),
      'very_active': Icon(Icons.local_fire_department_outlined, color: Colors.red.shade400),
    };

    return _buildPage(
      title: 'Activity Level',
      subtitle: 'How active are you on a weekly basis?',
      child: Expanded(
        child: ListView.builder(
          itemCount: _activityLevels.length,
          itemBuilder: (context, index) {
            final entry = _activityLevels.entries.elementAt(index);
            final bool isSelected = _selectedActivityLevel == entry.key;
            return Card(
              color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : null,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: activityIcons[entry.key],
                title: Text(entry.value.split(':')[0]),
                subtitle: Text(entry.value.split(':')[1].trim()),
                onTap: () => setState(() => _selectedActivityLevel = entry.key),
                selected: isSelected,
              ),
            );
          },
        ),
      ),
    );
  }
}