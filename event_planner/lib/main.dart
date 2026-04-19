import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'core/api/auth_service.dart';
import 'core/api/event_service.dart';
import 'core/api/social_service.dart';
import 'core/utils/storage_helper.dart';
import 'core/services/push_notification_service.dart';
import 'features/auth/auth_provider.dart';
import 'features/events/events_provider.dart';
import 'features/notifications/notifications_provider.dart';
import 'features/groups/social_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/events/create_events_screen.dart';
import 'features/events/event_detail_page.dart';
import 'features/events/event_planning_screen.dart';
import 'features/events/ticket_view_screen.dart';
import 'features/events/my_events_screen.dart';
import 'features/search/search_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/safety/safety_center_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/messages/messages_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Push Notifications (OneSignal)
  final pushNotificationService = PushNotificationService();
  await pushNotificationService.initialize();

  // Set preferred orientations to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables from .env file
  try {
    // Try to load from current directory first (for development)
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // If that fails, try to load from the application documents directory
    try {
      final directory = await getApplicationDocumentsDirectory();
      final envFile = File('${directory.path}/.env');
      if (await envFile.exists()) {
        await dotenv.load(fileName: envFile.path);
      }
    } catch (_) {
      // Fall back to empty env if all else fails
      debugPrint('Warning: Could not load .env file');
    }
  }

  debugPrint('Environment loaded. LOCAL_IP = ${dotenv.env['LOCAL_IP']}');
  // Initialize secure storage
  final storage = FlutterSecureStorage();

  // Initialize services
  final authService = AuthService();
  final eventService = EventService();
  final socialService = SocialService();

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
        ChangeNotifierProvider(
          create: (_) => NotificationsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SocialProvider(socialService: socialService),
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
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
          return EventDetailPage(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/events/:id/plan',
        name: 'event-planning',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return EventPlanningScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/events/:id/ticket',
        name: 'ticket',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return TicketViewScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/my-events',
        name: 'my-events',
        builder: (context, state) => const MyEventsScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/safety/:eventId',
        name: 'safety-center',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final eventName = state.extra as Map<String, dynamic>?;
          return SafetyCenterScreen(
            eventId: eventId,
            eventName: eventName?['eventName'],
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/messages/:conversationId',
        name: 'messages',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return MessagesScreen(conversationId: conversationId);
        },
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
      final isOnboardingPage = state.matchedLocation == '/onboarding';

      // Allow access to splash, landing, login, and register pages without auth
      if (!isAuthenticated &&
          !isLoginPage &&
          !isRegisterPage &&
          !isSplashPage &&
          !isOnboardingPage) {
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
