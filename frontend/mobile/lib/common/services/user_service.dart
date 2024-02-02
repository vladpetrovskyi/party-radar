import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';
import 'package:party_radar/common/models.dart' as models;
import 'package:party_radar/common/util/extensions.dart';

class UserService {
  static Future<bool> userExists(String username) async {
    Response response = await head(
      Uri.parse(
          'http://${ServerAddressExtension.serverAddress}:8080/api/v1/user/$username'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );
    return response.ok;
  }

  static Future<models.User?> getUser({String? username}) async {
    username = username ?? FirebaseAuth.instance.currentUser?.displayName;
    Response response = await get(
      Uri.parse(
          'http://${ServerAddressExtension.serverAddress}:8080/api/v1/user/$username'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );

    return response.ok
        ? models.User.fromJson(jsonDecode(response.body))
        : throw Exception("Couldn't get user: ${response.body}");
  }

  static Future<bool> updateUser({String? username, String? email}) async {
    var body = jsonEncode({
      'username': username ?? FirebaseAuth.instance.currentUser?.displayName,
      'email': email ?? FirebaseAuth.instance.currentUser?.email
    });

    Response response = await put(
      Uri.parse(
          'http://${ServerAddressExtension.serverAddress}:8080/api/v1/user'),
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
      if (FirebaseAuth.instance.currentUser?.displayName != username) FirebaseAuth.instance.currentUser?.updateDisplayName(username);
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
          'http://${ServerAddressExtension.serverAddress}:8080/api/v1/user/root-location/$locationId'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );
    return response.ok;
  }

  static Future<bool> deleteUserLocation() async {
    Response response = await delete(
      Uri.parse(
          'http://${ServerAddressExtension.serverAddress}:8080/api/v1/user/location'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );
    return response.ok;
  }
}
