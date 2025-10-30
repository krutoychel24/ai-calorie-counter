import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Animation local asset paths
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
  String? _selectedGender;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

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
    final String systemLocale = Platform.localeName.split('_')[0];
    if (_supportedLanguages.containsKey(systemLocale)) {
      setState(() {
        _selectedLanguage = systemLocale;
      });
    }
  }

  Future<void> _saveAndFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSetupComplete', true);
    if (_selectedLanguage != null) await prefs.setString('userLanguage', _selectedLanguage!);
    if (_selectedGender != null) await prefs.setString('gender', _selectedGender!);
    if (_ageController.text.isNotEmpty) await prefs.setInt('age', int.parse(_ageController.text));
    if (_weightController.text.isNotEmpty) await prefs.setDouble('weight', double.parse(_weightController.text));
    if (_heightController.text.isNotEmpty) await prefs.setDouble('height', double.parse(_heightController.text));
    if (_selectedActivityLevel != null) await prefs.setString('activityLevel', _selectedActivityLevel!);

    _navigateToHome();
  }

  Future<void> _skipSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSetupComplete', true);
    if (_selectedLanguage != null) await prefs.setString('userLanguage', _selectedLanguage!);
    _navigateToHome();
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
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
                key: ValueKey<int>(_currentPage), // Change key to trigger animation switch
                fit: BoxFit.contain,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
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
            onPressed: () {
              if (_currentPage < 2) {
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
              } else {
                _saveAndFinish();
              }
            },
            child: Text(_currentPage < 2 ? 'Next' : 'Finish'),
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
          Text(title, style: Theme.of(context).textTheme.displaySmall),
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
        decoration: const InputDecoration(labelText: 'Language', prefixIcon: Icon(Icons.language_outlined)),
      ),
    );
  }

  Widget _buildProfilePage(ThemeData theme) {
    Widget genderIcon;
    if (_selectedGender == 'male') {
      genderIcon = Icon(Icons.male, color: Colors.blue.shade300);
    } else if (_selectedGender == 'female') {
      genderIcon = Icon(Icons.female, color: Colors.pink.shade200);
    } else {
      genderIcon = const Icon(Icons.person_search_outlined);
    }

    return _buildPage(
      title: 'Your Profile',
      subtitle: 'This helps in calculating your personalized goals.',
      child: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedGender,
              items: const ['male', 'female'].map((gender) {
                return DropdownMenuItem<String>(value: gender, child: Text(gender[0].toUpperCase() + gender.substring(1)));
              }).toList(),
              onChanged: (value) => setState(() => _selectedGender = value),
              decoration: InputDecoration(labelText: 'Gender', prefixIcon: genderIcon),
            ),
            const SizedBox(height: 20),
            TextField(controller: _ageController, decoration: InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake_outlined, color: theme.colorScheme.tertiary)), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            TextField(controller: _weightController, decoration: InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.monitor_weight_outlined, color: theme.colorScheme.primaryContainer)), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            TextField(controller: _heightController, decoration: InputDecoration(labelText: 'Height (cm)', prefixIcon: Icon(Icons.height_outlined, color: theme.colorScheme.secondaryContainer)), keyboardType: TextInputType.number),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Level', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text('How active are you on a weekly basis?', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.secondary)),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: _activityLevels.length,
              itemBuilder: (context, index) {
                final entry = _activityLevels.entries.elementAt(index);
                final bool isSelected = _selectedActivityLevel == entry.key;
                return Card(
                  color: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2), width: 1.5),
                  ),
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
        ],
      ),
    );
  }
}

