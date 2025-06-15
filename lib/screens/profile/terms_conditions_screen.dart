import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          '''
Welcome to Returnly. By accessing or using our app, you agree to these Terms & Conditions:

1. **Use of Service:** You may only use Returnly for lawful purposes and in accordance with this agreement.  
2. **User Content:** You are responsible for any posts, comments, or data you submit. Do not post illegal, defamatory, or infringing content.  
3. **Intellectual Property:** All app content is owned by Returnly. You may not copy, modify, or distribute any part of the service without permission.  
4. **Limitation of Liability:** Returnly is provided “as is.” We are not liable for lost items, data breaches, or any indirect damages.  
5. **Governing Law:** These terms are governed by the laws of your jurisdiction.

If you disagree with any part of these terms, please do not use our service.
          ''',
          style: textStyle,
        ),
      ),
    );
  }
}
