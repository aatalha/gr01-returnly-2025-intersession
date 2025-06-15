import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:returnly_app/screens/home/add_post_page.dart';
import 'package:returnly_app/screens/profile/about_us_screen.dart';
import 'package:returnly_app/screens/profile/account_settings.dart';
import 'package:returnly_app/screens/profile/privacy_policy_screen.dart';
import 'package:returnly_app/screens/profile/terms_conditions_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;

      // If user is on splash screen, let them through
      if (state.fullPath == '/splash') {
        return null;
      }

      // If user is not logged in and trying to access protected routes
      if (!isLoggedIn &&
          !state.fullPath!.startsWith('/login') &&
          !state.fullPath!.startsWith('/signup')) {
        return '/login';
      }

      // If user is logged in and trying to access auth screens
      if (isLoggedIn &&
          (state.fullPath!.startsWith('/login') ||
              state.fullPath!.startsWith('/signup'))) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'add_post',
            builder: (context, state) => const AddPostPage(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutUsScreen(),
          ),
          GoRoute(
            path: 'privacy-policy',
            builder: (context, state) => const PrivacyPolicyScreen(),
          ),
          GoRoute(
            path: 'terms-conditions',
            builder: (context, state) => const TermsConditionsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => const AccountSettingsScreen(),
          ),
        ],
      ),
    ],
  );
}