import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/app.dart';
import 'package:party_radar/common/flavors/flavor_config.dart';
import 'package:freerasp/freerasp.dart';
import 'package:party_radar/firebase_options_prod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // create configuration for freeRASP
  final config = TalsecConfig(
    /// For Android
    androidConfig: AndroidConfig(
      packageName: 'app.party_radar',
      signingCertHashes: ['FMfznBvrCEaXQcpvXBLBFBshHvn6h0CiD6FhCQp/xrY='],
    ),

    /// For iOS
    iosConfig: IOSConfig(
      bundleIds: ['app.party-radar'],
      teamId: 'C9V8FS7238',
    ),
    watcherMail: 'v.petrovskyi98@gmail.com',
    isProd: true,
  );

  await Talsec.instance.start(config);

  try {
    await Firebase.initializeApp(options: ProdFirebaseOptions.currentPlatform);
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  } catch (e) {
    print("Failed to initialise Firebase: $e");
  }

  FlavorConfig(
    flavor: Flavor.prod,
    values: FlavorValues(
      baseUrl: "https://party-radar.app/api/v1",
    ),
  );

  runApp(const PartyRadarApp());
}
