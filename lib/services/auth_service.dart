import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
    {bool saveCredentials = true}
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Only save credentials if explicitly requested (for auto-login)
      if (saveCredentials) {
        await _saveSession(email, password);
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
    {bool saveCredentials = true}
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Only save credentials if explicitly requested (for auto-login)
      if (saveCredentials) {
        await _saveSession(email, password);
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw 'Google sign in failed: $e';
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await _clearSession();
  }
  
  // Auto-login from saved session
  Future<bool> autoLogin() async {
    try {
      // Check if user is already signed in (Firebase persists sessions)
      if (_auth.currentUser != null) {
        return true;
      }
      
      // Try to sign in with saved credentials
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      final password = prefs.getString('user_password');
      
      if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
        // Use saveCredentials: false to avoid re-saving (already saved)
        await signInWithEmailAndPassword(email, password, saveCredentials: false);
        return true;
      }
      return false;
    } catch (e) {
      // If auto-login fails, clear invalid credentials
      await _clearSession();
      return false;
    }
  }
  
  // Save session locally
  Future<void> _saveSession(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setString('user_password', password);
    // Note: In production, never store passwords in plain text
    // This is for demo purposes only
  }
  
  // Get saved credentials
  Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('user_email'),
      'password': prefs.getString('user_password'),
    };
  }
  
  // Clear session
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('user_password');
  }
  
  // Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}

