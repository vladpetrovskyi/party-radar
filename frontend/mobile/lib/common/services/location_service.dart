import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';
import 'package:party_radar/common/flavors/flavor_config.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/util/extensions.dart';

class LocationService {
  static Future<List<Location>?> getLocations(ElementType elementType) async {
    final response = await get(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV1}/location?type=${elementType.name}'),
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
      Uri.parse('${FlavorConfig.instance.values.apiV1}/location/$locationId'),
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
          '${FlavorConfig.instance.values.apiV1}/location/$id/user/count'),
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

  static Future<LocationAvailability> getLocationAvailability(int id) async {
    final response = await get(
      Uri.parse('${FlavorConfig.instance.values.apiV1}/location/$id/availability'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );

    if (response.statusCode == 404) {
      return LocationAvailability(isCloseable: false);
    } else if (response.ok) {
      String? closedAtString = jsonDecode(response.body)['closed_at'];
      return LocationAvailability(
        isCloseable: true,
        closedAt:
            closedAtString != null ? DateTime.parse(closedAtString) : null,
      );
    }

    throw Exception('Failed to get location closing: ${response.body}');
  }

  static Future<void> updateLocationAvailability(
      int id, DateTime? closingTime) async {
    final response = await patch(
      Uri.parse('${FlavorConfig.instance.values.apiV1}/location/$id/availability'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}',
        HttpHeaders.contentTypeHeader: 'application/json'
      },
      body: jsonEncode({
        'closed_at': closingTime?.toUtc().toString(),
      }),
    );

    if (!response.ok) {
      throw Exception('Failed to get user count at location: ${response.body}');
    }
  }
}
