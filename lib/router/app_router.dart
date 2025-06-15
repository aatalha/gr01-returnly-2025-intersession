import 'package:go_router/go_router.dart';
import 'package:returnly_app/screens/auth/forgot_password_screen.dart';
import 'package:returnly_app/screens/auth/login_screen.dart';
import 'package:returnly_app/screens/auth/signup_screen.dart';
import 'package:returnly_app/screens/profile/account_settings.dart';
import 'package:returnly_app/screens/splash_screen.dart';         
import 'package:returnly_app/screens/home/home_screen.dart';
import 'package:returnly_app/screens/home/add_post_page.dart';
import 'package:returnly_app/screens/profile/about_us_screen.dart';
import 'package:returnly_app/screens/profile/privacy_policy_screen.dart';
import 'package:returnly_app/screens/profile/terms_conditions_screen.dart';
import 'package:returnly_app/services/auth_gate.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthGate(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),

      ),
      GoRoute(
        path: '/forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/home',
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
      // ✅ ADD DIRECT CHAT ROUTES (for external navigation)
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final otherUserName = state.uri.queryParameters['otherUserName'] ?? 'Unknown';
          final itemTitle = state.uri.queryParameters['itemTitle'] ?? 'Unknown Item';

          return ChatDetailScreen(
            chatId: chatId,
            otherUserName: otherUserName,
            itemTitle: itemTitle,
          );
        },
      ),
      // 📝 DEVELOPER B WILL ADD DIRECT NOTIFICATION ROUTES HERE LATER
    ],
  );
}
