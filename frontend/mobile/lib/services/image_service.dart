import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:party_radar/flavors/flavor_config.dart';
import 'package:party_radar/util/extensions.dart';

class ImageService {
  static Future<bool> update(int imageId, File imageFile) async {
    var request = http.MultipartRequest('PUT',
        Uri.parse('${FlavorConfig.instance.values.apiV1}/image/$imageId'));
    request.files.add(http.MultipartFile.fromBytes(
        'imageFile', imageFile.readAsBytesSync(),
        filename: imageFile.path));
    request.headers.addAll({
      HttpHeaders.authorizationHeader:
          'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
    });

    var response = await request.send();

    if (response.statusCode != 200) {
      return false;
    }

    imageCache.clearLiveImages();
    imageCache.clear();
    return true;
  }

  static Future<bool> addForUser(File imageFile, int? userId) async {
    var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '${FlavorConfig.instance.values.apiV1}/image?userId=$userId'));
    request.files.add(http.MultipartFile.fromBytes(
        'imageFile', imageFile.readAsBytesSync(),
        filename: imageFile.path));
    request.headers.addAll({
      HttpHeaders.authorizationHeader:
          'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
    });

    var response = await request.send();

    if (response.statusCode != 200) {
      return false;
    }

    imageCache.clearLiveImages();
    imageCache.clear();
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
    return true;
  }

  static Future<int?> addForDialogSettings(
      File imageFile, int? dialogSettingsId) async {
    var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '${FlavorConfig.instance.values.apiV1}/image?dialogSettingsId=$dialogSettingsId'));
    request.files.add(http.MultipartFile.fromBytes(
        'imageFile', imageFile.readAsBytesSync(),
        filename: imageFile.path));
    request.headers.addAll({
      HttpHeaders.authorizationHeader:
          'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
    });

    var response = await http.Response.fromStream(await request.send());

    if (!response.ok) {
      return null;
    }

    imageCache.clearLiveImages();
    imageCache.clear();
    return jsonDecode(response.body)['id'] as int?;
  }

  static Future<Image> get(int? id,
      {double? size, bool showErrorImage = true}) async {
    var token = await FirebaseAuth.instance.currentUser?.getIdToken();
    var imageUrl = '${FlavorConfig.instance.values.apiV1}/image/$id';
    var headers = {HttpHeaders.authorizationHeader: 'Bearer $token'};

    http.Response response =
        await http.head(Uri.parse(imageUrl), headers: headers);

    var resultImage = Image.asset('assets/user.png', width: size, height: size);

    if (response.ok) {
      resultImage = Image.network(
        key: UniqueKey(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        '${FlavorConfig.instance.values.apiV1}/image/$id',
        headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        errorBuilder: (context, exception, stackTrace) {
          return showErrorImage
              ? Image.asset('assets/user.png', width: size, height: size)
              : const Icon(Icons.error);
        },
      );
    }

    return resultImage;
  }

  static Future<bool> delete(int imageId) async {
    var response = await http.delete(
        Uri.parse('${FlavorConfig.instance.values.apiV1}/image/$imageId'),
        headers: {
          HttpHeaders.authorizationHeader:
              'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
        });

    return response.ok;
  }
}
