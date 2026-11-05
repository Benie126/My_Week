import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/course_repository.dart';
import '../state/course_state.dart';
import 'login_screen.dart';
import 'my_week_screen.dart'; // We will create this next

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
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }
        // Signed in: create the Brain and give it to the screen
        return ChangeNotifierProvider<CourseState>(
          create: (_) => CourseState(CourseRepository(user.uid)),
          child: const MyWeekScreen(),
        );
      },
    );
  }
}