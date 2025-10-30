import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nutrition_data.dart';
import '../services/firebase_service.dart';
import '../services/open_food_facts_service.dart';
import '../widgets/animated_scan_line.dart';
import 'barcode_scanner_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final String mealType;

  const AnalysisScreen({super.key, required this.mealType});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Services
  final FirebaseService _firebaseService = FirebaseService();
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();

  // State
  File? _selectedImage;
  NutritionData? _nutritionData;
  bool _isLoading = false;
  bool _isEditing = false;

  // Controllers
  final TextEditingController _infoController = TextEditingController();
  final TextEditingController _dishNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void dispose() {
    _infoController.dispose();
    _dishNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _updateStateWithNutritionData(NutritionData data) {
    if (!mounted) return;
    setState(() {
      _nutritionData = data;
      _dishNameController.text = data.dishName;
      _caloriesController.text = data.calories.toStringAsFixed(0);
      _proteinController.text = data.protein.toStringAsFixed(1);
      _carbsController.text = data.carbs.toStringAsFixed(1);
      _fatController.text = data.fat.toStringAsFixed(1);
      _weightController.text = data.weight.toStringAsFixed(0);
      _isLoading = false;
      _isEditing = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
          source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _nutritionData = null;
          _isEditing = false;
        });
      }
    } catch (e) {
      _showError('Error selecting image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('userLanguage') ?? 'en';

      final result = await _firebaseService.analyzeImage(
        _selectedImage!,
        _infoController.text.isNotEmpty ? _infoController.text : null,
        langCode,
      );
      _updateStateWithNutritionData(result);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Analysis failed: ${e.toString()}');
      }
    }
  }

  Future<void> _scanBarcode() async {
    try {
      final String? barcode = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );
      if (barcode == null) return;

      setState(() => _isLoading = true);
      final result = await _openFoodFactsService.getProductByBarcode(barcode);

      if (result != null) {
        _updateStateWithNutritionData(result);
      } else {
        _showError('Product not found for barcode: $barcode');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Barcode scan failed: $e');
      setState(() => _isLoading = false);
    }
  }

  void _addFoodAndReturn() {
    if (_isEditing && !(_formKey.currentState?.validate() ?? false)) {
      _showError('Please fill all fields correctly');
      return;
    }
    final finalData = NutritionData(
      dishName: _dishNameController.text,
      weight: double.tryParse(_weightController.text) ?? 0.0,
      calories: double.tryParse(_caloriesController.text) ?? 0.0,
      protein: double.tryParse(_proteinController.text) ?? 0.0,
      fat: double.tryParse(_fatController.text) ?? 0.0,
      carbs: double.tryParse(_carbsController.text) ?? 0.0,
      ingredients: _nutritionData?.ingredients ?? [],
      usefulness: _nutritionData?.usefulness ?? 0.0,
    );
    Navigator.pop(context, finalData);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add to ${widget.mealType}')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageSection(context),
              const SizedBox(height: 24),
              _buildActionsSection(context),
              const SizedBox(height: 24),
              _buildInfoField(context),
              const SizedBox(height: 24),
              _buildResultsSection(context),
              const SizedBox(height: 24),
              if (_nutritionData != null) _buildAddFoodButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_selectedImage != null)
              Image.file(_selectedImage!, fit: BoxFit.cover)
            else
              Center(
                child: Text('Select an image to analyze', style: theme.textTheme.titleMedium),
              ),
            if (_isLoading) ...[
              Container(color: Colors.black.withOpacity(0.6)),
              const AnimatedScanLine(width: double.infinity, height: double.infinity, color: Colors.white),
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            ],
            if (_selectedImage != null && !_isLoading)
              Positioned(
                top: 12, right: 12,
                child: IconButton(
                  onPressed: () => setState(() {
                    _selectedImage = null;
                    _nutritionData = null;
                  }),
                  icon: const Icon(Icons.cancel_rounded, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.4),
                    foregroundColor: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: const Text('Gallery'),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: _scanBarcode,
          style: OutlinedButton.styleFrom(minimumSize: const Size(60, 60)),
          child: const Icon(Icons.qr_code_scanner_outlined, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _selectedImage != null && !_isLoading ? _analyzeImage : null,
            icon: const Icon(Icons.document_scanner_outlined, size: 20),
            label: Text(_isLoading ? 'Analyzing...' : 'Analyze'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField(BuildContext context) {
    return TextField(
      controller: _infoController,
      maxLines: 2,
      decoration: const InputDecoration(
        hintText: 'Any extra details? (e.g., brand, cooking method)',
        prefixIcon: Icon(Icons.notes_outlined, size: 20),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(sizeFactor: animation, child: child),
      ),
      child: _nutritionData != null
          ? _buildInteractiveCard(context)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildInteractiveCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: _isEditing
            ? _buildEditView(theme)
            : _buildDisplayView(theme),
      ),
    );
  }

  Widget _buildDisplayView(ThemeData theme) {
    return InkWell(
      key: const ValueKey('display'),
      onTap: () => setState(() => _isEditing = true),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_dishNameController.text, style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text('${_weightController.text}g (serving)', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.secondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Data',
                  onPressed: () => setState(() => _isEditing = true),
                ),
              ],
            ),
            const Divider(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroDisplay(theme, _caloriesController.text, 'Calories', 'kcal', theme.colorScheme.primary),
                _buildMacroDisplay(theme, _proteinController.text, 'Protein', 'g', theme.colorScheme.primaryContainer),
                _buildMacroDisplay(theme, _carbsController.text, 'Carbs', 'g', theme.colorScheme.tertiary),
                _buildMacroDisplay(theme, _fatController.text, 'Fat', 'g', theme.colorScheme.secondaryContainer),
              ],
            ),
            const Divider(height: 40),
            _buildUsefulnessIndicator(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildUsefulnessIndicator(ThemeData theme) {
    final score = _nutritionData?.usefulness ?? 0.0;
    final color = Color.lerp(Colors.red, Colors.green, score / 10) ?? Colors.grey;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Health Score', style: theme.textTheme.titleMedium),
        const SizedBox(width: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: score / 10,
              color: color,
              backgroundColor: color.withOpacity(0.2),
              strokeWidth: 6,
            ),
            Text(score.toStringAsFixed(1), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildEditView(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Padding(
        key: const ValueKey('edit'),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _dishNameController,
                        style: theme.textTheme.headlineMedium,
                        decoration: const InputDecoration.collapsed(hintText: 'Dish Name'),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _weightController,
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.secondary),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration.collapsed(hintText: 'Weight (g)'),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.check_circle, color: Colors.green.shade400, size: 28),
                  tooltip: 'Done Editing',
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() => _isEditing = false);
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroField(theme, _caloriesController, 'Calories', 'kcal'),
                _buildMacroField(theme, _proteinController, 'Protein', 'g'),
                _buildMacroField(theme, _carbsController, 'Carbs', 'g'),
                _buildMacroField(theme, _fatController, 'Fat', 'g'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroDisplay(ThemeData theme, String value, String label, String unit, Color color) {
    return Column(
      children: [
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
      ],
    );
  }

  Widget _buildMacroField(ThemeData theme, TextEditingController controller, String label, String unit) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Text(label, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.secondary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: const InputDecoration.collapsed(hintText: '0'),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFoodButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _addFoodAndReturn,
      icon: const Icon(Icons.add_task_outlined, size: 20),
      label: const Text('Add Food Entry'),
      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
    );
  }
}