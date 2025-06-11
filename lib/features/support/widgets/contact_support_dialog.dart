import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void showContactSupportDialog(BuildContext context, {bool isReport = false}) {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController();
  bool isLoading = false;

  showDialog(
    context: context,
    barrierDismissible: false, 
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isReport ? "Report Issue" : "Contact Support"),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isReport
                      ? "Please describe the issue with the user or item listing."
                      : "Please describe your technical issue in detail."),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Your message...",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 10) {
                        return "Please provide at least 10 characters.";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text("Cancel"),
              ),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setState(() => isLoading = true);
                          
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            final collection = isReport 
                                ? 'reports' 
                                : 'support_tickets';
                            
                            final docRef = FirebaseFirestore.instance
                                .collection(collection)
                                .doc();
                            
                            await docRef.set({
                              'id': docRef.id,
                              'userId': user?.uid,
                              'userEmail': user?.email,
                              'message': controller.text,
                              'timestamp': FieldValue.serverTimestamp(),
                              'status': 'New',
                              'type': isReport ? 'content_report' : 'support_request',
                            });
                            
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Your message has been sent successfully!"),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text("Failed to send: ${e.toString()}"),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                child: isLoading 
                    ? SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text("Submit"),
                    
              ),
            ],
          );
        },
      );
    },
  );
}