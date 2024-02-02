import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/location/location_widget.dart';
import 'package:party_radar/common/services/post_service.dart';
import 'package:party_radar/common/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPage extends StatefulWidget {
  const LocationPage(
      {super.key, required this.club, required this.onQuitRootLocation});

  final Location club;
  final Function()? onQuitRootLocation;

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const IconButton(
          icon: Icon(Icons.question_mark_rounded),
          onPressed: null,
        ),
        centerTitle: true,
        title: SizedBox(
          height: 40,
          child: Hero(
              tag: 'logo_hero', child: Image.asset('assets/logo_app_bar.png')),
        ),
        actions: [
          IconButton(
              onPressed: () => _endPartyDialogBuilder(context),
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: FutureBuilder(
          future: UserService.getUser(),
          builder: (context, snapshot) {
            return snapshot.hasData
                ? LocationWidget(
                    club: widget.club,
                    currentUserLocationId: snapshot.data?.locationId,
                    onChangedLocation: () => _refresh(),
                  )
                : const CircularProgressIndicator();
          }),
    );
  }

  _refresh() {
    setState(() {});
  }

  Future<void>? _endPartyDialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            actionsAlignment: MainAxisAlignment.center,
            buttonPadding: const EdgeInsets.all(5),
            title: const Text('Leaving the club?'),
            content:
                const Text('An update will be posted to your friends\' feeds'),
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
                  _leaveTheClub();
                },
              ),
            ],
          );
        });
      },
    );
  }

  void _leaveTheClub() async {
    var userRootLocationId = (await UserService.getUser())?.rootLocationId;
    if (!await UserService.deleteUserLocation()) {
      _showErrorSnackBar('Could not log you out from current location');
    } else {
      PostService.createPost(userRootLocationId, PostType.end).then((value) {
        if (value) {
          SharedPreferences.getInstance().then((value) {
          value.remove('club');
        });
        widget.onQuitRootLocation?.call();
        } else {
          _showErrorSnackBar('Could not post your location update');
        }
      });

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
