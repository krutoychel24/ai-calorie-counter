
import 'dart:io';
import 'package:calorie_counter_app/services/auth_service.dart';
import 'package:calorie_counter_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

enum Gender { male, female }
enum WeightGoal { lose, maintain, gain }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  late final String _uid;
  bool _isLoading = true;
  bool _isUploading = false;

  // User data
  String? _avatarUrl;
  String? _displayName;
  String? _email;

  // Profile Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  Gender? _selectedGender;
  String? _selectedActivityLevel;

  // Goal Controllers
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { return; }
    _uid = user.uid;
    _email = user.email;
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final userDoc = await _firestoreService.getUserData(_uid);
    if (!mounted || !userDoc.exists) return;

    final data = userDoc.data() as Map<String, dynamic>;
    setState(() {
      _avatarUrl = data['avatarUrl'];
      _displayName = data['displayName'];
      _nameController.text = _displayName ?? '';
      _ageController.text = (data['age'] as int?)?.toString() ?? '';
      _weightController.text = (data['weight'] as num?)?.toString() ?? '';
      _heightController.text = (data['height'] as num?)?.toString() ?? '';
      final genderString = data['gender'] as String?;
      _selectedGender = genderString != null ? Gender.values.firstWhere((e) => e.name == genderString, orElse: () => Gender.male) : null;
      _selectedActivityLevel = data['activityLevel'] as String?;

      _autoCalculateGoals = data['autoCalculateGoals'] as bool? ?? true;
      final goalString = data['weightGoal'] as String? ?? 'maintain';
      _weightGoal = WeightGoal.values.firstWhere((e) => e.name == goalString, orElse: () => WeightGoal.maintain);
      
      _caloriesController.text = (data['calorieGoal'] as num?)?.toStringAsFixed(0) ?? '0';
      _proteinController.text = (data['proteinGoal'] as num?)?.toStringAsFixed(0) ?? '0';
      _carbsController.text = (data['carbGoal'] as num?)?.toStringAsFixed(0) ?? '0';
      _fatController.text = (data['fatGoal'] as num?)?.toStringAsFixed(0) ?? '0';

      _isLoading = false;
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final imageUrl = await _firestoreService.uploadAvatar(_uid, File(image.path));
      await _firestoreService.updateUserProfile(_uid, {'avatarUrl': imageUrl});
      setState(() {
        _avatarUrl = imageUrl;
      });
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${e.toString()}')));
    } finally {
      if(mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    if (_autoCalculateGoals) {
      _calculateAndSetGoals();
    }

    final userData = {
      'displayName': _nameController.text,
      'age': int.tryParse(_ageController.text),
      'weight': double.tryParse(_weightController.text),
      'height': double.tryParse(_heightController.text),
      'gender': _selectedGender?.name,
      'activityLevel': _selectedActivityLevel,
      'weightGoal': _weightGoal.name,
      'autoCalculateGoals': _autoCalculateGoals,
      'calorieGoal': double.tryParse(_caloriesController.text),
      'proteinGoal': double.tryParse(_proteinController.text),
      'carbGoal': double.tryParse(_carbsController.text),
      'fatGoal': double.tryParse(_fatController.text),
    };

    await _firestoreService.updateUserProfile(_uid, userData);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
    Navigator.pop(context, true);
  }

  void _calculateAndSetGoals() {
    if (!_autoCalculateGoals) return;
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    if (age == null || weight == null || height == null || _selectedGender == null || _selectedActivityLevel == null) return;

    double bmr = (_selectedGender == Gender.male)
        ? (10 * weight + 6.25 * height - 5 * age + 5)
        : (10 * weight + 6.25 * height - 5 * age - 161);

    const activityMultipliers = {'sedentary': 1.2, 'light': 1.375, 'moderate': 1.55, 'active': 1.725, 'very_active': 1.9};
    final multiplier = activityMultipliers[_selectedActivityLevel] ?? 1.2;
    double dailyCalories = bmr * multiplier;

    switch (_weightGoal) {
      case WeightGoal.lose: dailyCalories -= 500; break;
      case WeightGoal.gain: dailyCalories += 500; break;
      case WeightGoal.maintain: break;
    }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: [
                  _buildAvatarSection(theme),
                  const SizedBox(height: 24),
                  _buildSectionHeader(theme, 'Account'),
                  _buildAccountCard(theme),
                  const SizedBox(height: 24),
                  _buildSectionHeader(theme, 'Personal Info'),
                  _buildProfileCard(theme),
                  const SizedBox(height: 24),
                  _buildSectionHeader(theme, 'Daily Goals'),
                  _buildGoalsCard(theme),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveProfile,
        label: const Text('Save Changes'),
        icon: const Icon(Icons.save_alt_outlined),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAvatarSection(ThemeData theme) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 3),
            ),
            child: CircleAvatar(
              radius: 58,
              backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
              backgroundColor: theme.colorScheme.surfaceVariant,
              child: _avatarUrl == null ? Icon(Icons.person_outline, size: 60, color: theme.colorScheme.primary) : null,
            ),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: _isUploading 
              ? const CircularProgressIndicator() 
              : IconButton.filled(
                  onPressed: _pickAndUploadAvatar,
                  icon: const Icon(Icons.camera_alt_outlined),
                  style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onBackground.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildAccountCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          TextFormField(controller: _nameController, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall, decoration: const InputDecoration.collapsed(hintText: 'Your Name')),
          const SizedBox(height: 4),
          Text(_email ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<Gender>(
            value: _selectedGender,
            items: Gender.values.map((g) => DropdownMenuItem(value: g, child: Text(g.name[0].toUpperCase() + g.name.substring(1)))).toList(),
            onChanged: (val) => setState(() => _selectedGender = val),
            decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _ageController, decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          TextFormField(controller: _weightController, decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          TextFormField(controller: _heightController, decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedActivityLevel,
            items: _activityLevels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.split(':')[0]))).toList(),
            onChanged: (val) => setState(() => _selectedActivityLevel = val),
            decoration: const InputDecoration(labelText: 'Activity Level', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Auto-calculate Goals'),
            value: _autoCalculateGoals,
            onChanged: (val) => setState(() {
              _autoCalculateGoals = val;
              if (val) _calculateAndSetGoals();
            }),
          ),
          const Divider(height: 24),
          SegmentedButton<WeightGoal>(
            segments: const [
              ButtonSegment(value: WeightGoal.lose, label: Text('Lose'), icon: Icon(Icons.trending_down)),
              ButtonSegment(value: WeightGoal.maintain, label: Text('Maintain'), icon: Icon(Icons.trending_flat)),
              ButtonSegment(value: WeightGoal.gain, label: Text('Gain'), icon: Icon(Icons.trending_up)),
            ],
            selected: {_weightGoal},
            onSelectionChanged: (newSelection) => setState(() {
              _weightGoal = newSelection.first;
              if(_autoCalculateGoals) _calculateAndSetGoals();
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
    );
  }

  Widget _buildGoalTextField(TextEditingController controller, String label, String unit, bool enabled) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      decoration: InputDecoration(labelText: label, suffixText: unit, border: const OutlineInputBorder()),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}
