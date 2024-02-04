import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';
import 'package:party_radar/common/flavors/flavor_config.dart';
import 'package:party_radar/common/models.dart' as models;
import 'package:party_radar/common/util/extensions.dart';

class UserService {
  static Future<bool> userExists(String username) async {
    Response response = await head(
      Uri.parse('${FlavorConfig.instance.values.baseUrl}/user/$username'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );
    return response.ok;
  }

  static Future<models.User?> getUser({String? username}) async {
    username = username ?? FirebaseAuth.instance.currentUser?.displayName;
    Response response;
    if (username != null && username.isNotEmpty) {
      response = await get(
        Uri.parse('${FlavorConfig.instance.values.baseUrl}/user/$username'),
        headers: {
          HttpHeaders.authorizationHeader:
              'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
        },
      );
    } else {
      response = await get(
        Uri.parse(
            '${FlavorConfig.instance.values.baseUrl}/user?userUID=${FirebaseAuth.instance.currentUser?.uid}'),
        headers: {
          HttpHeaders.authorizationHeader:
              'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
        },
      );
    }

    return response.ok
        ? models.User.fromJson(jsonDecode(response.body))
        : throw Exception("Couldn't get user: ${response.body}");
  }

  static Future<bool> updateUsername(String username) async {
    var body = jsonEncode({
      'username': username,
    });

    Response response = await put(
      Uri.parse('${FlavorConfig.instance.values.baseUrl}/user/username'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
      body: body,
    );
    if (!response.ok) {
      return false;
    }

    try {
      if (FirebaseAuth.instance.currentUser?.displayName != username) {
        FirebaseAuth.instance.currentUser?.updateDisplayName(username);
      }
    } on FirebaseAuthException catch (_) {
      return false;
    }

    FirebaseAuth.instance.currentUser?.reload();
    return true;
  }

  static Future<bool> updateEmail(String? email) async {
    try {
      if (FirebaseAuth.instance.currentUser?.email != email && email != null) {
        FirebaseAuth.instance.currentUser?.verifyBeforeUpdateEmail(email);
      }
    } on FirebaseAuthException catch (_) {
      return false;
    }

    FirebaseAuth.instance.currentUser?.reload();
    return true;
  }

  static Future<bool> updateUserRootLocation(int locationId) async {
    Response response = await put(
      Uri.parse(
          '${FlavorConfig.instance.values.baseUrl}/user/root-location/$locationId'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );
    return response.ok;
  }

  static Future<bool> deleteUserLocation() async {
    Response response = await delete(
      Uri.parse('${FlavorConfig.instance.values.baseUrl}/user/location'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );
    return response.ok;
  }

  static Future<bool> deleteUser() async {
    Response response = await delete(
      Uri.parse('${FlavorConfig.instance.values.baseUrl}/user'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );
    if (!response.ok) {
      return false;
    }

    try {
      FirebaseAuth.instance.currentUser?.delete();
    } on FirebaseAuthException catch (_) {
      return false;
    }

    return true;
  }
}
