import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get user => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // Send OTP to email after successful registration
      // Note: Firebase doesn't have a built-in 'OTP to email' service for new users.
      // We would typically use a Cloud Function or a third-party service like SendGrid
      // to send an email with a verification code.
      // For this plan, we'll simulate this with a simple email verification link.
      await userCredential.user?.sendEmailVerification();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign Up Error: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('Unknown Sign Up Error: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign In Error: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('Unknown Sign In Error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Simulate OTP verification (for Email/Password, this would be a manual link click)
  // This is a placeholder function to mimic OTP flow
  Future<bool> verifyOtp(String otp) async {
    // In a real app, this would check the OTP against a stored value
    // For now, let's assume a hardcoded OTP for demonstration
    return otp == '123456';
  }
}