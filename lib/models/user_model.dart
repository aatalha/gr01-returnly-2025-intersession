import 'package:cloud_firestore/cloud_firestore.dart';

// Enhanced user model with university data
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? university;
  final String? program;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profileImageUrl;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.university,
    this.program,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.profileImageUrl,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'university': university,
      'program': program,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'profileImageUrl': profileImageUrl,
    };
  }

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      university: data['university'],
      program: data['program'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      profileImageUrl: data['profileImageUrl'],
    );
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? displayName,
    String? university,
    String? program,
    bool? isActive,
    String? profileImageUrl,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      university: university ?? this.university,
      program: program ?? this.program,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  // Check if basic profile info is provided
  bool get hasBasicInfo {
    return displayName.isNotEmpty && email.isNotEmpty;
  }

  // Check if university info is provided
  bool get hasUniversityInfo {
    return university != null && program != null;
  }
}

// University and program data constants
class UniversityData {
  static const List<String> universities = [
    'University of Example',
    'Example State University',
    'Example Technical Institute',
    'Example Community College',
    // Can be expanded
  ];

  static const List<String> programs = [
    'Computer Science',
    'Software Engineering',
    'Information Technology',
    'Business Administration',
    'Engineering',
    'Arts and Sciences',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    // Can be expanded
  ];
}