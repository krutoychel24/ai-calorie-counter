import 'package:calorie_counter_app/services/auth_service.dart';
import 'package:calorie_counter_app/widgets/auth_wrapper.dart';
import 'package:calorie_counter_app/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/connectivity_service.dart';
import 'utils/theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // Use debug provider for development
    appleProvider: AppleProvider.debug, // Use debug provider for development
  );

  // Initialize locale for date formatting (English)
  await initializeDateFormatting('en_US', null);

  runApp(const CalorieCounterApp());
}

class CalorieCounterApp extends StatelessWidget {
  const CalorieCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<ConnectivityService>(
          create: (_) => ConnectivityService(),
        ),
      ],
      child: MaterialApp(
        title: 'NutriScan',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: const AuthWrapper(),
          bottomNavigationBar: OfflineBanner(),
        ),
      ),
    );
  }
}