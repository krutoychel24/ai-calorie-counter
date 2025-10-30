import 'dart:ui';
import 'package:calorie_counter_app/models/nutrition_data.dart';
import 'package:calorie_counter_app/screens/analysis_screen.dart';
import 'package:calorie_counter_app/screens/profile_screen.dart';
import 'package:calorie_counter_app/screens/settings_screen.dart';
import 'package:calorie_counter_app/services/auth_service.dart';
import 'package:calorie_counter_app/services/connectivity_service.dart';
import 'package:calorie_counter_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final FirestoreService _firestoreService = FirestoreService();
  late String _uid;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  // User Data
  String? _avatarUrl;
  String? _displayName;
  double _calorieGoal = 2200, _proteinGoal = 150, _carbGoal = 250, _fatGoal = 70;

  Map<String, List<NutritionData>> _dailyMeals = {
    'Breakfast': [], 'Lunch': [], 'Dinner': [], 'Snacks': [],
  };

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Provider.of<AuthService>(context, listen: false).signOut();
      return;
    }
    _uid = user.uid;
    _loadAllData();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      if (selected != today) {
        setState(() => _selectedDate = today);
        _loadMealsForSelectedDate();
      }
    }
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _loadUserData();
    await _loadMealsForSelectedDate();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUserData() async {
    final userDoc = await _firestoreService.getUserData(_uid);
    if (mounted && userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      setState(() {
        _displayName = data['displayName'];
        _avatarUrl = data['avatarUrl'];
        _calorieGoal = (data['calorieGoal'] as num?)?.toDouble() ?? 2200;
        _proteinGoal = (data['proteinGoal'] as num?)?.toDouble() ?? 150;
        _carbGoal = (data['carbGoal'] as num?)?.toDouble() ?? 250;
        _fatGoal = (data['fatGoal'] as num?)?.toDouble() ?? 70;
      });
    }
  }

  Future<void> _loadMealsForSelectedDate() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final meals = await _firestoreService.getMealsForDate(_uid, _selectedDate);
    if (mounted) {
      setState(() {
        _dailyMeals = meals;
        _isLoading = false;
      });
    }
  }

  void _onDateChange(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _loadMealsForSelectedDate();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadMealsForSelectedDate();
    }
  }

  Future<void> _navigateAndAddMeal(String mealType) async {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    if (!connectivityService.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No internet connection')));
      return;
    }
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AnalysisScreen(mealType: mealType)));
    if (result is NutritionData) {
      await _firestoreService.addMeal(_uid, mealType, result, _selectedDate);
      _loadMealsForSelectedDate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildDailySummary(context),
                      const SizedBox(height: 32),
                      _buildMealsSection(context),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      pinned: true,
      floating: false,
      expandedHeight: 120,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Today',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w300,
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            _buildDateSelector(),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _selectDate(context),
          icon: const Icon(Icons.calendar_today_outlined, size: 22),
          tooltip: 'Select Date',
        ),
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          icon: const Icon(Icons.settings_outlined, size: 22),
          tooltip: 'Settings',
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            if (result == true) _loadUserData();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
              backgroundColor: theme.colorScheme.surfaceVariant,
              child: _avatarUrl == null
                  ? Icon(Icons.person_outline, size: 20, color: theme.colorScheme.primary)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildDateSelector() {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatDate(_selectedDate),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDailySummary(BuildContext context) {
    final theme = Theme.of(context);
    final totalMacros = _getTotalMacros();
    final double currentCalories = totalMacros['calories'] ?? 0;
    final int remaining = (_calorieGoal - currentCalories).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Calorie Ring
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: (currentCalories / _calorieGoal).clamp(0.0, 1.0),
                    strokeWidth: 12,
                    backgroundColor: theme.colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      remaining > 0 ? remaining.toString() : '0',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'KCAL LEFT',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        letterSpacing: 1.5,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Macros Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMacroIndicator(
                theme,
                'Protein',
                totalMacros['protein'] ?? 0,
                _proteinGoal,
                theme.colorScheme.primaryContainer,
              ),
              _buildMacroIndicator(
                theme,
                'Carbs',
                totalMacros['carbs'] ?? 0,
                _carbGoal,
                theme.colorScheme.tertiary,
              ),
              _buildMacroIndicator(
                theme,
                'Fat',
                totalMacros['fat'] ?? 0,
                _fatGoal,
                theme.colorScheme.secondaryContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroIndicator(ThemeData theme, String label, double current, double goal, Color color) {
    final percentage = (current / goal * 100).clamp(0, 100).toInt();
    return Column(
      children: [
        Text(
          '${current.toInt()}g',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (percentage / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealsSection(BuildContext context) {
    final theme = Theme.of(context);
    final meals = [
      {'name': 'Breakfast', 'icon': Icons.wb_sunny_outlined},
      {'name': 'Lunch', 'icon': Icons.wb_cloudy_outlined},
      {'name': 'Dinner', 'icon': Icons.nightlight_outlined},
      {'name': 'Snacks', 'icon': Icons.local_cafe_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Meals',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ),
        ...meals.map((meal) {
          final mealName = meal['name'] as String;
          final items = _dailyMeals[mealName] ?? [];
          return _buildMealCard(
            theme,
            mealName,
            meal['icon'] as IconData,
            items,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMealCard(ThemeData theme, String title, IconData icon, List<NutritionData> items) {
    final totalCalories = items.fold(0, (sum, item) => sum + item.calories.toInt());
    final hasItems = items.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateAndAddMeal(title),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasItems ? '$totalCalories kcal' : 'Tap to add',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: hasItems 
                            ? theme.colorScheme.primary 
                            : theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline,
                  color: theme.colorScheme.primary.withOpacity(0.6),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat.MMMd().format(date);
    }
    if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday';
    }
    return DateFormat.MMMd().format(date);
  }

  Map<String, double> _getTotalMacros() {
    double calories = 0, protein = 0, carbs = 0, fat = 0;
    for (var list in _dailyMeals.values) {
      for (var item in list) {
        calories += item.calories;
        protein += item.protein;
        carbs += item.carbs;
        fat += item.fat;
      }
    }
    return {'calories': calories, 'protein': protein, 'carbs': carbs, 'fat': fat};
  }
}