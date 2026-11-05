import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';

class CourseState extends ChangeNotifier {
  CourseState(this._repo) {
    // Born: listen to Firestore
    _subscription = _repo.watchAll().listen(
          (list) {
        _courses = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = 'Could not load your courses.';
        notifyListeners();
      },
    );
  }

  final CourseRepository _repo;
  StreamSubscription<List<Course>>? _subscription;

  // Private data
  List<Course> _courses = [];
  bool _loading = true;
  String? _error;

  // Filter data
  String _filter = 'all';

  // Read-only views for the screens
  List<Course> get courses => _courses;
  bool get loading => _loading;
  String? get error => _error;
  String get filter => _filter;

  // Computed getter for the filter
  List<Course> get visibleCourses {
    if (_filter == 'all') return _courses;
    return _courses.where((c) => c.day.toLowerCase() == _filter.toLowerCase()).toList();
  }

  // Actions
  Future<void> add(Course course) => _repo.add(course);
  Future<void> edit(String id, Course course) => _repo.update(id, course);
  Future<void> remove(Course course) => _repo.delete(course.id);

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}