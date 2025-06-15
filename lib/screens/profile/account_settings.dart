import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/theme_mode_notifier.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _nameController = TextEditingController();
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  bool _savingName = false;
  bool _savingPw = false;
  String? _message;

  @override
  void dispose() {
    _nameController.dispose();
    _currentPwController.dispose();
    _newPwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final themeNotifier = context.watch<ThemeModeNotifier>();
    _nameController.text = user?.displayName ?? '';

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // letting theme control background, icons, text style
      ),
      // scaffoldBackgroundColor comes from theme
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          // Edit Name
          Text('Edit Name', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            // uses cardTheme.surface color
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "User Name",
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                              minimumSize: const Size(120, 36), // Minimum width 120, height 36
                              padding: const EdgeInsets.symmetric(horizontal: 24.0), // Horizontal padding
                            ),
                      onPressed: _savingName ? null : () async {
                        setState(() { _savingName = true; _message = null; });
                        try {
                          await user?.updateDisplayName(_nameController.text.trim());
                          await user?.reload();
                          setState(() { _message = "Username updated!"; });
                        } catch (e) {
                          setState(() { _message = "Failed: $e"; });
                        } finally {
                          setState(() { _savingName = false; });
                        }
                      },
                      child: _savingName
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Change Password
          Text('Change Password', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _currentPwController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Current Password",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPwController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "New Password",
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                              minimumSize: const Size(120, 36), // Minimum width 120, height 36
                              padding: const EdgeInsets.symmetric(horizontal: 24.0), // Horizontal padding
                            ),
                      // Inside your onPressed for "Change Password":
                      onPressed: _savingPw ? null : () async {
                        setState(() {
                          _savingPw = true;
                          _message = null;
                        });

                        try {
                          // 1) Reauthenticate
                          final cred = EmailAuthProvider.credential(
                            email: user!.email!,
                            password: _currentPwController.text.trim(),
                          );
                          await user.reauthenticateWithCredential(cred);

                          // 2) If that succeeds, update to the new password
                          await user.updatePassword(_newPwController.text.trim());
                          setState(() {
                            _message = "Password updated!";
                          });
                        } on FirebaseAuthException catch (e) {
                          // Friendly, specific messages
                          if (e.code == 'wrong-password') {
                            setState(() {
                              _message = "Current password is incorrect.";
                            });
                          } else if (e.code == 'weak-password') {
                            setState(() {
                              _message = "Your new password is too weak.";
                            });
                          } else {
                            setState(() {
                              _message = "Error: ${e.message}";
                            });
                          }
                        } catch (e) {
                          setState(() {
                            _message = "Unexpected error: $e";
                          });
                        } finally {
                          setState(() {
                            _savingPw = false;
                          });
                        }
                      },

                      child: _savingPw
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Change Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Appearance (Dark / Light)
          Text('Appearance', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              value: themeNotifier.themeMode == ThemeMode.dark,
              onChanged: (val) {
                context.read<ThemeModeNotifier>()
                  .setTheme(val ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),

          if (_message != null) ...[
            const SizedBox(height: 24),
            Center(
              child: Text(
                _message!,
                style: textTheme.bodyMedium?.copyWith(
                  color: _message!.contains("Failed")
                      ? colorScheme.error
                      : colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
