import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/util/extensions.dart';

class PostService {
  static Future<List<Post>> getFeed(
      int offset, int limit, String username) async {
    Response response = await get(
      Uri.parse(
          'http://${ServerAddressExtension.serverAddress}:8080/api/v1/post/feed?offset=$offset&limit=$limit&username=$username'),
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

  static Future<List<Post>> getUserPosts(int offset, int limit, int? userId) async {
    Response response = await get(
      Uri.parse(
          'http://${ServerAddressExtension.serverAddress}:8080/api/v1/post?offset=$offset&limit=$limit&userId=$userId'),
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
          'http://${ServerAddressExtension.serverAddress}:8080/api/v1/post/count?username=$username'),
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

  static Future<bool> createPost(int? locationId, PostType postType) async {
    Response response = await post(
      Uri.parse(
          'http://${ServerAddressExtension.serverAddress}:8080/api/v1/post'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
      body: jsonEncode({'location_id': locationId, 'post_type': postType.name}),
    );

    return response.ok;
  }
}
