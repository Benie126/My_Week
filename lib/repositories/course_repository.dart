import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';

class CourseRepository {
  CourseRepository(this.uid);

  final String uid;

  CollectionReference<Map<String, dynamic>> get _courses =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('courses');

  Stream<List<Course>> watchAll() => _courses.snapshots().map(
        (snapshot) => snapshot.docs.map(Course.fromDoc).toList(),
  );

  Future<void> add(Course course) => _courses.add(course.toMap());

  Future<void> update(String id, Course course) => _courses.doc(id).update(course.toMap());

  Future<void> delete(String id) => _courses.doc(id).delete();
}