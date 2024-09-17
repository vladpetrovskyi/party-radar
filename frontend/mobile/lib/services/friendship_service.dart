import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';
import 'package:party_radar/flavors/flavor_config.dart';
import 'package:party_radar/models/friendship.dart';
import 'package:party_radar/util/extensions.dart';

class FriendshipService {
  static Future<List<Friendship>> getFriendships(
      FriendshipStatus friendshipStatus, int offset, int limit) async {
    Response response = await get(
        Uri.parse(
            '${FlavorConfig.instance.values.apiV1}/friendship?status=${friendshipStatus.name}&offset=$offset&limit=$limit'),
        headers: {
          HttpHeaders.authorizationHeader:
              'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
        });
    return response.ok
        ? List<Friendship>.from(jsonDecode(response.body)
            .map((element) => Friendship.fromJson(element)))
        : [];
  }

  static Future<Friendship?> getFriendshipByUsername(String username) async {
    Response response = await get(
        Uri.parse(
            '${FlavorConfig.instance.values.apiV1}/friendship?username=$username'),
        headers: {
          HttpHeaders.authorizationHeader:
              'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
        });

    if (response.statusCode == 204) return null;

    return response.ok
        ? Friendship.fromJson(jsonDecode(response.body))
        : null;
  }

  static Future<int?> getFriendshipsCount(
      FriendshipStatus friendshipStatus) async {
    Response response = await get(
        Uri.parse(
            '${FlavorConfig.instance.values.apiV1}/friendship/count?status=${friendshipStatus.name}&userUID=${FirebaseAuth.instance.currentUser?.uid}'),
        headers: {
          HttpHeaders.authorizationHeader:
              'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
        });
    return response.ok ? jsonDecode(response.body)['count'] : null;
  }

  static Future<bool> createFriendshipRequest(String username) async {
    Response response = await post(
        Uri.parse('${FlavorConfig.instance.values.apiV1}/friendship'),
        headers: {
          HttpHeaders.authorizationHeader:
              'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}',
          HttpHeaders.contentTypeHeader: 'application/json'
        },
        body: jsonEncode({'username': username}));
    return response.ok;
  }

  static Future<bool> updateFriendship(
      int friendshipId, FriendshipStatus friendshipStatus) async {
    Response response = await put(
        Uri.parse(
            '${FlavorConfig.instance.values.apiV1}/friendship/$friendshipId'),
        headers: {
          HttpHeaders.authorizationHeader:
              'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}',
          HttpHeaders.contentTypeHeader: 'application/json'
        },
        body: jsonEncode({'status': friendshipStatus.name}));
    return response.ok;
  }

  static Future<bool> deleteFriendship(int friendshipId) async {
    Response response = await delete(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV1}/friendship/$friendshipId'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );
    return response.ok;
  }
}
