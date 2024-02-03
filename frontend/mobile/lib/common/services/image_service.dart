import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:party_radar/common/util/extensions.dart';

class ImageService {
  static Future<bool> updateImage(int imageId, File imageFile) async {
    var request = MultipartRequest(
        'PUT',
        Uri.parse(
            'http://${ServerAddressExtension.serverAddress}:8080/api/v1/image/$imageId'));
    request.files.add(MultipartFile.fromBytes(
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

  static Future<bool> addImage(File imageFile, int? userId) async {
    var request = MultipartRequest(
        'POST',
        Uri.parse(
            'http://${ServerAddressExtension.serverAddress}:8080/api/v1/image?userId=$userId'));
    request.files.add(MultipartFile.fromBytes(
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

  static Future<Image?> getImage(int? id, {double? size}) async {
    var token = await FirebaseAuth.instance.currentUser?.getIdToken();

    return Image.network(
      width: size,
      height: size,
      fit: BoxFit.cover,
      'http://${ServerAddressExtension.serverAddress}:8080/api/v1/image/$id',
      headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
      errorBuilder: (context, exception, stackTrace) {
        return Icon(Icons.question_mark, size: size ?? 128, color: Colors.grey);
      },
    );
  }
}
