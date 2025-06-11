import 'package:flutter/material.dart';
import 'package:returnly/features/support/widgets/contact_support_dialog.dart';
import 'package:returnly/features/support/widgets/faq_section.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Help & Support"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            "Frequently Asked Questions",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FaqSection(), 

          const SizedBox(height: 32),

          Text(
            "Need More Help?",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.support_agent_outlined, color: Theme.of(context).colorScheme.primary),
              title: Text("Contact Technical Support"),
              subtitle: Text("Report a bug or request a feature"),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showContactSupportDialog(context);
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.report_problem_outlined, color: Colors.orange.shade700),
              title: Text("Report Inappropriate Content"),
              subtitle: Text("Report a user or an item listing"),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showContactSupportDialog(context, isReport: true);
              },
            ),
          ),
        ],
      ),
    );
  }
}