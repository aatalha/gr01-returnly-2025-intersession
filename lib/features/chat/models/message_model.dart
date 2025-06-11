import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String text;
  final Timestamp timestamp;

  MessageModel({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      senderId: json['senderId'] as String,
      text: json['text'] as String,
      timestamp: json['timestamp'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
    };
  }
}