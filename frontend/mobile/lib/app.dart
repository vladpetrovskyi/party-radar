import 'package:firebase_auth/firebase_auth.dart' as firebase_auth_pkg;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:party_radar/common/flavors/flavor_banner.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/services/location_service.dart';
import 'package:party_radar/common/services/user_service.dart';
import 'package:party_radar/feed/feed_page.dart';
import 'package:party_radar/location/location_page.dart';
import 'package:party_radar/login/login_widget.dart';
import 'package:party_radar/profile/user_profile_page.dart';

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
      home: getUserData() != null ? const MainPage() : const LoginPage(),
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
  int _currentPageIndex = 1;
  int _initialTabIndex = 0;

  Location? rootLocation;

  @override
  void initState() {
    initClub(null);

    setupInteractedMessage();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FlavorBanner(
      child: Scaffold(
        body: [
          if (rootLocation != null)
            FeedPage(locationId: rootLocation!.id)
          else
            Container(),
          LocationPage(
            rootLocation: rootLocation,
            onQuitRootLocation: () => setState(() {
              _currentPageIndex = 1;
              rootLocation = null;
            }),
            onChangeLocation: (locationId) => initClub(locationId),
          ),
          UserProfilePage(
            initialTabIndex: _initialTabIndex,
            onTabChanged: (index) => _initialTabIndex = index,
          ),
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
            NavigationDestination(
              icon: const Icon(Icons.history),
              label: 'Feed',
              enabled: rootLocation != null,
            ),
            const NavigationDestination(
              icon: Icon(Icons.share_location_outlined),
              label: 'Location',
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

  void initClub(int? locationId) async {
    int? userRootLocationId;
    if (locationId != null ||
        (userRootLocationId = (await UserService.getUser())?.rootLocationId) !=
            null) {
      var userLocation =
      await LocationService.getLocation(locationId ?? userRootLocationId);
      setState(() {
        rootLocation = userLocation;
      });
    } else {
      setState(() {
        rootLocation = null;
      });
    }
  }

  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage? message) {
    if (message != null) {
      if (message.data['view'] == 'friendship-requests') {
        setState(() {
          _currentPageIndex = 2;
          _initialTabIndex = 2;
        });
      } else if (message.data['view'] == 'posts' && rootLocation != null) {
        setState(() {
          _currentPageIndex = 0;
        });
      } else if (message.data['view'] == 'post-tag' && rootLocation != null) {
        setState(() {
          _currentPageIndex = 0;
          // TODO open dialog window with exact location
        });
      } else if (message.data['view'] == 'location') {
        setState(() {
          _currentPageIndex = 1;
        });
      }
    }
  }
}
