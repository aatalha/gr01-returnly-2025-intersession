import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:returnly_app/theme/theme.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/theme_mode_notifier.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeModeNotifier()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: Consumer<ThemeModeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Returnly App',
            theme: lightMode,
            darkTheme: darkMode,
            themeMode: themeNotifier.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
