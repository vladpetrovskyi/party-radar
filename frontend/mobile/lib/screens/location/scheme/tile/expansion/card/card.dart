import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/providers/user_provider.dart';
import 'package:party_radar/screens/location/dialogs/party_state_dialog.dart';
import 'package:party_radar/screens/location/scheme/tile/dialogs/share_location_dialog_builder.dart';
import 'package:party_radar/screens/location/scheme/tile/expansion/card/dialogs/location_selection_dialog.dart';
import 'package:party_radar/screens/location/scheme/tile/expansion/card/edit/edit_card_screen.dart';
import 'package:party_radar/screens/location/scheme/tile/expansion/card/widgets/timer.dart';
import 'package:party_radar/screens/location/scheme/tile/widgets/user_dots_widget.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:party_radar/widgets/error_snack_bar.dart';
import 'package:provider/provider.dart';

class LocationCard extends StatefulWidget {
  const LocationCard({
    super.key,
    required this.location,
    this.isEditMode = false,
  });

  final Location location;
  final bool isEditMode;

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard>
    with ShareLocationDialogBuilder, ErrorSnackBar {
  late Location _location;

  @override
  void initState() {
    super.initState();
    _location = widget.location;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, provider, child) => Card(
        clipBehavior: Clip.hardEdge,
        shape: getShape(provider),
        surfaceTintColor: _location.enabled ? null : Colors.red,
        child: child,
      ),
      child: InkWell(
        onLongPress: _getLongPressFunction(),
        onTap: _getOnTapFunction(),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_location.emoji != null) cardEmoji,
                cardName,
                if (_location.closedAt == null) onlineStatusDots,
                if (_location.isCloseable && _location.closedAt != null)
                  ...closedOverlay
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget get cardName => Padding(
        padding: const EdgeInsets.only(left: 5, right: 5, top: 2, bottom: 5),
        child: Text(
          _location.name,
          style: const TextStyle(
            fontSize: 20,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      );

  Widget get cardEmoji => Padding(
        padding: const EdgeInsets.only(left: 5, right: 5, bottom: 2),
        child: Text(
          _location.emoji ?? '',
          style: const TextStyle(
            fontSize: 20,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      );

  Widget get onlineStatusDots => _location.id != null
      ? Padding(
          padding: const EdgeInsets.only(left: 5, right: 5, top: 5),
          child: UserDotsWidget(
            locationId: _location.id!,
            alignment: WrapAlignment.center,
          ),
        )
      : Container();

  List<Widget> get closedOverlay => [
        Container(
          decoration:
              BoxDecoration(color: Colors.red.shade900.withOpacity(0.8)),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Closed',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            TimerWidget(timestamp: _location.closedAt!),
          ],
        ),
      ];

  ShapeBorder? getShape(LocationProvider provider) {
    if (widget.isEditMode) {
      return null;
    }
    return provider.currentLocationTree.contains(_location.id)
        ? RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          )
        : null;
  }

  Function()? _getOnTapFunction() {
    if (widget.isEditMode) {
      return () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditCardScreen(
                location: _location,
                handle: (newLocation) =>
                    setState(() => _location = newLocation),
              ),
            ),
          );
    }

    if (!_isActive()) {
      return () => showErrorSnackBar(
          'Please check in first by pressing play button', context);
    }

    if (_location.isCloseable && _location.closedAt != null) {
      return () => showDialog(
            context: context,
            builder: (context) => PartyStateDialog(
              title: 'Mark as opened',
              content: const Text(
                  'This location has been temporarily closed. Is it available again? The result of this action will be visible to everyone!'),
              onAccept: () {
                _openLocation(_location.id);
                Navigator.of(context).pop();
              },
            ),
          );
    }

    return () {
      if (_location.id == null) return;

      if (_location.onClickAction != OnClickAction.openDialog) {
        buildShareLocationDialog(context, _location.id);
        return;
      }

      LocationService.getLocationChildren(_location.id!)
          .then((locationChildren) {
        if (locationChildren == null || locationChildren.isEmpty) {
          buildShareLocationDialog(context, _location.id);
          return;
        }
        showDialog<void>(
          context: context,
          builder: (context) {
            return LocationSelectionDialog(
              context: context,
              dialogName: _location.dialogName,
              imageId: _location.imageId,
              parentLocationId: _location.id!,
              isCapacitySelectable: _location.isCapacitySelectable,
              locationChildren: locationChildren,
            );
          },
        );
      });
    };
  }

  Function()? _getLongPressFunction() {
    if (!_isActive() ||
        !_location.isCloseable ||
        _location.closedAt != null ||
        widget.isEditMode) {
      return null;
    }

    return () => showDialog(
          context: context,
          builder: (context) => PartyStateDialog(
            title: 'Mark as closed',
            content: const Text(
                'Would you like to mark this location as temporarily closed? The result of this action will be visible to everyone!'),
            onAccept: () {
              _closeLocation(_location.id);
              Navigator.of(context).pop();
            },
          ),
        );
  }

  void _closeLocation(int? locationId) {
    if (locationId == null) return;

    LocationService.updateLocationAvailability(locationId, DateTime.now())
        .then((_) => _reloadLocation());
  }

  void _openLocation(int? locationId) {
    if (locationId == null) return;

    LocationService.updateLocationAvailability(locationId, null)
        .then((_) => _reloadLocation());
  }

  void _reloadLocation() async =>
      LocationService.getLocation(_location.id).then((l) {
        if (l != null) {
          setState(() => _location = l);
        } else {
          showErrorSnackBar(
              "Could not update the view - service unavailable", context);
        }
      });

  bool _isActive() {
    var rootLocation =
        Provider.of<LocationProvider>(context, listen: false).rootLocation;
    var userRootLocationId =
        Provider.of<UserProvider>(context, listen: false).user?.rootLocationId;
    return userRootLocationId != null && userRootLocationId == rootLocation?.id;
  }
}
