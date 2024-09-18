import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:party_radar/flavors/flavor_config.dart';
import 'package:party_radar/models/dialog_settings.dart';
import 'package:party_radar/util/extensions.dart';

class DialogSettingsService {
  Future<int?> create(DialogSettings dialogSettings) async {
    final response = await http.post(
      Uri.parse('${FlavorConfig.instance.values.apiV1}/dialog-settings'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}',
        HttpHeaders.contentTypeHeader: 'application/json'
      },
      body: jsonEncode(dialogSettings.toJson()),
    );

    if (response.ok) {
      return (jsonDecode(response.body) as Map<String, dynamic>)['id'] as int;
    }

    return null;
  }

  Future<bool> update(DialogSettings dialogSettings) async {
    final response = await http.put(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV1}/dialog-settings/${dialogSettings.id}'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}',
        HttpHeaders.contentTypeHeader: 'application/json'
      },
      body: jsonEncode(dialogSettings.toJson()),
    );

    return response.ok;
  }

  Future<bool> delete(int dialogSettingsId) async {
    final response = await http.delete(
      Uri.parse(
          '${FlavorConfig.instance.values.apiV1}/dialog-settings/$dialogSettingsId'),
      headers: {
        HttpHeaders.authorizationHeader:
            'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}',
      },
    );

    return response.ok;
  }
}
