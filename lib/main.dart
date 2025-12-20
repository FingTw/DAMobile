
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled3/firebase_options.dart';
import 'package:untitled3/screens/wrapper.dart';
import 'package:untitled3/services/notification_service.dart';
import 'package:untitled3/screens/error_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // We don't await here anymore. The FutureBuilder will handle it.
  runApp(MyApp()); // FIX: Removed const
}

class MyApp extends StatelessWidget {
  MyApp({super.key}); // FIX: Removed const

  // Create the initialization Future outside of build to avoid re-initialization on rebuilds
  final Future<FirebaseApp> _initialization = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          // --- Check for errors ---
          if (snapshot.hasError) {
            return ErrorScreen(errorMessage: snapshot.error.toString());
          }

          // --- Once complete, show your application ---
          if (snapshot.connectionState == ConnectionState.done) {
            // Initialize OneSignal AFTER Firebase is confirmed to be working
            NotificationService.initOneSignal();
            return const Wrapper();
          }

          // --- Otherwise, show something whilst waiting for initialization to complete ---
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
