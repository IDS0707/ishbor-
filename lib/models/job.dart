import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight Job model used by the new screens layer.
/// (The legacy [job_model.dart] with Hive adapters is kept for backwards compat.)
class Job {
  final String id;
  final String title;
  final String salary;
  final String phone;
  final String category;
  final String description;
  final String postedByUid;
  final DateTime createdAt;
  final String region;
  final String workAddress;
  final String workStart;
  final String workEnd;
  final double latitude;
  final double longitude;

  /// One of: 'emp_fulltime' | 'emp_parttime' | 'emp_onetime' | ''
  final String employmentType;

  /// Minimum worker age (0 = no limit).
  final int ageMin;

  /// Maximum worker age (0 = no limit).
  final int ageMax;

  /// Preferred worker gender: 'male' | 'female' | '' (any).
  final String gender;

  const Job({
    required this.id,
    required this.title,
    required this.salary,
    required this.phone,
    required this.createdAt,
    this.category = 'cat_other',
    this.description = '',
    this.postedByUid = '',
    this.region = '',
    this.workAddress = '',
    this.workStart = '',
    this.workEnd = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.employmentType = '',
    this.ageMin = 0,
    this.ageMax = 0,
    this.gender = '',
  });

  factory Job.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Job(
      id: doc.id,
      title: d['title'] as String? ?? '',
      salary: d['salary'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      category: d['category'] as String? ?? 'cat_other',
      description: d['description'] as String? ?? '',
      postedByUid: d['postedByUid'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      region: d['region'] as String? ?? '',
      workAddress: d['workAddress'] as String? ?? '',
      workStart: d['workStart'] as String? ?? '',
      workEnd: d['workEnd'] as String? ?? '',
      latitude: (d['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (d['longitude'] as num?)?.toDouble() ?? 0.0,
      employmentType: d['employmentType'] as String? ?? '',
      ageMin: d['ageMin'] as int? ?? 0,
      ageMax: d['ageMax'] as int? ?? 0,
      gender: d['gender'] as String? ?? '',
    );
  }

  /// Only the fields written to Firestore — id is auto-assigned, createdAt
  /// uses a server timestamp so the client value is intentionally ignored.
  Map<String, dynamic> toFirestore() => {
        'title': title,
        'salary': salary,
        'phone': phone,
        'category': category,
        'description': description,
        'postedByUid': postedByUid,
        'createdAt': FieldValue.serverTimestamp(),
        'region': region,
        'workAddress': workAddress,
        'workStart': workStart,
        'workEnd': workEnd,
        'latitude': latitude,
        'longitude': longitude,
        'employmentType': employmentType,
        'ageMin': ageMin,
        'ageMax': ageMax,
        'gender': gender,
      };
}
