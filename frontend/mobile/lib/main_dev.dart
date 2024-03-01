import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:freerasp/freerasp.dart';
import 'package:party_radar/app.dart';
import 'package:party_radar/common/flavors/flavor_config.dart';
import 'package:party_radar/common/services/user_service.dart';
import 'package:party_radar/firebase_options_dev.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = TalsecConfig(
    androidConfig: AndroidConfig(
      packageName: 'app.party_radar.dev',
      signingCertHashes: ['FMfznBvrCEaXQcpvXBLBFBshHvn6h0CiD6FhCQp/xrY='],
    ),
    iosConfig: IOSConfig(
      bundleIds: ['app.party-radar.dev'],
      teamId: 'C9V8FS7238',
    ),
    watcherMail: 'v.petrovskyi98@gmail.com',
    isProd: false,
  );

  await Talsec.instance.start(config);

  await Firebase.initializeApp(options: DevFirebaseOptions.currentPlatform);
  await _initFCM();

  FlavorConfig(
    flavor: Flavor.dev,
    color: Colors.green,
    values: FlavorValues(
      baseUrl: "https://dev.party-radar.app/api",
    ),
  );

  runApp(const PartyRadarApp());
}

Future<void> _initFCM() async {
  await FirebaseMessaging.instance.requestPermission(provisional: true);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.instance.getToken().then((token) {
    if (FirebaseAuth.instance.currentUser != null) {
      UserService.updateFCMToken(token);
    }
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    if (FirebaseAuth.instance.currentUser != null) {
      UserService.updateFCMToken(token);
    }
  });
}
