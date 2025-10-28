import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/nutrition_data.dart';
import 'analysis_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  late SharedPreferences _prefs;

  double _calorieGoal = 2200, _proteinGoal = 150, _carbGoal = 250, _fatGoal = 70;
  bool _isLoadingGoals = true, _isLoadingMeals = true;

  Map<String, List<NutritionData>> dailyMeals = {
    'Breakfast': [], 'Lunch': [], 'Dinner': [], 'Snacks': [],
  };

  late Map<String, Color> mealAccentColors;

  @override
  void didChangeDependencies() {
     super.didChangeDependencies();
     final colors = Theme.of(context).colorScheme;
     mealAccentColors = {
        'Breakfast': colors.tertiaryContainer,
        'Lunch': colors.surfaceTint,
        'Dinner': colors.inverseSurface,
        'Snacks': colors.inversePrimary,
     };
  }

  @override
  void initState() {
    super.initState();
    _initPreferencesAndLoadData();
  }

  Future<void> _initPreferencesAndLoadData() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadGoals();
    await _loadMealsForSelectedDate();
    if (mounted) {
      setState(() {
        _isLoadingGoals = false;
        _isLoadingMeals = false;
      });
    }
  }

  Future<void> _loadGoals() async {
     _calorieGoal = _prefs.getDouble('calorieGoal') ?? 2200;
     _proteinGoal = _prefs.getDouble('proteinGoal') ?? 150;
     _carbGoal = _prefs.getDouble('carbGoal') ?? 250;
     _fatGoal = _prefs.getDouble('fatGoal') ?? 70;
  }

  String _getDateKey(DateTime date) => 'meals_${DateFormat('yyyy-MM-dd').format(date)}';

  Future<void> _loadMealsForSelectedDate() async {
    if (mounted) setState(() => _isLoadingMeals = true);
    final String key = _getDateKey(_selectedDate);
    final String? mealsJsonString = _prefs.getString(key);
    Map<String, List<NutritionData>> loadedMeals = {
       'Breakfast': [], 'Lunch': [], 'Dinner': [], 'Snacks': [],
    };
    if (mealsJsonString != null) {
      try {
        final Map<String, dynamic> decodedMap = jsonDecode(mealsJsonString);
        decodedMap.forEach((mealType, items) {
          if (items is List && loadedMeals.containsKey(mealType)) {
             loadedMeals[mealType] = items
                .map((item) => NutritionData.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        });
      } catch (e) { print("Error decoding meals for key $key: $e"); }
    }
    if (mounted) {
       setState(() { dailyMeals = loadedMeals; _isLoadingMeals = false; });
    }
  }

  Future<void> _saveMealsForSelectedDate() async {
    final String key = _getDateKey(_selectedDate);
    try {
      final String mealsJsonString = jsonEncode(
        dailyMeals.map((key, value) => MapEntry(key, value.map((item) => item.toJson()).toList())),
      );
       await _prefs.setString(key, mealsJsonString);
    } catch (e) { print("Error encoding meals for key $key: $e"); }
  }

  void _changeDate(int days) async {
    setState(() { _selectedDate = _selectedDate.add(Duration(days: days)); _isLoadingMeals = true; });
    await _loadMealsForSelectedDate();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() { _selectedDate = picked; _isLoadingMeals = true; });
       await _loadMealsForSelectedDate();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);
    if (checkDate == today) return 'Today';
    if (checkDate == yesterday) return 'Yesterday';
    if (checkDate == tomorrow) return 'Tomorrow';
    return DateFormat.yMMMMd('en_US').format(date);
  }

  Future<void> _navigateAndAddMeal(BuildContext context, String mealType) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AnalysisScreen(mealType: mealType)));
    if (result != null && result is NutritionData) {
      setState(() { dailyMeals[mealType]?.add(result); });
      await _saveMealsForSelectedDate();
    }
  }

  Future<void> _navigateToSettings(BuildContext context) async {
     final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
     if (result != null && result is Map<String, double>) {
       await _prefs.setDouble('calorieGoal', result['calories'] ?? _calorieGoal);
       await _prefs.setDouble('proteinGoal', result['protein'] ?? _proteinGoal);
       await _prefs.setDouble('carbGoal', result['carbs'] ?? _carbGoal);
       await _prefs.setDouble('fatGoal', result['fat'] ?? _fatGoal);
       await _loadGoals();
       if (mounted) setState(() {});
     }
  }

  double _getMacroForMeal(String mealType, String macro) {
     return dailyMeals[mealType]?.fold<double>(0.0, (double sum, item) {
       switch(macro) {
         case 'protein': return sum + item.protein;
         case 'carbs': return sum + item.carbs;
         case 'fat': return sum + item.fat;
         default: return sum;
       }
     }) ?? 0.0;
  }

  int _getCaloriesForMeal(String mealType) => dailyMeals[mealType]?.fold<int>(0, (int sum, item) => sum + item.calories.toInt()) ?? 0;

  Map<String, double> _getTotalMacros() {
    double calories = 0, protein = 0, carbs = 0, fat = 0;
    for (var list in dailyMeals.values) { for (var item in list) {
        calories += item.calories; protein += item.protein; carbs += item.carbs; fat += item.fat;
    }}
    return {'calories': calories, 'protein': protein, 'carbs': carbs, 'fat': fat};
  }

  void _showFoodItemDetails(BuildContext context, String mealType, int index) {
     final item = dailyMeals[mealType]![index];
     final theme = Theme.of(context);
     showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
           return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              title: Text(item.dishName, style: theme.textTheme.headlineSmall),
              content: SingleChildScrollView(
                 child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text('Weight: ${item.weight.toStringAsFixed(0)} g'),
                       const SizedBox(height: 8),
                       Text('Calories: ${item.calories.toStringAsFixed(0)} kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
                       const SizedBox(height: 8),
                       Text('Protein: ${item.protein.toStringAsFixed(1)} g'),
                       Text('Carbs: ${item.carbs.toStringAsFixed(1)} g'),
                       Text('Fat: ${item.fat.toStringAsFixed(1)} g'),
                       if (item.ingredients.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('Ingredients:', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Wrap(
                             spacing: 6, runSpacing: 4,
                             children: item.ingredients.map((ing) => Chip(
                                label: Text(ing), labelStyle: theme.textTheme.bodySmall,
                                padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                                backgroundColor: theme.colorScheme.surfaceVariant,
                             )).toList(),
                          )
                       ]
                    ],
                 ),
              ),
              actions: <Widget>[
                 TextButton(
                    child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    onPressed: () { Navigator.of(dialogContext).pop(); _deleteFoodItem(mealType, index); },
                 ),
                 TextButton(
                    child: Text('Close', style: TextStyle(color: theme.colorScheme.primary)),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                 ),
              ],
           );
        },
     );
  }

  void _deleteFoodItem(String mealType, int index) {
     setState(() { dailyMeals[mealType]?.removeAt(index); });
     _saveMealsForSelectedDate();
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalMacros = _getTotalMacros();
    bool showLoading = _isLoadingGoals || _isLoadingMeals;

    return Scaffold(
      appBar: AppBar(
        title: _buildDateSelector(theme, context),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(onPressed: () => _selectDate(context), icon: const Icon(Icons.calendar_today_outlined, size: 20), tooltip: 'Select Date'),
          IconButton(onPressed: () => _navigateToSettings(context), icon: const Icon(Icons.settings_outlined, size: 22), tooltip: 'Settings'),
          const SizedBox(width: 8),
        ],
      ),
      body: showLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            physics: const ClampingScrollPhysics(), // Use clamping physics
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // Reduced bottom padding
            children: [
              _buildDailySummaryCard(theme, totalMacros),
              const SizedBox(height: 24),
              _buildMealCard(
                theme: theme, title: 'Breakfast', icon: Icons.wb_sunny_outlined,
                accentColor: mealAccentColors['Breakfast']!,
                calories: _getCaloriesForMeal('Breakfast'), protein: _getMacroForMeal('Breakfast', 'protein'),
                carbs: _getMacroForMeal('Breakfast', 'carbs'), fat: _getMacroForMeal('Breakfast', 'fat'),
                items: dailyMeals['Breakfast'] ?? [],
                onAdd: () => _navigateAndAddMeal(context, 'Breakfast'),
                 onItemTap: (index) => _showFoodItemDetails(context, 'Breakfast', index),
              ),
              const SizedBox(height: 16),
              _buildMealCard(
                theme: theme, title: 'Lunch', icon: Icons.restaurant_outlined,
                accentColor: mealAccentColors['Lunch']!,
                calories: _getCaloriesForMeal('Lunch'), protein: _getMacroForMeal('Lunch', 'protein'),
                carbs: _getMacroForMeal('Lunch', 'carbs'), fat: _getMacroForMeal('Lunch', 'fat'),
                items: dailyMeals['Lunch'] ?? [],
                onAdd: () => _navigateAndAddMeal(context, 'Lunch'),
                onItemTap: (index) => _showFoodItemDetails(context, 'Lunch', index),
              ),
              const SizedBox(height: 16),
              _buildMealCard(
                 theme: theme, title: 'Dinner', icon: Icons.nightlight_outlined,
                 accentColor: mealAccentColors['Dinner']!,
                 calories: _getCaloriesForMeal('Dinner'), protein: _getMacroForMeal('Dinner', 'protein'),
                 carbs: _getMacroForMeal('Dinner', 'carbs'), fat: _getMacroForMeal('Dinner', 'fat'),
                 items: dailyMeals['Dinner'] ?? [],
                 onAdd: () => _navigateAndAddMeal(context, 'Dinner'),
                 onItemTap: (index) => _showFoodItemDetails(context, 'Dinner', index),
              ),
              const SizedBox(height: 16),
              _buildMealCard(
                 theme: theme, title: 'Snacks', icon: Icons.fastfood_outlined,
                 accentColor: mealAccentColors['Snacks']!,
                 calories: _getCaloriesForMeal('Snacks'), protein: _getMacroForMeal('Snacks', 'protein'),
                 carbs: _getMacroForMeal('Snacks', 'carbs'), fat: _getMacroForMeal('Snacks', 'fat'),
                 items: dailyMeals['Snacks'] ?? [],
                 onAdd: () => _navigateAndAddMeal(context, 'Snacks'),
                 onItemTap: (index) => _showFoodItemDetails(context, 'Snacks', index),
              ),
            ],
          ),
    );
  }

  Widget _buildDateSelector(ThemeData theme, BuildContext context) {
    final buttonStyle = theme.iconButtonTheme.style?.copyWith(
      padding: const MaterialStatePropertyAll(EdgeInsets.all(12)),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(onPressed: () => _changeDate(-1), icon: const Icon(Icons.chevron_left, size: 24), style: buttonStyle, tooltip: 'Previous Day'),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(_formatDate(_selectedDate), style: theme.appBarTheme.titleTextStyle),
          ),
        ),
        IconButton(onPressed: () => _changeDate(1), icon: const Icon(Icons.chevron_right, size: 24), style: buttonStyle, tooltip: 'Next Day'),
      ],
    );
  }

  Widget _buildDailySummaryCard(ThemeData theme, Map<String, double> macros) {
    final double currentCalories = macros['calories'] ?? 0;
    final double remainingCalories = _calorieGoal - currentCalories;
    final double calorieProgress = _calorieGoal <= 0 ? 0 : (currentCalories / _calorieGoal).clamp(0.0, 1.0);
    return Card(
      child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
         child: Row(
            children: [
               SizedBox(
                 width: 110, height: 110,
                 child: Stack(
                   fit: StackFit.expand,
                   children: [
                     CircularProgressIndicator(value: 1, strokeWidth: 7, backgroundColor: theme.colorScheme.surface, color: theme.colorScheme.surfaceVariant),
                     CircularProgressIndicator(value: calorieProgress, strokeWidth: 7, strokeCap: StrokeCap.round, color: theme.colorScheme.primary),
                     Center(
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text(remainingCalories.toStringAsFixed(0), style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, height: 1.1), textAlign: TextAlign.center),
                           Text('REMAINING', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary, letterSpacing: 0.5)),
                         ],
                       ),
                     ),
                   ],
                 ),
               ),
               const SizedBox(width: 24),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     _buildMacroRow(theme: theme, label: 'Protein', current: macros['protein'] ?? 0, goal: _proteinGoal, color: theme.colorScheme.primaryContainer),
                     const SizedBox(height: 12),
                     _buildMacroRow(theme: theme, label: 'Carbs', current: macros['carbs'] ?? 0, goal: _carbGoal, color: theme.colorScheme.tertiary),
                     const SizedBox(height: 12),
                     _buildMacroRow(theme: theme, label: 'Fat', current: macros['fat'] ?? 0, goal: _fatGoal, color: theme.colorScheme.secondaryContainer),
                   ],
                 ),
               ),
            ],
         ),
      ),
    );
  }

   Widget _buildMacroRow({
    required ThemeData theme, required String label,
    required double current, required double goal, required Color color,
  }) {
    final double progress = goal <= 0 ? 0 : (current / goal).clamp(0.0, 1.0);
    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Text(label, style: theme.textTheme.titleSmall),
             Text('${current.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} g', style: theme.textTheme.bodySmall),
           ],
         ),
         const SizedBox(height: 4),
         LinearProgressIndicator(
           value: progress, backgroundColor: theme.colorScheme.surfaceVariant,
           color: color, minHeight: 6, borderRadius: BorderRadius.circular(3),
         ),
       ],
    );
  }

  Widget _buildMealCard({
    required ThemeData theme, required String title, required IconData icon,
    required Color accentColor,
    required int calories, required double protein, required double carbs, required double fat,
    required List<NutritionData> items, required VoidCallback onAdd,
    required Function(int) onItemTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
             color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
             child: InkWell(
               onTap: () { },
               child: Row(
                  children: [
                     Container(width: 5, height: 50, color: accentColor),
                     Expanded(
                       child: Padding(
                         padding: const EdgeInsets.only(left: 11, right: 8, top: 12, bottom: 12),
                         child: Row(
                            children: [
                              Icon(icon, color: accentColor, size: 20),
                              const SizedBox(width: 12),
                              Text(title, style: theme.textTheme.titleLarge),
                              const Spacer(),
                              Text('$calories kcal', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary)),
                              IconButton(
                                iconSize: 24, visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                onPressed: onAdd, icon: Icon(Icons.add_circle, color: theme.colorScheme.primary),
                                tooltip: 'Add food to $title',
                              ),
                            ],
                         ),
                       ),
                     ),
                  ],
               ),
             ),
          ),
          if (calories > 0)
             Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                   'P: ${protein.toStringAsFixed(0)}g   C: ${carbs.toStringAsFixed(0)}g   F: ${fat.toStringAsFixed(0)}g',
                   style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                ),
             ),
          if (items.isNotEmpty) const Divider(height: 16, thickness: 1, indent: 16, endIndent: 16),
          if (items.isEmpty)
             Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Center(
                  child: Text( 'Tap + to add food',
                    style: theme.textTheme.bodyMedium?.copyWith( color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ),
                  ),
                ),
              )
          else
             Column(
                children: List.generate(items.length, (index) {
                   final item = items[index];
                   return InkWell(
                     onTap: () => onItemTap(index),
                     child: ListTile(
                       title: Text(item.dishName),
                       subtitle: Text( '${item.weight.toStringAsFixed(0)}g ・ P ${item.protein.toStringAsFixed(0)} C ${item.carbs.toStringAsFixed(0)} F ${item.fat.toStringAsFixed(0)}', ),
                       trailing: Text('${item.calories.toStringAsFixed(0)} kcal'),
                     ),
                   );
                }),
             ),
        ],
      ),
    );
  }
}