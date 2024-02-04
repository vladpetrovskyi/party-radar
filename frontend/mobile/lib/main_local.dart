import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/app.dart';
import 'package:party_radar/common/flavors/flavor_config.dart';
import 'package:party_radar/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlavorConfig(
    flavor: Flavor.local,
    color: Colors.deepPurpleAccent,
    values: FlavorValues(
      baseUrl: "http://${Platform.isAndroid ? '10.0.2.2' : 'localhost'}:8080/api/v1",
    ),
  );

  runApp(const PartyRadarApp());
}
