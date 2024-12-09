import 'package:cloud_firestore/cloud_firestore.dart';

class UserHabit {
  String id;
  String name;
  String category;
  String description;
  String icon;
  int color;
  bool active;

  UserHabit({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
    required this.active,
  });

  factory UserHabit.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserHabit(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '',
      color: data['color'] ?? 0,
      active: data['active'] ?? false,
    );
  }
}
