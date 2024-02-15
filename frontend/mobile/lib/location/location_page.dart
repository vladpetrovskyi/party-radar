import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/services/location_service.dart';
import 'package:party_radar/location/location_widget.dart';
import 'package:party_radar/common/services/post_service.dart';
import 'package:party_radar/common/services/user_service.dart';
import 'package:party_radar/profile/tabs/widgets/not_found_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({
    super.key,
    this.rootLocation,
    required this.onQuitRootLocation,
    required this.onChangeLocation,
  });

  final Location? rootLocation;
  final Function()? onQuitRootLocation;
  final Function()? onChangeLocation;

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  Future<User?> futureUser = UserService.getUser();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: SizedBox(
          height: 40,
          child: Hero(
              tag: 'logo_hero', child: Image.asset('assets/logo_app_bar.png')),
        ),
        actions: widget.rootLocation != null
            ? [
                FutureBuilder(
                    future: futureUser,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data!.rootLocationId != null
                            ? _getEndPartyButton()
                            : _getStartPartyButton();
                      }
                      return Container();
                    }),
                IconButton(
                    onPressed: () => _cleanLocationView(),
                    icon: const Icon(Icons.exit_to_app_outlined)),
              ]
            : [],
      ),
      drawer: Drawer(
        child: FutureBuilder(
          future: LocationService.getLocations(ElementType.root),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: snapshot.data!.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return DrawerHeader(
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary),
                        child: const Text(
                          'Location selection',
                          style: TextStyle(
                              fontSize: 42, fontWeight: FontWeight.bold),
                        ),
                      );
                    }
                    var location = snapshot.data![index - 1];
                    return ListTile(
                        title: Text(
                          location.name,
                          style: const TextStyle(fontSize: 24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 16),
                        onTap: () => _selectLocation(location.id),
                        enabled: location.enabled);
                  });
            }
            return Column(children: [
              DrawerHeader(
                decoration:
                    BoxDecoration(color: Theme.of(context).colorScheme.primary),
                child: const Text(
                  'Location selection',
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                ),
              ),
              const NotFoundWidget(
                  title: 'No results',
                  message: 'Locations could not be loaded or found.'),
            ]);
          },
        ),
      ),
      body: widget.rootLocation != null
          ? FutureBuilder(
              future: futureUser,
              builder: (context, snapshot) {
                return snapshot.hasData
                    ? LocationWidget(
                        club: widget.rootLocation!,
                        currentUserLocationId: snapshot.data?.locationId,
                        onChangedLocation: () => _refresh(),
                        canPostUpdates: snapshot.data!.rootLocationId != null &&
                            snapshot.data!.rootLocationId ==
                                widget.rootLocation?.id,
                      )
                    : const Center(child: CircularProgressIndicator());
              })
          : const Center(
              child: Text(
                'Please select a location in the upper left menu',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28),
              ),
            ),
    );
  }

  Widget _getEndPartyButton() {
    return IconButton(
        onPressed: () => _openDialog(PartyStateDialog(
            onAccept: () => _leaveTheLocation(),
            title: 'Leaving the club?',
            content:
                'An update with the time you left will be posted to the feed')),
        icon: const Icon(Icons.stop_circle_outlined));
  }

  Widget _getStartPartyButton() {
    return IconButton(
        onPressed: () => _openDialog(PartyStateDialog(
            onAccept: () => _arriveAtLocation(widget.rootLocation!.id),
            title: 'Check in?',
            content:
                'An update about your arrival at the selected location will be posted to the feed')),
        icon: const Icon(Icons.play_circle_outline_rounded));
  }

  void _openDialog(Widget dialogWidget) {
    showDialog(
        context: context,
        builder: (context) {
          return dialogWidget;
        });
  }

  void _selectLocation(int locationId) async {
    if (firebase.FirebaseAuth.instance.currentUser?.displayName == null ||
        firebase.FirebaseAuth.instance.currentUser!.displayName!.isEmpty) {
      _showErrorSnackBar('Please select username first');
    } else {
      Navigator.of(context).pop();
      LocationService.getLocation(locationId).then((location) {
        SharedPreferences.getInstance().then((sharedPreferences) {
          sharedPreferences.setString('club', jsonEncode(location));
          widget.onChangeLocation?.call();
        });
      });
    }
  }

  _refresh() {
    setState(() {});
  }

  void _leaveTheLocation() async {
    var userRootLocationId = (await UserService.getUser())?.rootLocationId;
    if (!await UserService.deleteUserLocation()) {
      _showErrorSnackBar('Could not check you out from the current location');
    } else {
      PostService.createPost(userRootLocationId, PostType.end).then((value) {
        if (value) {
          setState(() {
            futureUser = UserService.getUser();
          });
        } else {
          _showErrorSnackBar('Could not post your location update');
        }
      });
    }
  }

  void _arriveAtLocation(int locationId) async {
    if (firebase.FirebaseAuth.instance.currentUser?.displayName == null ||
        firebase.FirebaseAuth.instance.currentUser!.displayName!.isEmpty) {
      _showErrorSnackBar('Please select username first');
    } else {
      if (!await UserService.updateUserRootLocation(locationId)) {
        _showErrorSnackBar('Could not update your location, please retry');
      } else {
        PostService.createPost(locationId, PostType.start).then((value) {
          if (value) {
            setState(() {
              futureUser = UserService.getUser();
            });
          } else {
            _showErrorSnackBar('Could not post your location update');
          }
        });
      }
    }
  }

  void _cleanLocationView() {
    SharedPreferences.getInstance().then((value) {
      value.remove('club');
    });
    widget.onQuitRootLocation?.call();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class PartyStateDialog extends StatelessWidget {
  const PartyStateDialog({
    super.key,
    required this.onAccept,
    required this.title,
    required this.content,
  });

  final Function() onAccept;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        buttonPadding: const EdgeInsets.all(5),
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          ElevatedButton(
            child: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: const Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop();
              onAccept();
            },
          ),
        ],
      );
    });
  }
}
