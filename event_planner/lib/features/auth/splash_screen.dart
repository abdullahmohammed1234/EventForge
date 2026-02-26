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
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.event,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              // App Name
              const Text(
                'EventForge',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // Tagline
              const Text(
                'Find all the events you never hear about',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 48),
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
