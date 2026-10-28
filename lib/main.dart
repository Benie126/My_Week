import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'weather_api.dart';

void main() {
  runApp(const MyWeekApp());
}

class MyWeekApp extends StatelessWidget {
  const MyWeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Week',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const MyWeekScreen(),
    );
  }
}

class Course {
  String name;
  String day;
  String time;

  Course({required this.name, required this.day, required this.time});

  Map<String, dynamic> toJson() {
    return {'name': name, 'day': day, 'time': time};
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      name: json['name'] as String,
      day: json['day'] as String,
      time: json['time'] as String,
    );
  }
}

class MyWeekScreen extends StatefulWidget {
  const MyWeekScreen({super.key});

  @override
  State<MyWeekScreen> createState() => _MyWeekScreenState();
}

class _MyWeekScreenState extends State<MyWeekScreen> {
  List<Course> courses = [];
  late SharedPreferences prefs;
  bool isLoadingData = true;

  WeatherData? apiWeather;
  bool apiLoading = true;
  String? apiError;

  @override
  void initState() {
    super.initState();
    initApp();
  }

  Future<void> initApp() async {
    // This forces Chrome to use its permanent LocalStorage
    SharedPreferences.setPrefix('my_week_app_');
    prefs = await SharedPreferences.getInstance();

    await loadCourses();
    await loadWeather();
  }

  Future<void> loadCourses() async {
    final saved = prefs.getString('my_courses');
    debugPrint('LOADING: $saved');

    if (saved != null) {
      final list = jsonDecode(saved) as List;
      setState(() {
        courses = list.map((x) => Course.fromJson(x as Map<String, dynamic>)).toList();
        isLoadingData = false;
      });
    } else {
      setState(() {
        courses = [
          Course(name: 'Mobile Programming', day: 'Monday', time: '10:00 AM'),
          Course(name: 'Database Systems', day: 'Wednesday', time: '2:00 PM'),
        ];
        isLoadingData = false;
      });
      await saveCourses();
    }
  }

  Future<void> saveCourses() async {
    final list = courses.map((c) => c.toJson()).toList();
    final jsonString = jsonEncode(list);

    await prefs.setString('my_courses', jsonString);
    debugPrint('SAVED: $jsonString');
  }

  Future<void> loadWeather() async {
    setState(() {
      apiLoading = true;
      apiError = null;
    });
    try {
      final w = await fetchKigaliWeather();
      setState(() {
        apiWeather = w;
        apiLoading = false;
      });
    } catch (e) {
      setState(() {
        apiError = 'Could not load weather.';
        apiLoading = false;
      });
    }
  }

  void deleteCourse(int index) {
    setState(() {
      courses.removeAt(index);
    });
    saveCourses();
  }

  void showAddCourseDialog() {
    final nameController = TextEditingController();
    final dayController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Course'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Course Name')),
              TextField(controller: dayController, decoration: const InputDecoration(labelText: 'Day (e.g. Monday)')),
              TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Time (e.g. 10:00 AM)')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    courses.add(Course(
                      name: nameController.text,
                      day: dayController.text,
                      time: timeController.text,
                    ));
                  });
                  saveCourses();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget buildWeatherBanner() {
    if (apiLoading) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (apiError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: Colors.red.shade50,
        child: Text(apiError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.blue.shade50,
      child: Text(
        'Today in Kigali: ${apiWeather!.temp.round()}°C',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Week')),
      body: isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          buildWeatherBanner(),
          Expanded(
            child: courses.isEmpty
                ? const Center(child: Text('No courses yet. Add one!'))
                : ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.book),
                    title: Text(course.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${course.day} at ${course.time}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteCourse(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddCourseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}