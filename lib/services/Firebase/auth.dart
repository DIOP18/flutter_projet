import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Auth{
  final FirebaseAuth _firebaseAuth=FirebaseAuth.instance;
  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  Future<void> LoginWithEmailAndPassword(String email, String password) async{
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }
  Future<void>logout() async{
    await _firebaseAuth.signOut();
  }
  Future<void> createUserWithEmailAndPassword(String email, String password) async{
    await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);

  }
}