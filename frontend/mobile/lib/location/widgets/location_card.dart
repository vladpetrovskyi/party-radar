import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/services/location_service.dart';
import 'package:party_radar/location/dialogs/location_selection_dialog.dart';
import 'package:party_radar/location/dialogs/builders/share_location_dialog_builder.dart';
import 'package:party_radar/location/widgets/elapsed_time.dart';
import 'package:party_radar/location/widgets/user_dots_widget.dart';

class LocationCard extends StatefulWidget {
  const LocationCard({
    super.key,
    required this.location,
    required this.onChangedLocation,
    this.isSelected = false,
    this.isActive = false,
  });

  final Location location;
  final Function() onChangedLocation;
  final bool isSelected;
  final bool isActive;

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard>
    with ShareLocationDialogBuilder {
  LocationClosing? locationClosing;

  @override
  void initState() {
    if (widget.location.isCloseable) {
      _loadLocationClosing();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      shape: widget.isSelected
          ? RoundedRectangleBorder(
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            )
          : null,
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
                if (widget.location.emoji != null) _buildCardEmoji(),
                _buildCardName(),
                if (locationClosing?.closedAt == null) _buildOnlineStatusDots(),
              ],
            ),
            if (locationClosing != null && locationClosing!.closedAt != null)
              Container(
                decoration:
                    BoxDecoration(color: Colors.red.shade900.withOpacity(0.8)),
              ),
            if (locationClosing != null && locationClosing!.closedAt != null)
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
                  ElapsedTime(timestamp: locationClosing!.closedAt!),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Function()? _getOnTapFunction() {
    if (widget.isActive) {
      if (locationClosing != null && locationClosing!.closedAt != null) {
        return () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Mark as opened'),
                content: const Text(
                    'This location has been temporarily closed. Is it available again? The result of this action will be visible to everyone!'),
                actions: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Icon(Icons.close),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _openLocation(widget.location.id);
                      Navigator.of(context).pop();
                    },
                    child: const Icon(Icons.check),
                  ),
                ],
              );
            },
          );
        };
      }
      return () {
        if (widget.location.onClickAction == OnClickAction.openDialog) {
          showDialog<void>(
            context: context,
            builder: (context) {
              return LocationSelectionDialog(
                context: context,
                locations: widget.location.children,
                dialogName: widget.location.dialogName,
                imageId: widget.location.imageId,
                parentLocationId: widget.location.id,
                onChangedLocation: widget.onChangedLocation,
                isCapacitySelectable: widget.location.isCapacitySelectable,
              );
            },
          );
        } else {
          buildShareLocationDialog(context, widget.location.id);
        }
      };
    }
    return () => _showErrorSnackBar(
        'Please check in first by pressing play button', context);
  }

  Function()? _getLongPressFunction() {
    if (widget.isActive && locationClosing != null && locationClosing!.closedAt == null) {
      return () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Mark as closed'),
              content: const Text(
                  'Would you like to mark this location as temporarily closed? The result of this action will be visible to everyone!'),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Icon(Icons.close),
                ),
                ElevatedButton(
                  onPressed: () {
                    _closeLocation(widget.location.id);
                    Navigator.of(context).pop();
                  },
                  child: const Icon(Icons.check),
                ),
              ],
            );
          },
        );
      };
    }
    return null;
  }

  void _closeLocation(int locationId) {
    LocationService.updateLocationClosing(locationId, DateTime.now())
        .then((value) => _loadLocationClosing());
  }

  void _openLocation(int locationId) {
    LocationService.updateLocationClosing(locationId, null)
        .then((value) => _loadLocationClosing());
  }

  void _showErrorSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildCardName() => Padding(
        padding: const EdgeInsets.only(left: 5, right: 5, top: 2, bottom: 5),
        child: Text(
          widget.location.name,
          style: const TextStyle(
            fontSize: 20,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      );

  Widget _buildCardEmoji() => Padding(
        padding: const EdgeInsets.only(left: 5, right: 5, bottom: 2),
        child: Text(
          widget.location.emoji ?? '',
          style: const TextStyle(
            fontSize: 20,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      );

  Widget _buildOnlineStatusDots() => Padding(
        padding: const EdgeInsets.only(left: 5, right: 5, top: 5),
        child: UserDotsWidget(
          locationId: widget.location.id,
          alignment: WrapAlignment.center,
        ),
      );

  void _loadLocationClosing() {
    LocationService.getLocationClosing(widget.location.id)
        .then((locationClosing) {
      if (locationClosing.isCloseable) {
        setState(() {
          this.locationClosing = locationClosing;
        });
      }
    });
  }

  @override
  Function() get onLocationChanged => widget.onChangedLocation;
}
