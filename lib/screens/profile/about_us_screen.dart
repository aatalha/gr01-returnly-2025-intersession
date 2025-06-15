import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          '''
Returnly is your community-driven lost & found marketplace, making it easy to reconnect with misplaced items or reunite lost treasures with their owners. Whether you’ve lost something precious or you’ve found an item someone left behind, Returnly provides a simple, intuitive platform to post, search, and claim items in real time.

Founded on the principles of trust, transparency, and collaboration, our mission is to turn the frustration of losing something into a streamlined process that empowers neighbors to help each other. Join the Returnly family today and help build a safer, more connected world—one returned item at a time.
          ''',
          style: textStyle,
        ),
      ),
    );
  }
}
