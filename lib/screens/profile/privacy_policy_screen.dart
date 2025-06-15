import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          '''
Your privacy matters to us. This Privacy Policy explains how Returnly collects, uses, and safeguards your personal information when you use our mobile application.

• **Information We Collect:** We may collect your name, email address, and any other information you choose to share when creating posts or comments.  
• **How We Use Your Information:** We use your data to authenticate you, personalize your experience, and facilitate lost & found postings.  
• **Data Sharing:** We never sell your data. We only share information with third parties when required by law or to provide core app functionality.  
• **Security:** We use industry-standard encryption and security practices to protect your data.  

By using Returnly, you consent to the terms of this Privacy Policy. If you have questions, contact us at privacy@returnly.app.
          ''',
          style: textStyle,
        ),
      ),
    );
  }
}
