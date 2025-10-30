import 'package:flutter/material.dart';
import '../models/nutrition_data.dart';

class NutritionCard extends StatelessWidget {
  final NutritionData data;

  const NutritionCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column( // Simpler Column for header now
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(data.dishName, style: theme.textTheme.headlineSmall),
                 const SizedBox(height: 4),
                 Text('${data.weight.toStringAsFixed(0)} g estimate', style: theme.textTheme.bodyMedium),
               ],
            ),
          ),

          const Divider(height: 1),

          // Macros Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMacroRow(
                  theme: theme, label: 'Calories',
                  value: data.calories.toStringAsFixed(0), unit: 'kcal',
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildMacroItem(theme: theme, label: 'Protein', value: data.protein.toStringAsFixed(1), color: theme.colorScheme.primaryContainer)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMacroItem(theme: theme, label: 'Carbs', value: data.carbs.toStringAsFixed(1), color: theme.colorScheme.tertiary)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMacroItem(theme: theme, label: 'Fat', value: data.fat.toStringAsFixed(1), color: theme.colorScheme.secondaryContainer)),
                  ],
                ),
              ],
            ),
          ),

          // Ingredients Section
          if (data.ingredients.isNotEmpty) ...[
            const Divider(height: 1, indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Main Ingredients', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: data.ingredients.map((ingredient) => Chip(
                       label: Text(ingredient),
                       labelStyle: theme.textTheme.bodySmall,
                       backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.7),
                       side: BorderSide.none,
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                       visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroRow({
    required ThemeData theme, required String label, required String value,
    required String unit, required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.titleMedium),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text(unit, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
          ],
        ),
      ],
    );
  }

 Widget _buildMacroItem({
    required ThemeData theme, required String label,
    required String value, required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: theme.textTheme.labelMedium?.copyWith(color: color)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text('g', style: theme.textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}