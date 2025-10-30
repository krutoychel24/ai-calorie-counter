
import 'package:calorie_counter_app/services/auth_service.dart';
import 'package:calorie_counter_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firestoreService = FirestoreService();
  late final String _uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { return; }
    _uid = user.uid;
  }

  Future<void> _signOut() async {
    await Provider.of<AuthService>(context, listen: false).signOut();
  }

  Future<void> _resetSetup() async {
    await _firestoreService.deleteUserData(_uid);
    if (mounted) {
      await Provider.of<AuthService>(context, listen: false).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildSectionHeader(theme, 'Application'),
          _buildStyledCard(
            theme,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.language_outlined, color: theme.colorScheme.primary),
                  title: const Text('Language'),
                  subtitle: const Text('App language (coming soon)'),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.dark_mode_outlined, color: theme.colorScheme.tertiary),
                  title: const Text('Theme'),
                  subtitle: const Text('Dark/Light mode (coming soon)'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(theme, 'Account'),
          _buildStyledCard(
            theme,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.restart_alt, color: Colors.orange.shade400),
                  title: const Text('Reset Setup'),
                  subtitle: const Text('Delete profile data & start setup again'),
                  onTap: _resetSetup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red.shade400),
                  title: const Text('Sign Out'),
                  onTap: _signOut,
                ),
              ],
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

  Widget _buildStyledCard(ThemeData theme, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}
