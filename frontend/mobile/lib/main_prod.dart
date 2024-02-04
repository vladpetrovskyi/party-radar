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
    flavor: Flavor.prod,
    values: FlavorValues(
      baseUrl: "https://party-radar.app/api/v1",
    ),
  );

  runApp(const PartyRadarApp());
}
