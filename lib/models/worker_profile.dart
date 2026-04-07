import 'package:cloud_firestore/cloud_firestore.dart';

/// Profile that job seekers fill out to be discoverable by employers.
class WorkerProfile {
  final String uid;
  final String name;
  final String phone;

  /// Selected job category slugs (matches kCategories keys).
  final List<String> categories;

  /// Free-text description of skills / what the person can do.
  final String skills;

  final int age;

  /// 'male' | 'female' | '' (empty = not set)
  final String gender;

  final DateTime updatedAt;

  const WorkerProfile({
    required this.uid,
    required this.name,
    required this.phone,
    required this.categories,
    required this.skills,
    required this.age,
    required this.gender,
    required this.updatedAt,
  });

  factory WorkerProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return WorkerProfile(
      uid: doc.id,
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      categories: List<String>.from(d['categories'] as List? ?? []),
      skills: d['skills'] as String? ?? '',
      age: d['age'] as int? ?? 0,
      gender: d['gender'] as String? ?? '',
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory WorkerProfile.fromMap(String uid, Map<String, dynamic> d) {
    return WorkerProfile(
      uid: uid,
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      categories: List<String>.from(d['categories'] as List? ?? []),
      skills: d['skills'] as String? ?? '',
      age: d['age'] as int? ?? 0,
      gender: d['gender'] as String? ?? '',
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        'categories': categories,
        'skills': skills,
        'age': age,
        'gender': gender,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  bool get isComplete =>
      categories.isNotEmpty &&
      age > 0 &&
      skills.trim().isNotEmpty &&
      gender.isNotEmpty;
}
