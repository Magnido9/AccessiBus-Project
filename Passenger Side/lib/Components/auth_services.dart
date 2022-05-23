library auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
String error_message="";


enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthRepository with ChangeNotifier {
  FirebaseAuth _auth;
  User? _user;
  Status _status = Status.Uninitialized;

  AuthRepository.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
    _onAuthStateChanged(_user);
  }

  Status get status => _status;

  User? get user => _user;

  bool get isAuthenticated => status == Status.Authenticated;

  Future<UserCredential?> signUp(String email, String password,BuildContext context) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
      print(e);
      error_message=e.toString();
      _status = Status.Unauthenticated;
      notifyListeners();
      throw(e);
    }
  }

  Future<UserCredential?> signIn(String email, String password,BuildContext context) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {


      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
      print(e);
      error_message=e.toString();
      _status = Status.Unauthenticated;
      notifyListeners();
      return null;
    }
  }

  Future signOut() async {
    _auth.signOut();
    _status = Status.Unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }
}

