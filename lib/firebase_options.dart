import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyDcGh7XGSbVedkTJjKo91qW8_m8ieUB0R8", // Your actual API key
      authDomain: "my-week-app-c5ed4.firebaseapp.com",
      projectId: "my-week-app-c5ed4",
      storageBucket: "my-week-app-c5ed4.firebasestorage.app",
      messagingSenderId: "930805155269",
      appId:  "1:930805155269:web:b694c85a27c0726615f7ac",
    );
  }
}