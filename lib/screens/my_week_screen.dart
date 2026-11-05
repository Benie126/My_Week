import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../state/course_state.dart';
import '../models/course.dart';
import '../weather_api.dart';

class MyWeekScreen extends StatefulWidget {
  const MyWeekScreen({super.key});

  @override
  State<MyWeekScreen> createState() => _MyWeekScreenState();
}

class _MyWeekScreenState extends State<MyWeekScreen> {
  WeatherData? apiWeather;
  bool apiLoading = true;
  String? apiError;

  @override
  void initState() {
    super.initState();
    loadWeather();
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

  // We read the Brain BEFORE opening the dialog and pass it using .value
  void showCourseDialog({Course? courseToEdit}) {
    final state = context.read<CourseState>();
    showDialog(
      context: context,
      builder: (context) {
        return ChangeNotifierProvider<CourseState>.value(
          value: state,
          child: CourseDialog(courseToEdit: courseToEdit),
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
    // Watch the brain to rebuild when data changes
    final state = context.watch<CourseState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Week'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          buildWeatherBanner(),

          // FILTER CHIPS
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Wrap(
              spacing: 8,
              children: ['all', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'].map((f) => ChoiceChip(
                label: Text(f.toUpperCase()),
                selected: state.filter == f,
                onSelected: (_) => context.read<CourseState>().setFilter(f),
              )).toList(),
            ),
          ),

          // THE LIST
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                ? Center(child: Text(state.error!))
                : state.visibleCourses.isEmpty
                ? const Center(child: Text('No courses yet. Add one!'))
                : ListView.builder(
              itemCount: state.visibleCourses.length,
              itemBuilder: (context, index) {
                final course = state.visibleCourses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.book),
                    title: Text(course.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${course.day} at ${course.time}'),
                    onTap: () => showCourseDialog(courseToEdit: course),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => context.read<CourseState>().remove(course),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCourseDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- THE DIALOG ---
class CourseDialog extends StatefulWidget {
  final Course? courseToEdit;
  const CourseDialog({super.key, this.courseToEdit});

  @override
  State<CourseDialog> createState() => _CourseDialogState();
}

class _CourseDialogState extends State<CourseDialog> {
  late TextEditingController nameController;
  late TextEditingController dayController;
  late TextEditingController timeController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.courseToEdit?.name ?? '');
    dayController = TextEditingController(text: widget.courseToEdit?.day ?? '');
    timeController = TextEditingController(text: widget.courseToEdit?.time ?? '');
  }

  @override
  Widget build(BuildContext context) {
    // Watch the brain to show live total count
    final state = context.watch<CourseState>();

    return AlertDialog(
      title: Text(widget.courseToEdit == null ? 'Add Course' : 'Edit Course'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Total courses: ${state.courses.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 16),
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
          onPressed: () async {
            if (nameController.text.isNotEmpty) {
              final newCourse = Course(
                name: nameController.text,
                day: dayController.text,
                time: timeController.text,
              );

              if (widget.courseToEdit == null) {
                await state.add(newCourse);
              } else {
                await state.edit(widget.courseToEdit!.id, newCourse);
              }
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}