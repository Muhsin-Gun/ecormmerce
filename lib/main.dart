import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// Firebase Options
import 'firebase_options.dart';

// Core & Services
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/utils/app_error_reporter.dart';

// Providers
import 'shared/providers/theme_provider.dart';
import 'auth/providers/auth_provider.dart';
import 'shared/providers/product_provider.dart';
import 'shared/providers/cart_provider.dart';
import 'shared/providers/order_provider.dart';
import 'shared/providers/review_provider.dart';
import 'shared/providers/message_provider.dart';
import 'shared/providers/wishlist_provider.dart';
import 'shared/services/firebase_service.dart';
import 'auth/widgets/auth_wrapper.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await AppErrorReporter.init();

    // Initialize Notifications
    try {
      if (!kIsWeb) {
        await NotificationService.init();
      }
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }

    runApp(const ProMarketApp());
  }, (error, stack) {
    AppErrorReporter.report(error, stack);
  });
}

class ProMarketApp extends StatelessWidget {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const ProMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider.value(value: FirebaseService.instance),
        
        // Theme Provider
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..init(),
        ),
        
        // Auth Provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..init(),
        ),
        
        // Product Provider
        ChangeNotifierProvider(
          create: (_) => ProductProvider(),
        ),
        
        // Cart Provider
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) {
            final cartProvider = cart ?? CartProvider();
            unawaited(cartProvider.ensureLoadedForUser(auth.firebaseUser?.uid));
            return cartProvider;
          },
        ),
        
        // Order Provider
        ChangeNotifierProvider(
          create: (_) => OrderProvider(),
        ),

        // Review Provider
        ChangeNotifierProvider(
          create: (_) => ReviewProvider(),
        ),

        // Message Provider
        ChangeNotifierProvider(
          create: (_) => MessageProvider(),
        ),

        // Wishlist Provider - loads after user is authenticated
        ChangeNotifierProxyProvider<AuthProvider, WishlistProvider>(
          create: (_) => WishlistProvider(),
          update: (_, auth, wishlist) {
            final wishlistProvider = wishlist ?? WishlistProvider();
            unawaited(wishlistProvider.ensureLoadedForUser(auth.firebaseUser?.uid));
            return wishlistProvider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'ProMarket',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: ProMarketApp.scaffoldMessengerKey,
            navigatorKey: ProMarketApp.navigatorKey,
            
            // Theme
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            
            // Home
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

/// Splash Screen - Shows while loading app
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for providers to initialize
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Navigate to AuthWrapper which handles all routing logic
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A192F), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              // App Name
              Text(
                'ProMarket',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                'Buy. Sell. Manage. Anywhere.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
