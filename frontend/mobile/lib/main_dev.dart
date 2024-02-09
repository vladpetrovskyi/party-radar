import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:freerasp/freerasp.dart';
import 'package:party_radar/app.dart';
import 'package:party_radar/common/flavors/flavor_config.dart';
import 'package:party_radar/firebase_options_dev.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // create configuration for freeRASP
  final config = TalsecConfig(
    /// For Android
    androidConfig: AndroidConfig(
      packageName: 'app.party_radar.dev',
      signingCertHashes: ['FMfznBvrCEaXQcpvXBLBFBshHvn6h0CiD6FhCQp/xrY='],
    ),

    /// For iOS
    iosConfig: IOSConfig(
      bundleIds: ['app.party-radar.dev'],
      teamId: 'C9V8FS7238',
    ),
    watcherMail: 'v.petrovskyi98@gmail.com',
    isProd: false,
  );

  await Talsec.instance.start(config);

  await Firebase.initializeApp(options: DevFirebaseOptions.currentPlatform);

  FlavorConfig(
    flavor: Flavor.dev,
    color: Colors.green,
    values: FlavorValues(
      baseUrl: "https://dev.party-radar.app/api/v1",
    ),
  );

  runApp(const PartyRadarApp());
}
