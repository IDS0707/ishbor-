import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String skills;

  @HiveField(4)
  String userType; // 'job_seeker' or 'employer'

  @HiveField(5)
  DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.skills,
    required this.userType,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      skills: json['skills'] as String? ?? '',
      userType: json['userType'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'skills': skills,
      'userType': userType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'User(id: $id, name: $name, userType: $userType)';
}
