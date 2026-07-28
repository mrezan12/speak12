import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_sign_in_config.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize(
      serverClientId: googleSignInServerClientId,
    );
    _initialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    await ensureInitialized();

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw StateError('Google Sign-In did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await ensureInitialized();
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
