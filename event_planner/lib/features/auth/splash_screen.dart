import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/utils/storage_helper.dart';
import 'auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Show splash for at least 2.5 seconds for better UX
    final minSplashDuration =
        Future.delayed(const Duration(milliseconds: 4500));

    // Also wait for auth check to complete
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authCheck = _waitForAuthCheck(authProvider);

    // Wait for both minimum duration and auth check
    await Future.wait([minSplashDuration, authCheck]);

    if (!mounted) return;

    // Check if onboarding has been completed
    final storage = FlutterSecureStorage();
    final storageHelper = StorageHelper(storage);
    final isOnboardingComplete = await storageHelper.isOnboardingComplete();

    // Navigate based on auth status and onboarding completion
    if (!isOnboardingComplete) {
      // First time user - show onboarding
      context.go('/onboarding');
    } else if (authProvider.isAuthenticated) {
      // Already authenticated - go to home
      context.go('/home');
    } else {
      // Not authenticated - go to register
      context.go('/register');
    }
  }

  Future<void> _waitForAuthCheck(AuthProvider authProvider) async {
    while (authProvider.isCheckingAuth) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/SplashScreen.gif',
          fit: BoxFit.cover, // Makes it fill the entire screen
        ),
      ),
    );
  }
}
