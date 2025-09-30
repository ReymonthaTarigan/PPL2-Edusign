import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<User?> signUp({
    required String email,
    required String password,
  }) async {
    UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = result.user;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }

    return user;
  }

  Future<void> saveUserData({
    required String uid,
    required String name,
    required String jenjang,
    required String email,
  }) async {
    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "uid": uid,
      "name": name,
      "jenjang": jenjang,
      "email": email,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
