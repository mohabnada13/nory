import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/background_gradient.dart';

// Firebase options will be replaced with actual config later
import 'firebase_options.dart';
// Real feature screens
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/checkout/checkout_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/address/address_form_screen.dart';

// Router configuration - will be moved to router.dart later
final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrdersScreen(),
    ),
    GoRoute(
      path: '/address_form',
      builder: (context, state) => const AddressFormScreen(),
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with default options
  // This will use google-services.json when added later
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  

  
  runApp(
    const ProviderScope(
      child: NoryShopApp(),
    ),
  );
}

class NoryShopApp extends StatelessWidget {
  const NoryShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nory Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}

// Placeholder screens - will be replaced with actual implementations
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate checking auth state
    Future.delayed(const Duration(seconds: 2), () {
      // For now, always navigate to onboarding as specified
      context.go('/onboarding');
      
      // Later, this will check auth state and navigate accordingly:
      // if (userIsAuthenticated) {
      //   context.go('/home');
      // } else {
      //   context.go('/onboarding');
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundGradient(
        child: Center(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppPalette.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.cake,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nory Shop',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppPalette.primaryStart,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bakery & Sweets',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.primaryEnd,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}


