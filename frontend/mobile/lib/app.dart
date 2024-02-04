import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth_pkg;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:party_radar/common/flavors/flavor_banner.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/services/location_service.dart';
import 'package:party_radar/common/services/user_service.dart';
import 'package:party_radar/home/feed/feed_page.dart';
import 'package:party_radar/home/location_selection_page.dart';
import 'package:party_radar/location/location_page.dart';
import 'package:party_radar/login/login_widget.dart';
import 'package:party_radar/profile/user_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PartyRadarApp extends StatefulWidget {
  const PartyRadarApp({super.key});

  @override
  State<PartyRadarApp> createState() => _PartyRadarAppState();
}

class _PartyRadarAppState extends State<PartyRadarApp> {
  @override
  Widget build(BuildContext context) {
    firebase_auth_pkg.User? getUserData() =>
        firebase_auth_pkg.FirebaseAuth.instance.currentUser;

    return MaterialApp(
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
      home: getUserData() != null ? const MainPage() : const LoginWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentPageIndex = 0;

  Location? club;

  @override
  void initState() {
    _initClub();
    super.initState();
  }

  void _initClub() async {
    setState(() {});
    var sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.containsKey('club')) {
      setState(() {
        club =
            Location.fromJson(jsonDecode(sharedPreferences.getString('club')!));
      });
    } else {
      var user = await UserService.getUser();
      if (user?.rootLocationId != null) {
        var userLocation =
            await LocationService.getLocation(user?.rootLocationId);
        setState(() {
          club = userLocation;
        });
        sharedPreferences.setString('club', jsonEncode(userLocation));
      } else {
        setState(() {
          club = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlavorBanner(
      child: Scaffold(
        body: [
          club == null
              ? LocationSelectionPage(
                  onChangeLocation: () => _initClub(),
                )
              : const FeedPage(),
          club != null
              ? LocationPage(
                  club: club!,
                  onQuitRootLocation: () => setState(() {
                        _currentPageIndex = 0;
                        club = null;
                      }))
              : Container(),
          const UserProfilePage(),
        ][_currentPageIndex],
        bottomNavigationBar: NavigationBar(
          height: 65,
          onDestinationSelected: (int index) {
            setState(() {
              _currentPageIndex = index;
            });
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: <Widget>[
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Feed',
            ),
            NavigationDestination(
              icon: const Icon(Icons.share_location_outlined),
              label: 'Location',
              enabled: club != null,
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            )
          ],
          selectedIndex: _currentPageIndex,
        ),
      ),
    );
  }
}
