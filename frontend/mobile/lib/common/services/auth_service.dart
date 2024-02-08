import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';
import 'package:party_radar/common/flavors/flavor_config.dart';

class AuthService {
  static Future<String?> login(String login, String password) async {
    try {
      UserCredential userCredentials = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: login, password: password);

      if (userCredentials.user?.emailVerified != null &&
          !userCredentials.user!.emailVerified &&
          FlavorConfig.instance.flavor == Flavor.prod) {
        FirebaseAuth.instance.signOut();
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
    UserCredential user;
    try {
      user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
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
        Uri.parse('${FlavorConfig.instance.values.baseUrl}/user/registration'),
        body: jsonEncode(registrationData),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'});

    if (response.statusCode != 200) {
      FirebaseAuth.instance.currentUser?.delete();
      return json.decode(response.body)['msg'];
    }

    user.user?.sendEmailVerification();
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
