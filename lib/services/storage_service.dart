// storage_service.dart
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static Future<String> getDownloadUrl(String path) async {
    try {
      return await FirebaseStorage.instance.ref(path).getDownloadURL();
    } catch (e) {
      print("Error getting download URL: $e");
      return ""; // Return empty string or placeholder
    }
  }
}