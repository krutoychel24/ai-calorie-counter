import 'package:calorie_counter_app/screens/setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  await initializeDateFormatting('en_US', null);

  final prefs = await SharedPreferences.getInstance();
  final isSetupComplete = prefs.getBool('isSetupComplete') ?? false;

  runApp(CalorieCounterApp(home: isSetupComplete ? const HomeScreen() : const SetupScreen()));
}

class CalorieCounterApp extends StatelessWidget {
  final Widget home;
  const CalorieCounterApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriScan', // App title (can be changed)
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // You might want to define this too
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Force dark theme
      home: home,
    );
  }
}