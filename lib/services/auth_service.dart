
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get user => _auth.authStateChanges();

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "Sign-in cancelled by user.";

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
        final snapshot = await userRef.get();
        if (!snapshot.exists) {
          await DatabaseService(uid: user.uid).createNewUser(
            user.displayName ?? 'Google User',
            user.email ?? '',
          );
        }
      }
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException in signInWithGoogle: ${e.code}");
      return e.message ?? "An error occurred during Google sign-in.";
    } catch (e) {
      debugPrint("An unexpected error occurred in signInWithGoogle: $e");
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException in signInWithEmailAndPassword: ${e.code}");
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Invalid email or password. Please try again.';
      }
      return e.message ?? "An error occurred during sign-in.";
    } catch (e) {
      debugPrint("An unexpected error occurred in signInWithEmailAndPassword: $e");
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<String?> registerWithEmailAndPassword(String name, String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user != null) {
        await DatabaseService(uid: user.uid).createNewUser(name, email);
      }
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException in registerWithEmailAndPassword: ${e.code}");
      if (e.code == 'email-already-in-use') {
        return 'This email address is already in use by another account.';
      }
      return e.message ?? "An error occurred during registration.";
    } catch (e) {
      debugPrint("An unexpected error occurred in registerWithEmailAndPassword: $e");
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }
}
