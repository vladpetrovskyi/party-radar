import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';
import 'package:party_radar/flavors/flavor_config.dart';
import 'package:party_radar/models/post.dart';
import 'package:party_radar/util/extensions.dart';

class PostService {
  static Future<List<Post>> getFeed(
      int offset, int limit, String username, int? rootLocationId) async {
    Response response = await get(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV1}/post/feed?offset=$offset&limit=$limit&username=$username&rootLocationId=${rootLocationId ?? ''}'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );

    if (response.ok) {
      return List<Post>.from(
          jsonDecode(response.body).map((model) => Post.fromJson(model)));
    }
    return [];
  }

  static Future<List<Post>> getUserPosts(
      int offset, int limit, int? userId) async {
    Response response = await get(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV1}/post?offset=$offset&limit=$limit&userId=$userId'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );

    if (response.ok) {
      return List<Post>.from(
          jsonDecode(response.body).map((model) => Post.fromJson(model)));
    }
    return [];
  }

  static Future<int?> getPostCount(String? username) async {
    Response response = await get(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV1}/post/count?username=${username ?? ''}'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );

    if (response.ok) {
      return jsonDecode(response.body)['count'];
    }
    return null;
  }

  static Future<bool> createPost(
      int? locationId, PostType postType, int? capacity) async {
    Response response = await post(
      Uri.parse('${FlavorConfig.instance.values.apiV1}/post'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}',
        HttpHeaders.contentTypeHeader: 'application/json'
      },
      body: jsonEncode({
        'location_id': locationId,
        'post_type': postType.name,
        'capacity': capacity
      }),
    );

    if (!response.ok) throw Exception("Could not post location: ${response.body}");

    return response.ok;
  }

  static Future<bool> increaseViewCountByOne(int? postId) async {
    Response response = await put(
        Uri.parse('${FlavorConfig.instance.values.apiV1}/post/$postId/view'),
        headers: {
          HttpHeaders.authorizationHeader:
          'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
        });

    if (!response.ok) throw Exception("Could not increase view count: \n${response.body}");

    return response.ok;
  }

  static Future<int> getPostViewsCount(int? postId) async {
    Response response = await get(
        Uri.parse('${FlavorConfig.instance.values.apiV1}/post/$postId/view'),
        headers: {
          HttpHeaders.authorizationHeader:
          'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
        });

    if (!response.ok) throw Exception("Could not get post views count: \n${response.body}");

    return jsonDecode(response.body)['count'];
  }

  static Future<bool> deletePost(int postId) async {
    Response response = await delete(
        Uri.parse('${FlavorConfig.instance.values.apiV1}/post/$postId'),
        headers: {
          HttpHeaders.authorizationHeader:
              'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
        });

    return response.ok;
  }
}
