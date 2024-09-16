import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:party_radar/flavors/flavor_config.dart';
import 'package:party_radar/util/extensions.dart';

class LocationClosingService {
  Future<bool> create(int locationId) async {
    final response = await http.post(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV1}/location/$locationId/location-closing'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );

    return response.ok;
  }

  Future<bool> delete(int locationId) async {
    final response = await http.delete(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV1}/location/$locationId/location-closing'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
      },
    );

    return response.ok;
  }
}
