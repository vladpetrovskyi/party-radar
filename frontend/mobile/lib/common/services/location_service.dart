import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/util/extensions.dart';

class LocationService {
  static Future<List<Location>?> getLocations(ElementType elementType) async {
    final response = await get(
      Uri.parse(
          'http://${ServerAddressExtension.serverAddress}:8080/api/v1/location?type=${elementType.name}'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );

    if (response.ok) {
      return List<Location>.from(
          jsonDecode(response.body).map((model) => Location.fromJson(model)));
    }
    throw Exception('Request failed: ${response.body}');
  }

  static Future<Location?> getLocation(int? locationId) async {
    if (locationId == null) return null;

    final response = await get(
      Uri.parse(
          'http://${ServerAddressExtension.serverAddress}:8080/api/v1/location/$locationId'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );

    if (response.ok) {
      return Location.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load location: ${response.body}');
    }
  }

  static Future<int?> getLocationUserCount(int id) async {
    final response = await get(
      Uri.parse(
          'http://${ServerAddressExtension.serverAddress}:8080/api/v1/location/$id/user/count'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );

    if (response.ok) {
      return jsonDecode(response.body)['count'];
    } else {
      throw Exception('Failed to get user count at location: ${response.body}');
    }
  }
}
