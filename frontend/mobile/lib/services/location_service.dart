import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';
import 'package:party_radar/flavors/flavor_config.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/util/extensions.dart';

class LocationService {
  static Future<Location?> createLocation(Location location) async {
    final response = await post(
      Uri.parse('${FlavorConfig.instance.values.apiV1}/location'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}',
        HttpHeaders.contentTypeHeader: 'application/json'
      },
      body: jsonEncode(location.toJson()),
    );

    if (response.ok) {
      return Location.fromJson(jsonDecode(response.body));
    }

    return null;
  }

  static Future<Location?> updateLocation(Location location) async {
    final response = await put(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV1}/location/${location.id}'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}',
        HttpHeaders.contentTypeHeader: 'application/json'
      },
      body: jsonEncode(location.toJson()),
    );

    if (response.ok) {
      return Location.fromJson(jsonDecode(response.body));
    }

    return null;
  }

  static Future<bool> deleteLocation(int? locationId) async {
    final response = await delete(
      Uri.parse('${FlavorConfig.instance.values.apiV1}/location/$locationId'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );

    return response.ok;
  }

  static Future<List<int>> getSelectedLocationIds() async {
    final response = await get(
      Uri.parse('${FlavorConfig.instance.values.apiV1}/location/selected-ids'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );

    if (response.statusCode == 204) {
      return List.empty();
    }

    if (response.ok) {
      return List<int>.from(
          jsonDecode(response.body).map((model) => model as int)).toList();
    }
    throw Exception('Request failed: ${response.body}');
  }

  static Future<List<Location>?> getLocations(ElementType elementType,
      {bool? checkEnabled}) async {
    final response = await get(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV1}/location?type=${elementType.name}${checkEnabled != null ? '&enabled=$checkEnabled' : ''}'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );

    if (response.ok) {
      return List<Location>.from(jsonDecode(response.body)
              .map((model) => Location.fromJson(model)))
          .toList();
    }
    throw Exception('Request failed: ${response.body}');
  }

  static Future<List<Location>?> getLocationChildren(int? locationId,
      {bool visibleOnly = false}) async {
    if (locationId == null) return null;

    final response = await get(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV1}/location/$locationId/children'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );

    if (response.ok) {
      return List<Location>.from(jsonDecode(response.body)
              .map((model) => Location.fromJson(model)))
          .where((element) => visibleOnly ? element.deletedAt == null : true)
          .toList();
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

  static Future<void> updateLocationAvailability(
      int id, DateTime? closingTime) async {
    final response = await patch(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV1}/location/$id/availability'),
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
