import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/api/auth_service.dart';
import 'core/api/event_service.dart';
import 'core/utils/storage_helper.dart';
import 'features/auth/auth_provider.dart';
import 'features/events/events_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/events/events_feed_screen.dart';
import 'features/events/create_events_screen.dart';
import 'features/profile/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize secure storage
  final storage = FlutterSecureStorage();
  
  // Initialize services
  final authService = AuthService();
  final eventService = EventService();
  
  // Initialize storage helper
  final storageHelper = StorageHelper(storage);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: authService,
            storage: storage,
            storageHelper: storageHelper,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => EventsProvider(
            eventService: eventService,
            storage: storage,
          ),
        ),
      ],
      child: EventPlannerApp(storageHelper: storageHelper),
    ),
  );
}

class EventPlannerApp extends StatelessWidget {
  final StorageHelper storageHelper;

  EventPlannerApp({super.key, required this.storageHelper});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Event Planner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          fillColor: Colors.grey[100],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }

  final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => AuthCheckScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => RegisterScreen(),
      ),
      GoRoute(
        path: '/events',
        name: 'events',
        builder: (context, state) => EventsFeedScreen(),
      ),
      GoRoute(
        path: '/events/create',
        name: 'create-event',
        builder: (context, state) => CreateEventScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => ProfileScreen(),
      ),
    ],
    redirect: (context, state) async {
      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = authProvider.isAuthenticated;
      final isCheckingAuth = authProvider.isCheckingAuth;

      if (isCheckingAuth) {
        return null; // Show splash while checking
      }

      final isLoginPage = state.matchedLocation == '/login';
      final isRegisterPage = state.matchedLocation == '/register';

      if (!isAuthenticated && !isLoginPage && !isRegisterPage) {
        return '/login';
      }

      if (isAuthenticated && (isLoginPage || isRegisterPage)) {
        return '/events';
      }

      return null;
    },
  );
}

// Auth check screen - redirects to login or events
class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isCheckingAuth) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authProvider.isAuthenticated) {
      return const EventsFeedScreen();
    }

    return const LoginScreen();
  }
}
