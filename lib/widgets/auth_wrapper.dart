
import 'package:calorie_counter_app/screens/home_screen.dart';
import 'package:calorie_counter_app/screens/setup_screen.dart';
import 'package:calorie_counter_app/services/auth_service.dart';
import 'package:calorie_counter_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../screens/auth_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    // Also create an instance of FirestoreService to be used in the check
    final firestoreService = FirestoreService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          if (user == null) {
            return const AuthScreen();
          } 
          // If user is logged in, check if they have a document in Firestore
          return FutureBuilder<bool>(
            future: firestoreService.checkIfUserExists(user.uid),
            builder: (context, userExistsSnapshot) {
              if (userExistsSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (userExistsSnapshot.data == true) {
                return const HomeScreen();
              } else {
                return const SetupScreen();
              }
            },
          );
        }
        // While waiting for auth connection, show a loading indicator
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
