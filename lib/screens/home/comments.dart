import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Comments extends StatelessWidget {
  final String text;
  final String user;
  final String timestamp;
  const Comments({super.key, required this.text, required this.user, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: TextStyle(fontSize: 14)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(user, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('.'),
              Text(timestamp, style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}