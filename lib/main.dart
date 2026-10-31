import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'weather_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: const AuthGate(),
    );
  }
}

// --- THE GATE ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == null) {
          return const LoginScreen();
        }
        return const MyWeekScreen();
      },
    );
  }
}

// --- THE MODEL ---
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

CollectionReference<Map<String, dynamic>> myCourses() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance.collection('users').doc(uid).collection('courses');
}

// --- MAIN SCREEN ---
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

  // --- ADD / EDIT DIALOG ---
  // If courseToEdit is null, it adds a new course.
  // If courseToEdit is provided, it updates the existing one.
  void showCourseDialog({Course? courseToEdit}) {
    final nameController = TextEditingController(text: courseToEdit?.name ?? '');
    final dayController = TextEditingController(text: courseToEdit?.day ?? '');
    final timeController = TextEditingController(text: courseToEdit?.time ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(courseToEdit == null ? 'Add Course' : 'Edit Course'),
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
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  if (courseToEdit == null) {
                    // ADD NEW
                    await myCourses().add({
                      'name': nameController.text,
                      'day': dayController.text,
                      'time': timeController.text,
                    });
                  } else {
                    // EDIT EXISTING
                    await myCourses().doc(courseToEdit.id).update({
                      'name': nameController.text,
                      'day': dayController.text,
                      'time': timeController.text,
                    });
                  }
                  if (context.mounted) Navigator.pop(context);
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
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: myCourses().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final courses = snapshot.data!.docs.map(Course.fromDoc).toList();

                if (courses.isEmpty) {
                  return const Center(child: Text('No courses yet. Add one!'));
                }

                return ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.book),
                        title: Text(course.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${course.day} at ${course.time}'),
                        // EDIT: Opens the dialog with the course data
                        onTap: () => showCourseDialog(courseToEdit: course),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => myCourses().doc(course.id).delete(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCourseDialog(), // ADD: Opens empty dialog
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _submit({required bool newAccount}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      if (newAccount) {
        await auth.createUserWithEmailAndPassword(
            email: _email.text.trim(), password: _password.text);
      } else {
        await auth.signInWithEmailAndPassword(
            email: _email.text.trim(), password: _password.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _message(e.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Log in instead.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Wrong email or password.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Something went wrong ($code).';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('My Week',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  validator: (v) {
                    final email = (v ?? '').trim();
                    if (email.isEmpty) return 'Enter your email';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                      return 'Enter a valid email, like aline@gmail.com';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  validator: (v) =>
                  (v ?? '').length < 6 ? 'At least 6 characters' : null,
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : () => _submit(newAccount: false),
                  child: const Text('Log in'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : () => _submit(newAccount: true),
                  child: const Text('Create account'),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}