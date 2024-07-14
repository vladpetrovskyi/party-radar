import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/providers.dart';
import 'package:party_radar/common/services/post_service.dart';
import 'package:party_radar/common/services/user_service.dart';
import 'package:party_radar/location/location_widget.dart';
import 'package:party_radar/location/widgets/location_drawer.dart';
import 'package:provider/provider.dart';

class LocationPage extends StatefulWidget {
  const LocationPage(this.rootLocation, {super.key});

  final Location? rootLocation;

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  TextEditingController? _textEditingController;

  @override
  void dispose() {
    _textEditingController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder:
          (BuildContext context, UserProvider userProvider, Widget? child) =>
              Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Consumer<LocationProvider>(
          builder: (BuildContext context, LocationProvider locationProvider,
              Widget? child) {
            if (locationProvider.editMode) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton.extended(
                    onPressed: () {
                      widget.rootLocation?.children.add(
                        Location(name: "", elementType: ElementType.listTile),
                      );
                      locationProvider.updateRootLocation(widget.rootLocation);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Tile"),
                  ),
                  FloatingActionButton.extended(
                    onPressed: () {
                      widget.rootLocation?.children.add(
                        Location(
                            name: "", elementType: ElementType.expansionTile),
                      );
                      locationProvider.updateRootLocation(widget.rootLocation);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Expansion"),
                  ),
                ],
              );
            }
            return Container();
          },
        ),
        appBar: AppBar(
          centerTitle: true,
          title: Consumer<LocationProvider>(
            builder: (BuildContext context, LocationProvider provider,
                Widget? child) {
              _textEditingController?.dispose();
              _textEditingController =
                  TextEditingController(text: provider.rootLocation?.name);
              if (provider.editMode) {
                return TextField(
                  controller: _textEditingController,
                  onChanged: (val) => provider.rootLocation?.name = val,
                  style: const TextStyle(
                    fontSize: 28,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color.fromRGBO(119, 136, 153, 0.05),
                    border: UnderlineInputBorder(),
                    isCollapsed: true,
                  ),
                );
              }
              return SizedBox(
                height: 40,
                child: Hero(
                  tag: 'logo_hero',
                  child: Image.asset('assets/logo_app_bar.png'),
                ),
              );
            },
          ),
          actions: _getActions(userProvider.user, widget.rootLocation),
        ),
        drawer: const LocationDrawer(),
        body: widget.rootLocation != null
            ? userProvider.user != null
                ? LocationWidget(widget.rootLocation)
                : const Center(child: CircularProgressIndicator())
            : const Center(
                child: Text(
                  'Please select a location in the upper left menu',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28),
                ),
              ),
      ),
    );
  }

  List<Widget> _getActions(User? user, Location? rootLocation) {
    if (rootLocation != null && user != null) {
      return [
        user.rootLocationId != null
            ? _getEndPartyButton()
            : _getStartPartyButton(rootLocation),
        Padding(
          padding: const EdgeInsets.only(right: 6.60),
          child: user.username == rootLocation.createdBy
              ? IconButton(
                  onPressed: () =>
                      Provider.of<LocationProvider>(context, listen: false)
                          .setEditMode(null),
                  icon: Provider.of<LocationProvider>(context, listen: false)
                          .editMode
                      ? const Icon(Icons.check)
                      : const Icon(Icons.edit_outlined),
                )
              : Container(),
        ),
      ];
    }
    return [];
  }

  Widget _getEndPartyButton() {
    return Consumer<UserProvider>(
      builder: (BuildContext context, UserProvider provider, Widget? child) =>
          IconButton(
        onPressed: () => _openDialog(
          PartyStateDialog(
            onAccept: () => _leaveTheLocation(provider.user?.rootLocationId),
            title: 'Leaving the club?',
            content: const Text(
                'An update with the time you left will be posted to the feed'),
          ),
        ),
        icon: const Icon(Icons.stop_circle_outlined),
      ),
    );
  }

  Widget _getStartPartyButton(Location rootLocation) {
    return IconButton(
        onPressed: () => _openDialog(
              PartyStateDialog(
                onAccept: () => _arriveAtLocation(rootLocation.id),
                title: 'Check in?',
                content: const Text(
                    'An update about your arrival at the selected location will be posted to the feed'),
              ),
            ),
        icon: const Icon(Icons.play_circle_outline_rounded));
  }

  void _openDialog(Widget dialogWidget) {
    showDialog(context: context, builder: (context) => dialogWidget);
  }

  void _leaveTheLocation(int? userRootLocationId) async {
    if (!await UserService.deleteUserLocation()) {
      _showErrorSnackBar('Could not check you out from the current location');
    } else {
      PostService.createPost(userRootLocationId, PostType.end, null)
          .then((postCreated) {
        if (postCreated) {
          Provider.of<UserProvider>(context, listen: false).updateUser();
        } else {
          _showErrorSnackBar('Could not post your location update');
        }
      });
    }
  }

  void _arriveAtLocation(int? locationId) async {
    if (locationId == null) return;

    if (firebase.FirebaseAuth.instance.currentUser?.displayName == null ||
        firebase.FirebaseAuth.instance.currentUser!.displayName!.isEmpty) {
      _showErrorSnackBar('Please select username first');
      return;
    }

    if (!await UserService.updateUserRootLocation(locationId)) {
      _showErrorSnackBar('Could not update your location, please retry');
      return;
    }

    PostService.createPost(locationId, PostType.start, null).then((value) {
      if (!value) {
        _showErrorSnackBar('Could not post your location update');
        return;
      }

      Provider.of<UserProvider>(context, listen: false).updateUser();
    });
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
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        buttonPadding: const EdgeInsets.all(5),
        title: Text(title),
        content: content,
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
