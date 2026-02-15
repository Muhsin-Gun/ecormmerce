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
import 'screens/splash_screen.dart';

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
        
        // Auth Provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..init(),
        ),

        // Theme Provider (reacts to current auth user)
        ChangeNotifierProxyProvider<AuthProvider, ThemeProvider>(
          create: (_) => ThemeProvider()..init(),
          update: (_, auth, themeProvider) {
            final provider = themeProvider ?? ThemeProvider();
            provider.setUserId(auth.firebaseUser?.uid);
            return provider;
          },
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
            home: const EntryRouter(),
          );
        },
      ),
    );
  }
}

class EntryRouter extends StatefulWidget {
  const EntryRouter({super.key});

  @override
  State<EntryRouter> createState() => _EntryRouterState();
}

class _EntryRouterState extends State<EntryRouter> {
  bool _splashDone = false;

  void _onSplashFinished() {
    if (mounted) setState(() => _splashDone = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _splashDone
          ? const AuthWrapper(key: ValueKey('auth'))
          : SplashScreen(
              key: const ValueKey('splash'),
              onFinished: _onSplashFinished,
            ),
    );
  }
}
