import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/screens/feed_screen.dart';
import 'package:party_radar/flavors/flavor_banner.dart';
import 'package:party_radar/screens/location/location_screen.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/screens/user_profile/user_profile_screen.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentPageIndex = 1;
  int _initialTabIndex = 0;

  @override
  void initState() {
    setupInteractedMessage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FlavorBanner(
      child: Scaffold(
        body: [
          Consumer<LocationProvider>(
            builder: (BuildContext context, LocationProvider provider,
                Widget? child) {
              return provider.rootLocation != null
                  ? FeedScreen(locationId: provider.rootLocation!.id!)
                  : Container();
            },
          ),
          const LocationScreen(),
          UserProfileScreen(
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
            Consumer<LocationProvider>(
              builder: (_, provider, __) {
                return NavigationDestination(
                  icon: const Icon(Icons.history),
                  label: 'Feed',
                  enabled: provider.rootLocation != null,
                );
              },
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
      var rootLocation =
          Provider.of<LocationProvider>(context, listen: false).rootLocation;
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