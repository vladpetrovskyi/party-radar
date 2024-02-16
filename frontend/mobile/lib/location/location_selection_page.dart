import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/profile/tabs/widgets/not_found_widget.dart';
import 'package:party_radar/common/services/location_service.dart';
import 'package:party_radar/common/services/post_service.dart';
import 'package:party_radar/common/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationSelectionPage extends StatefulWidget {
  const LocationSelectionPage({super.key, this.onChangeLocation});

  final Function()? onChangeLocation;

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  int? _selectedLocationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const SizedBox(
          height: 40,
          child: Text(
            'Select location',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
      ),
      body: FutureBuilder(
        future: LocationService.getLocations(ElementType.root),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => LocationTile(
                  name: snapshot.data![index].name,
                  onSelectedLocationChanged: (value) {
                    setState(() {
                      _selectedLocationId = value;
                    });
                  },
                  enabled: snapshot.data![index].enabled,
                  value: _selectedLocationId == snapshot.data![index].id,
                  id: snapshot.data![index].id),
            );
          } else if (snapshot.hasError) {
            return const NotFoundWidget(title: 'No results', message: 'Locations could not be loaded or found.');
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: _selectedLocationId != null
          ? FloatingActionButton.extended(
              onPressed: () => _selectLocation(_selectedLocationId!),
              label: const Text(
                'START',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.play_circle_fill_rounded),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _selectLocation(int locationId) async {
    if (FirebaseAuth.instance.currentUser?.displayName == null ||
        FirebaseAuth.instance.currentUser!.displayName!.isEmpty) {
      _showErrorSnackBar('Please select username first');
    } else {
      if (!await UserService.updateUserRootLocation(locationId)) {
        _showErrorSnackBar('Could not update your location, please retry');
      } else {
        LocationService.getLocation(locationId).then((location) {
          SharedPreferences.getInstance().then((sharedPreferences) {
            sharedPreferences.setString('club', jsonEncode(location));
            widget.onChangeLocation?.call();
          });
        });
        PostService.createPost(locationId, PostType.start, null);
      }
    }
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

class LocationTile extends StatelessWidget {
  const LocationTile(
      {super.key,
      required this.name,
      required this.onSelectedLocationChanged,
      required this.enabled,
      required this.value,
      required this.id});

  final String name;
  final ValueChanged<int?> onSelectedLocationChanged;
  final bool enabled;
  final bool value;
  final int id;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(
        name,
        style: const TextStyle(fontSize: 20),
      ),
      onChanged: (value) {
        value != null && value
            ? onSelectedLocationChanged.call(id)
            : onSelectedLocationChanged.call(null);
      },
      enabled: enabled,
      value: value,
    );
  }
}
