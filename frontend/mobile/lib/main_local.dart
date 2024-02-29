import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/app.dart';
import 'package:party_radar/common/flavors/flavor_config.dart';
import 'package:party_radar/firebase_options_dev.dart';

import 'common/services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DevFirebaseOptions.currentPlatform);
  await _initFCM();

  FlavorConfig(
    flavor: Flavor.local,
    color: Colors.deepPurpleAccent,
    values: FlavorValues(
      baseUrl: "http://${Platform.isAndroid ? '10.0.2.2' : 'localhost'}:8080/api/v1",
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
