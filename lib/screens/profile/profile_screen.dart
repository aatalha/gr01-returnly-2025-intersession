import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        elevation: 0,
        // backgroundColor is omitted so it uses theme.appBarTheme.backgroundColor
      ),
      // scaffoldBackgroundColor comes from your theme now
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Section header uses theme text style
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Menu items
                  ListTile(
                    title: const Text('Account Settings'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.go('/settings'),
                  ),
                  
                  ListTile(
                    title: const Text('About Us'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.go('/about'),
                  ),

                  ListTile(
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.go('/privacy-policy'),
                  ),
                  ListTile(
                    title: const Text('Terms & Conditions'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.go('/terms-conditions'),
                  ),

                  const SizedBox(height: 32),

                  // App version & logout
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Versions',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'v0.0.1',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(120, 36), // Minimum width 120, height 36
                              padding: const EdgeInsets.symmetric(horizontal: 24.0), // Horizontal padding
                            ),
                            onPressed: () async {
                              await authService.signOut();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                            child: const Text('Log Out'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
