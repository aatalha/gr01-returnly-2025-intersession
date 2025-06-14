import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final String location;
  final List<String> imageUrls;
  final bool isLost; // true for lost items, false for found items
  final String userId;
  final String userEmail;
  final String userDisplayName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ItemStatus status;
  final PriorityLevel priority;
  final String? claimedByUserId;
  final DateTime? claimedAt;

  ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.location,
    required this.imageUrls,
    required this.isLost,
    required this.userId,
    required this.userEmail,
    required this.userDisplayName,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.priority = PriorityLevel.normal,
    this.claimedByUserId,
    this.claimedAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'location': location,
      'imageUrls': imageUrls,
      'isLost': isLost,
      'userId': userId,
      'userEmail': userEmail,
      'userDisplayName': userDisplayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status.toString(),
      'priority': priority.toString(),
      'claimedByUserId': claimedByUserId,
      'claimedAt': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
    };
  }

  // Create from Firestore document
  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ItemModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      location: data['location'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      isLost: data['isLost'] ?? true,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userDisplayName: data['userDisplayName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      status: ItemStatus.values.firstWhere(
            (e) => e.toString() == data['status'],
        orElse: () => ItemStatus.active,
      ),
      priority: PriorityLevel.values.firstWhere(
            (e) => e.toString() == data['priority'],
        orElse: () => PriorityLevel.normal,
      ),
      claimedByUserId: data['claimedByUserId'],
      claimedAt: data['claimedAt'] != null
          ? (data['claimedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Create a copy with updated fields
  ItemModel copyWith({
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    String? location,
    List<String>? imageUrls,
    bool? isLost,
    ItemStatus? status,
    PriorityLevel? priority,
    String? claimedByUserId,
    DateTime? claimedAt,
  }) {
    return ItemModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      isLost: isLost ?? this.isLost,
      userId: userId,
      userEmail: userEmail,
      userDisplayName: userDisplayName,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      status: status ?? this.status,
      priority: priority ?? this.priority,
      claimedByUserId: claimedByUserId ?? this.claimedByUserId,
      claimedAt: claimedAt ?? this.claimedAt,
    );
  }
}

// Item status enum - matches project requirements
enum ItemStatus {
  active,     // Item is still lost/found and available
  claimed,    // Someone has claimed the item but not yet collected
  resolved,   // Item has been successfully returned to owner
  expired,    // Item post has expired (optional for cleanup)
}

// Priority level for important documents
enum PriorityLevel {
  normal,     // Regular items
  high,       // Important documents (ID cards, passports, etc.)
}

// Categories based on project wireframes and requirements
class ItemCategories {
  static const String electronics = 'Electronics';
  static const String books = 'Books';
  static const String clothing = 'Clothing';
  static const String documents = 'Documents';
  static const String accessories = 'Accessories';
  static const String jewelry = 'Jewelry';
  static const String waterBottle = 'Water Bottle';
  static const String charger = 'Charger';
  static const String keys = 'Keys';
  static const String glasses = 'Glasses';
  static const String others = 'Others';

  static List<String> get allCategories => [
    electronics,
    books,
    clothing,
    documents,
    accessories,
    jewelry,
    waterBottle,
    charger,
    keys,
    glasses,
    others,
  ];

  // High priority categories (important documents)
  static List<String> get highPriorityCategories => [
    documents,
  ];
}

// Campus locations based on project requirements
class CampusLocations {
  static const String scienceBuilding = 'Science Building';
  static const String libraryBuilding = 'Library Building';
  static const String universityCentre = 'University Centre';
  static const String engineeringBuilding = 'Engineering Building';
  static const String artsAdminBuilding = 'Arts and Administration Building';
  static const String residenceHalls = 'Residence Halls';
  static const String sportsComplex = 'Sports Complex';
  static const String cafeteria = 'Cafeteria';
  static const String parkingLot = 'Parking Lot';
  static const String studentServices = 'Student Services';
  static const String computerScienceBuilding = 'Computer Science Building';
  static const String others = 'Other Location';

  static List<String> get allLocations => [
    scienceBuilding,
    libraryBuilding,
    universityCentre,
    engineeringBuilding,
    artsAdminBuilding,
    residenceHalls,
    sportsComplex,
    cafeteria,
    parkingLot,
    studentServices,
    computerScienceBuilding,
    others,
  ];
}