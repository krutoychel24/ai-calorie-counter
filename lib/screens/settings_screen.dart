import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeightUnit { kg, lbs }
enum HeightUnit { cm, ftin }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late SharedPreferences _prefs;

  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  WeightUnit _selectedWeightUnit = WeightUnit.kg;
  HeightUnit _selectedHeightUnit = HeightUnit.cm;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _caloriesController.dispose(); _proteinController.dispose();
    _carbsController.dispose(); _fatController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _caloriesController.text = (_prefs.getDouble('calorieGoal') ?? 2200).toStringAsFixed(0);
      _proteinController.text = (_prefs.getDouble('proteinGoal') ?? 150).toStringAsFixed(0);
      _carbsController.text = (_prefs.getDouble('carbGoal') ?? 250).toStringAsFixed(0);
      _fatController.text = (_prefs.getDouble('fatGoal') ?? 70).toStringAsFixed(0);
      _selectedWeightUnit = WeightUnit.values[_prefs.getInt('weightUnit') ?? WeightUnit.kg.index];
      _selectedHeightUnit = HeightUnit.values[_prefs.getInt('heightUnit') ?? HeightUnit.cm.index];
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      final calorieGoal = double.tryParse(_caloriesController.text) ?? 2200;
      final proteinGoal = double.tryParse(_proteinController.text) ?? 150;
      final carbGoal = double.tryParse(_carbsController.text) ?? 250;
      final fatGoal = double.tryParse(_fatController.text) ?? 70;

      await _prefs.setDouble('calorieGoal', calorieGoal);
      await _prefs.setDouble('proteinGoal', proteinGoal);
      await _prefs.setDouble('carbGoal', carbGoal);
      await _prefs.setDouble('fatGoal', fatGoal);
      await _prefs.setInt('weightUnit', _selectedWeightUnit.index);
      await _prefs.setInt('heightUnit', _selectedHeightUnit.index);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: const Text('Settings saved successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          behavior: SnackBarBehavior.floating,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
           margin: const EdgeInsets.all(16),
        ),
      );

      Navigator.pop(context, {
        'calories': calorieGoal, 'protein': proteinGoal,
        'carbs': carbGoal, 'fat': fatGoal,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Reset Goals', onPressed: _resetGoalsToDefaults),
        ],
      ),
      body: GestureDetector(
         onTap: () => FocusScope.of(context).unfocus(),
         child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                     _buildSectionHeader(theme, 'Profile & Units'),
                     Card(
                        elevation: 0,
                        child: Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                           child: Column(
                              children: [
                                _buildUnitSelectorTile<WeightUnit>(
                                   title: 'Weight Unit',
                                   value: _selectedWeightUnit,
                                   items: const {WeightUnit.kg: 'Kilograms (kg)', WeightUnit.lbs: 'Pounds (lbs)'},
                                   onChanged: (value) => setState(() => _selectedWeightUnit = value!),
                                ),
                                _buildUnitSelectorTile<HeightUnit>(
                                   title: 'Height Unit',
                                   value: _selectedHeightUnit,
                                   items: const {HeightUnit.cm: 'Centimeters (cm)', HeightUnit.ftin: 'Feet & Inches (ft\' in")'},
                                   onChanged: (value) => setState(() => _selectedHeightUnit = value!),
                                ),
                              ],
                           ),
                        ),
                     ),
                     const SizedBox(height: 24),
                     _buildSectionHeader(theme, 'Daily Goals'),
                     Card(
                       elevation: 0,
                       child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               _buildGoalTextField(
                                 controller: _caloriesController, label: 'Calories', unit: 'kcal',
                                 icon: Icons.local_fire_department_outlined,
                               ),
                               const SizedBox(height: 16),
                               _buildGoalTextField(
                                 controller: _proteinController, label: 'Protein', unit: 'g',
                                 icon: Icons.egg_outlined, color: theme.colorScheme.primaryContainer,
                               ),
                                const SizedBox(height: 16),
                               _buildGoalTextField(
                                 controller: _carbsController, label: 'Carbs', unit: 'g',
                                 icon: Icons.rice_bowl_outlined, color: theme.colorScheme.tertiary,
                               ),
                                const SizedBox(height: 16),
                               _buildGoalTextField(
                                 controller: _fatController, label: 'Fat', unit: 'g',
                                 icon: Icons.water_drop_outlined, color: theme.colorScheme.secondaryContainer,
                               ),
                             ],
                          ),
                       ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                       icon: const Icon(Icons.save_alt_outlined, size: 20),
                       onPressed: _saveSettings,
                       label: const Text('Save Settings'),
                       style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
       child: Text(
          title.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
             color: theme.colorScheme.primary,
             fontWeight: FontWeight.bold,
          )
       ),
     );
  }

  Widget _buildUnitSelectorTile<T>({
     required String title,
     required T value,
     required Map<T, String> items,
     required ValueChanged<T?> onChanged,
   }) {
     final theme = Theme.of(context);
     return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: DropdownButtonFormField<T>(
           value: value,
           items: items.entries.map((entry) => DropdownMenuItem<T>(
             value: entry.key,
             child: Text(entry.value),
           )).toList(),
           onChanged: onChanged,
           decoration: InputDecoration(
             labelText: title,
             filled: false,
             contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
             border: InputBorder.none,
             enabledBorder: InputBorder.none,
             focusedBorder: InputBorder.none,
           ),
            style: theme.textTheme.bodyLarge,
            // --- FIX HERE ---
            dropdownColor: theme.colorScheme.surfaceVariant, // Use surfaceVariant
            borderRadius: BorderRadius.circular(8),
        ),
     );
   }

  Widget _buildGoalTextField({
    required TextEditingController controller, required String label,
    required String unit, required IconData icon, Color? color,
  }) {
     final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: color ?? theme.colorScheme.secondary),
        suffixText: unit,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color ?? theme.colorScheme.primary, width: 1.5),
        ),
         enabledBorder: InputBorder.none,
         border: InputBorder.none,
         floatingLabelStyle: TextStyle(color: color ?? theme.colorScheme.primary),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) return 'Enter a value';
        final number = int.tryParse(value);
        if (number == null) return 'Enter a valid number';
        if (number < 0) return 'Cannot be negative';
        return null;
      },
    );
  }

   void _resetGoalsToDefaults() {
      setState(() {
         _caloriesController.text = '2200';
         _proteinController.text = '150';
         _carbsController.text = '250';
         _fatController.text = '70';
      });
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Goals reset to defaults.')),
      );
   }
}