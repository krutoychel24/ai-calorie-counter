import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize locale for date formatting (English)
  await initializeDateFormatting('en_US', null); // Changed locale

  runApp(const CalorieCounterApp());
}

class CalorieCounterApp extends StatelessWidget {
  const CalorieCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriScan', // App title (can be changed)
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // You might want to define this too
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Force dark theme
      home: const HomeScreen(),
    );
  }
}