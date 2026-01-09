
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled3/firebase_options.dart';
import 'package:untitled3/screens/wrapper.dart';
import 'package:untitled3/services/notification_service.dart';
import 'package:untitled3/screens/error_screen.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Ensure Flutter is ready.
  WidgetsFlutterBinding.ensureInitialized();
  // Run the app.
  runApp(const MyApp());
}

// 1. Converted to a StatefulWidget
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 2. Created a Future to hold the initialization state.
  // This prevents re-initialization on rebuilds.
  late final Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    // 3. Moved initialization logic into initState to run it only once.
    _initializationFuture = _initializeServices();
  }

  // This method now encapsulates all async initialization.
  Future<void> _initializeServices() async {
    // Initialize Firebase first.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Once Firebase is ready, initialize the notification service.
    await NotificationService.initOneSignal();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      navigatorKey: navigatorKey,
      title: 'Srum team work',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // 4. The FutureBuilder now waits for our initialization Future to complete.
      home: FutureBuilder(
        future: _initializationFuture,
        builder: (context, snapshot) {
          // --- Check for errors during initialization ---
          if (snapshot.hasError) {
            return ErrorScreen(errorMessage: snapshot.error.toString());
          }

          // --- Once complete, show your application ---
          if (snapshot.connectionState == ConnectionState.done) {
            return const Wrapper();
          }

          // --- Otherwise, show a loading screen ---
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
