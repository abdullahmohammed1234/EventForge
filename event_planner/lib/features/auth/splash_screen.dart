import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
    // Show splash for at least 1.5 seconds for better UX
    final minSplashDuration = Future.delayed(const Duration(milliseconds: 1500));
    
    // Also wait for auth check to complete
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authCheck = _waitForAuthCheck(authProvider);
    
    // Wait for both minimum duration and auth check
    await Future.wait([minSplashDuration, authCheck]);

    if (mounted) {
      // Navigate based on auth status: home if logged in, landing if not
      if (authProvider.isAuthenticated) {
        context.go('/home');
      } else {
        context.go('/landing');
      }
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
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Image.asset(
          'assets/SplashScreen.gif',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
