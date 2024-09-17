import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';
import 'package:party_radar/flavors/flavor_config.dart';
import 'package:party_radar/models/user.dart' as models;
import 'package:party_radar/util/extensions.dart';

class UserService {
  static Future<models.User?> getCurrentUser() async {
    if (FirebaseAuth.instance.currentUser == null) return null;

    var response = await get(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV2}/user?userUID=${FirebaseAuth.instance.currentUser?.uid}'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );

    return response.ok
        ? models.User.fromJson(jsonDecode(response.body))
        : throw Exception("Couldn't get user: ${response.body}");
  }

  static Future<List<models.User>> getUsers(String username, int offset, int limit) async {
    if (FirebaseAuth.instance.currentUser == null) return List.empty();

    var response = await get(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV2}/user?username=$username&offset=$offset&limit=$limit'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );
    return response.ok
        ? List<models.User>.from(jsonDecode(response.body)
            .map((model) => models.User.fromJson(model))
            .toList())
        : throw Exception("Couldn't decode users: ${response.body}");
  }

  static Future<bool> updateUsername(String username) async {
    var body = jsonEncode({
      'username': username,
    });

    Response response = await put(
      Uri.parse('${FlavorConfig.instance.values.apiV1}/user/username'),
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

  static Future<bool> updateFCMToken(String? token) async {
    Response response = await patch(
      Uri.parse('${FlavorConfig.instance.values.apiV1}/user/fcm-token'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}',
        HttpHeaders.contentTypeHeader: 'application/json'
      },
      body: jsonEncode({'fcm_token': token}),
    );
    return response.ok;
  }

  static Future<bool> updateUserRootLocation(int locationId) async {
    Response response = await put(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV1}/user/root-location/$locationId'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );
    return response.ok;
  }

  static Future<bool> deleteUserLocation() async {
    Response response = await delete(
      Uri.parse('${FlavorConfig.instance.values.apiV2}/user/location'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );
    return response.ok;
  }

  static Future<bool> deleteUser() async {
    Response response = await delete(
      Uri.parse('${FlavorConfig.instance.values.apiV1}/user'),
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

  static Future<List<String>> getUserTopics() async {
    Response response = await get(
      Uri.parse('${FlavorConfig.instance.values.apiV1}/user/topic'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}',
        HttpHeaders.contentTypeHeader: 'application/json'
      },
    );
    if (response.ok) {
      return List<String>.from(jsonDecode(response.body)['topics']);
    }
    return [];
  }

  static Future<bool> subscribeToTopic(String topicName) async {
    Response response = await post(
      Uri.parse('${FlavorConfig.instance.values.apiV1}/user/topic'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}',
        HttpHeaders.contentTypeHeader: 'application/json'
      },
      body: jsonEncode({'topic_name': topicName}),
    );
    return response.ok;
  }

  static Future<bool> unsubscribeFromTopic(String topicName) async {
    Response response = await delete(
      Uri.parse('${FlavorConfig.instance.values.apiV1}/user/topic'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}',
        HttpHeaders.contentTypeHeader: 'application/json'
      },
      body: jsonEncode({'topic_name': topicName}),
    );
    return response.ok;
  }
}
