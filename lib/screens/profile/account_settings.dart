import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Add this import
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
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          // Edit Name
          Text('Edit Name', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
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
                        minimumSize: const Size(120, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      ),
                      onPressed: _savingName ? null : () async {
                        setState(() { 
                          _savingName = true; 
                          _message = null; 
                        });
                        
                        try {
                          final newName = _nameController.text.trim();
                          if (newName.isEmpty) {
                            setState(() { 
                              _message = "Name cannot be empty"; 
                            });
                            return;
                          }

                          // Update Firebase Auth display name
                          await user?.updateDisplayName(newName);
                          await user?.reload();
                          
                          // Update Firestore user document (set with merge for both new and existing users)
                          if (user?.uid != null) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user!.uid)
                                .set({
                              'name': newName,
                              'displayName': newName, // for compatibility
                              'updatedAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));
                          }
                          
                          // Notify AuthService of changes
                          authService.notifyListeners();
                          
                          setState(() { 
                            _message = "Username updated successfully!"; 
                          });
                        } catch (e) {
                          setState(() { 
                            _message = "Failed to update username: ${e.toString()}"; 
                          });
                        } finally {
                          setState(() { 
                            _savingName = false; 
                          });
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
                      helperText: "Password must be at least 6 characters",
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      ),
                      onPressed: _savingPw ? null : () async {
                        setState(() {
                          _savingPw = true;
                          _message = null;
                        });

                        try {
                          // Validate inputs
                          if (_currentPwController.text.trim().isEmpty) {
                            setState(() {
                              _message = "Please enter your current password";
                            });
                            return;
                          }
                          
                          if (_newPwController.text.trim().length < 6) {
                            setState(() {
                              _message = "New password must be at least 6 characters";
                            });
                            return;
                          }

                          // Reauthenticate with current password
                          final credential = EmailAuthProvider.credential(
                            email: user!.email!,
                            password: _currentPwController.text.trim(),
                          );
                          await user.reauthenticateWithCredential(credential);

                          // Update to new password
                          await user.updatePassword(_newPwController.text.trim());
                          
                          // Clear password fields
                          _currentPwController.clear();
                          _newPwController.clear();
                          
                          setState(() {
                            _message = "Password updated successfully!";
                          });
                        } on FirebaseAuthException catch (e) {
                          String errorMessage;
                          switch (e.code) {
                            case 'wrong-password':
                              errorMessage = "Current password is incorrect";
                              break;
                            case 'weak-password':
                              errorMessage = "New password is too weak";
                              break;
                            case 'requires-recent-login':
                              errorMessage = "Please log out and log back in before changing password";
                              break;
                            default:
                              errorMessage = "Error: ${e.message}";
                          }
                          setState(() {
                            _message = errorMessage;
                          });
                        } catch (e) {
                          setState(() {
                            _message = "Unexpected error: ${e.toString()}";
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
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message!.toLowerCase().contains("success") 
                      ? colorScheme.primaryContainer 
                      : colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: _message!.toLowerCase().contains("success")
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onErrorContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
