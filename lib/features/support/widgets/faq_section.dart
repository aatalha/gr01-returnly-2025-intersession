import 'package:flutter/material.dart';

class FaqSection extends StatelessWidget {
  const FaqSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final faqItems = {
      "How do I report a lost item?": "Tap the 'Add Post' button on the home screen, select 'Lost', fill in the details, and submit.",
      "How do I verify ownership?": "Use the secure in-app chat to ask the finder specific questions about the item that only the true owner would know.",
      "Is my personal information safe?": "Yes, chat is handled entirely within the app. You never need to share your phone number or personal email.",
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: faqItems.entries.map((entry) {
          return ExpansionTile(
            title: Text(entry.key, style: TextStyle(fontWeight: FontWeight.w600)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(entry.value),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}