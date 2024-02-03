import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';

class AuthService {
  static Future<String?> login(String login, String password) async {
    try {
      UserCredential userCredentials = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: login, password: password);

      if (userCredentials.user?.emailVerified != null &&
          !userCredentials.user!.emailVerified) {
        return 'Please verify your email address';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Wrong email or password';
      } else if (e.code == 'wrong-password') {
        return 'Wrong email or password';
      }
      return 'Credentials provided are invalid';
    }
    return null;
  }

  static Future<String?> register(String email, String password) async {
    try {
      UserCredential user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      user.user?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        return 'The account already exists for that email';
      } else {
        return 'Could not register new account';
      }
    } catch (e) {
      return 'Could not register new account';
    }

    final Map<String, dynamic> registrationData = {
      'email': email,
      'uid': FirebaseAuth.instance.currentUser?.uid,
    };

    Response response = await post(
        Uri.parse('http://localhost:8080/api/v1/user/registration'),
        body: json.encode(registrationData),
        headers: {'Content-Type': 'application/json'});

    if (response.statusCode != 200) {
      FirebaseAuth.instance.currentUser?.delete();
      return json.decode(response.body)['msg'];
    }

    FirebaseAuth.instance.signOut();
    return null;
  }

  static Future<String?> recoverPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'auth/invalid-email') {
        return 'Invalid email address';
      } else if (e.code == 'auth/user-not-found') {
        return 'Email is not registered';
      }
      return 'Password recovery failed';
    }
    return null;
  }
}
