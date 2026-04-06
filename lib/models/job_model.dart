import 'package:hive/hive.dart';

part 'job_model.g.dart';

@HiveType(typeId: 1)
class Job extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String salary;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String category; // 'simple_jobs', 'office_jobs', 'online_jobs'

  @HiveField(5)
  String description;

  @HiveField(6)
  String location;

  @HiveField(7)
  double distance; // in km

  @HiveField(8)
  String employerId;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  int viewsCount;

  @HiveField(11)
  int contactsCount;

  Job({
    required this.id,
    required this.title,
    required this.salary,
    required this.phone,
    required this.category,
    required this.description,
    required this.location,
    required this.distance,
    required this.employerId,
    required this.createdAt,
    this.viewsCount = 0,
    this.contactsCount = 0,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String,
      title: json['title'] as String,
      salary: json['salary'] as String,
      phone: json['phone'] as String,
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      employerId: json['employerId'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      viewsCount: json['viewsCount'] as int? ?? 0,
      contactsCount: json['contactsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'salary': salary,
      'phone': phone,
      'category': category,
      'description': description,
      'location': location,
      'distance': distance,
      'employerId': employerId,
      'createdAt': createdAt.toIso8601String(),
      'viewsCount': viewsCount,
      'contactsCount': contactsCount,
    };
  }

  @override
  String toString() => 'Job(id: $id, title: $title, salary: $salary)';
}
