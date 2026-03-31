import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:http/http.dart' as http;

/// Firebase Auth + Google Sign-In service for the mobile app.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Stream of auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current user provider.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  User? get currentUser => _auth.currentUser;

  /// Sign in with Google. Returns the credential and stores the auth client.
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  /// Get an authenticated HTTP client for Google APIs (Drive).
  /// Returns null if not signed in.
  Future<http.Client?> getAuthenticatedClient() async {
    final googleUser = await _googleSignIn.signInSilently();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    if (accessToken == null) return null;

    final credentials = gapis.AccessCredentials(
      gapis.AccessToken(
        'Bearer',
        accessToken,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
      ['https://www.googleapis.com/auth/drive.file'],
    );

    return gapis.authenticatedClient(http.Client(), credentials);
  }

  /// Sign out.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
