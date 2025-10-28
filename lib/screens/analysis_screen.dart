import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_service.dart';
import '../models/nutrition_data.dart';
import '../widgets/nutrition_card.dart';
import '../widgets/animated_scan_line.dart'; // Import the new animation widget

class AnalysisScreen extends StatefulWidget {
  final String mealType;

  const AnalysisScreen({super.key, required this.mealType});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _infoController = TextEditingController();
  final GlobalKey _imageSectionKey = GlobalKey(); // Key to get image section size

  File? _selectedImage;
  bool _isLoading = false;
  NutritionData? _nutritionData;
  Size _imageSectionSize = Size.zero; // To store the size for animation bounds

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureImageSectionSize();
    });
  }

  void _captureImageSectionSize() {
    final RenderBox? renderBox = _imageSectionKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      if (mounted) {
           setState(() {
              _imageSectionSize = renderBox.size;
           });
       }
    }
  }

  @override
  void dispose() {
    _infoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _nutritionData = null;
          _captureImageSectionSize();
        });
      }
    } catch (e) { _showError('Error selecting image: $e'); }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _firebaseService.analyzeImage(
        _selectedImage!,
         _infoController.text.isNotEmpty ? _infoController.text : null,
      );
      if (mounted) {
        setState(() { _nutritionData = result; _isLoading = false; });
      }
    } catch (e) {
       if (mounted) {
          setState(() => _isLoading = false);
          _showError('Analysis failed: ${e.toString()}');
       }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
       margin: const EdgeInsets.all(16),
    ));
  }

   void _showImageSourceDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerTheme.color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            _buildSourceOption(theme: theme, icon: Icons.camera_alt_outlined, title: 'Camera', onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
            const SizedBox(height: 12),
            _buildSourceOption(theme: theme, icon: Icons.photo_library_outlined, title: 'Gallery', onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
          ],
        ),
      ),
    );
  }

   Widget _buildSourceOption({ required ThemeData theme, required IconData icon, required String title, required VoidCallback onTap }) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.background, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerTheme.color ?? Colors.grey),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: theme.iconTheme.color),
            const SizedBox(width: 16),
            Text(title, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  void _addFoodAndReturn() {
    if (_nutritionData != null) {
      Navigator.pop(context, _nutritionData);
    } else { _showError('No analysis data to add'); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Add to ${widget.mealType}'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context), tooltip: 'Cancel'),
      ),
      body: GestureDetector(
         onTap: () => FocusScope.of(context).unfocus(),
         child: SafeArea(
          child: LayoutBuilder(
             builder: (context, constraints) {
                if (_imageSectionSize == Size.zero) {
                   WidgetsBinding.instance.addPostFrameCallback((_) => _captureImageSectionSize());
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildImageSection(theme),
                      const SizedBox(height: 24),
                      _buildInputAndActions(theme),
                      const SizedBox(height: 32),
                      _buildResultsSection(theme),
                    ],
                  ),
                );
             }
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
         key: _imageSectionKey,
         clipBehavior: Clip.antiAlias,
         decoration: BoxDecoration(
           color: theme.colorScheme.surfaceVariant,
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: theme.colorScheme.outlineVariant),
         ),
         child: Stack(
           fit: StackFit.expand,
           children: [
             if (_selectedImage != null)
               Image.file(_selectedImage!, fit: BoxFit.cover)
             else
               _buildImagePlaceholder(theme),

             if (_isLoading && _selectedImage != null && _imageSectionSize != Size.zero) ...[
               Container(color: Colors.black.withOpacity(0.5)),
               AnimatedScanLine(
                 width: _imageSectionSize.width,
                 height: _imageSectionSize.height,
                 color: theme.colorScheme.primary,
               ),
               const Center(child: CircularProgressIndicator(color: Colors.white)),
             ],

              if (_selectedImage != null && !_isLoading)
                Positioned(
                  top: 8, right: 8,
                  child: IconButton(
                    onPressed: () => setState(() { _selectedImage = null; _nutritionData = null; }),
                    icon: const Icon(Icons.cancel_rounded, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.4),
                      foregroundColor: Colors.white.withOpacity(0.8),
                      padding: const EdgeInsets.all(4),
                    ),
                    tooltip: 'Remove Image',
                  ),
                ),
           ],
         ),
      ),
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(Icons.camera_alt_outlined, size: 56, color: theme.colorScheme.secondary.withOpacity(0.6)),
           const SizedBox(height: 12),
           Text('Select an image to analyze', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.secondary)),
         ],
       ),
     );
  }

  Widget _buildInputAndActions(ThemeData theme) {
    return Column(
      children: [
        TextField(
          controller: _infoController,
          maxLines: 2,
          style: theme.textTheme.bodyMedium,
          decoration: const InputDecoration(
            hintText: 'Any extra details? (e.g., brand, cooking method)',
            prefixIcon: Icon(Icons.notes_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                label: const Text('Select'),
                style: OutlinedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _selectedImage != null && !_isLoading ? _analyzeImage : null,
                 style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 12),
                 ),
                icon: _isLoading
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
                    : const Icon(Icons.document_scanner_outlined, size: 20),
                label: Text(_isLoading ? 'Analyzing...' : 'Analyze Image'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultsSection(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: _nutritionData != null
          ? Column(
              key: const ValueKey('results'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NutritionCard(data: _nutritionData!),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _addFoodAndReturn,
                  icon: const Icon(Icons.add_task_outlined, size: 20),
                  label: const Text('Add Food Entry'),
                   style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    minimumSize: const Size(double.infinity, 50),
                     textStyle: theme.textTheme.labelLarge,
                  ),
                )
              ],
            )
          : Container(key: const ValueKey('empty')),
    );
  }
}