import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String name;
  final String day;
  final String time;

  Course({this.id = '', required this.name, required this.day, required this.time});

  Map<String, dynamic> toMap() {
    return {'name': name, 'day': day, 'time': time};
  }

  factory Course.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Course(
      id: doc.id,
      name: data['name'] as String,
      day: data['day'] as String,
      time: data['time'] as String,
    );
  }
}