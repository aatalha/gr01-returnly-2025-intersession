import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:returnly/auth/auth_gate.dart';
import 'package:returnly/features/chat/screens/chat_detail_screen.dart';
import 'package:returnly/features/chat/screens/messages_list_screen.dart';
import 'package:returnly/features/chat/services/chat_services.dart';
import 'package:returnly/features/support/screens/help_support_screen.dart';
import 'package:returnly/firebase_options.dart';
import 'package:returnly/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Returnly',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class TestHomeScreen extends StatefulWidget {
  @override
  _TestHomeScreenState createState() => _TestHomeScreenState();
}

class _TestHomeScreenState extends State<TestHomeScreen> {
  bool _isCreatingChat = false;

  Future<void> _createTestChatAndNavigate() async {
    setState(() => _isCreatingChat = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final chatService = ChatService();
      
      final chatId = await chatService.getOrCreateChatWithUser(
        "test_user_id_123", 
        "Test User",
        "Current User"
      );
      
      await chatService.sendMessage(chatId, "Hello! I found your lost item.");
      await Future.delayed(Duration(milliseconds: 500));
      await chatService.sendMessage(chatId, "Can you describe it for verification?");
      await Future.delayed(Duration(milliseconds: 500));
      

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chatId: chatId,
            receiverName: "Test User",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating test chat: $e")),
      );
    } finally {
      setState(() => _isCreatingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Returnly (Test Menu)")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Signed in with UID:"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                FirebaseAuth.instance.currentUser!.uid,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.message_outlined),
              label: Text("Go to My Messages"),
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => MessagesListScreen())
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: _isCreatingChat
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.chat_bubble_outline),
              label: Text(_isCreatingChat 
                  ? "Creating Test Chat..." 
                  : "Create Test Chat"),
              onPressed: _isCreatingChat ? null : _createTestChatAndNavigate,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.support_agent_outlined),
              label: Text("Go to Help & Support"),
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => HelpSupportScreen())
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () => FirebaseAuth.instance.signOut(), 
              child: Text("Sign Out (for testing)")
            ),
          ],
        ),
      ),
    );
  }
}