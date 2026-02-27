import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/app_config.dart';
import 'core/api/auth_service.dart';
import 'core/api/event_service.dart';
import 'core/utils/storage_helper.dart';
import 'features/auth/auth_provider.dart';
import 'features/events/events_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/landing_screen.dart';
import 'features/home/home_screen.dart';
import 'features/events/create_events_screen.dart';
import 'features/events/event_details_screen.dart';
import 'features/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
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
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/landing',
        name: 'landing',
        builder: (context, state) => const LandingScreen(),
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
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/events',
        name: 'events',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/events/create',
        name: 'create-event',
        builder: (context, state) => CreateEventScreen(),
      ),
      GoRoute(
        path: '/events/:id',
        name: 'event-details',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return EventDetailsScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (context, state) {
      // Skip redirect for splash screen during initial load
      if (state.matchedLocation == '/') {
        return null;
      }

      // Try to get auth provider, skip redirect if not available
      AuthProvider? authProvider;
      try {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
      } catch (_) {
        return null;
      }

      final isAuthenticated = authProvider.isAuthenticated;
      final isCheckingAuth = authProvider.isCheckingAuth;

      if (isCheckingAuth) {
        return null;
      }

      final isLoginPage = state.matchedLocation == '/login';
      final isRegisterPage = state.matchedLocation == '/register';
      final isSplashPage = state.matchedLocation == '/';
      final isLandingPage = state.matchedLocation == '/landing';

      // Allow access to splash, landing, login, and register pages without auth
      if (!isAuthenticated && !isLoginPage && !isRegisterPage && !isSplashPage && !isLandingPage) {
        return '/login';
      }

      // Redirect logged-in users away from auth pages
      if (isAuthenticated && (isLoginPage || isRegisterPage)) {
        return '/home';
      }

      return null;
    },
  );
}

// Auth check screen - redirects to login or home
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
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
