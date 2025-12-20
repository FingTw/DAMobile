
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled3/screens/home_screen.dart';
import 'package:untitled3/screens/login_screen.dart';
import 'package:untitled3/services/auth_service.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          // User is logged in
          return const HomeScreen();
        } else {
          // User is not logged in
          return const LoginScreen();
        }
      },
    );
  }
}
