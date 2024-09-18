import 'package:firebase_auth/firebase_auth.dart' as firebase_auth_pkg;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/providers/user_provider.dart';
import 'package:party_radar/screens/login_screen.dart';
import 'package:party_radar/screens/main_screen.dart';
import 'package:provider/provider.dart';

class PartyRadarApp extends StatefulWidget {
  const PartyRadarApp({super.key});

  @override
  State<PartyRadarApp> createState() => _PartyRadarAppState();
}

class _PartyRadarAppState extends State<PartyRadarApp> {
  @override
  Widget build(BuildContext context) {
    firebase_auth_pkg.FirebaseAuth.instance
        .authStateChanges()
        .listen((firebase_auth_pkg.User? user) {
      if (user == null) _rebuildWidget();
    });

    firebase_auth_pkg.User? getUserData() =>
        firebase_auth_pkg.FirebaseAuth.instance.currentUser;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'Party Radar',
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          dividerColor: Colors.black12,
          colorSchemeSeed: Colors.cyanAccent,
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: GoogleFonts.openSansTextTheme()
              .apply(displayColor: Colors.white, bodyColor: Colors.white),
        ),
        themeMode: ThemeMode.dark,
        home: getUserData() != null ? const MainScreen() : const LoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  void _rebuildWidget() => setState(() {});
}
