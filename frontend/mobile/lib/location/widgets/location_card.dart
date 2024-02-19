import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
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
  bool _isCleaning = false;

  @override
  void initState() {
    // TODO: fetch closing time from API
    if (widget.location.isCloseable ?? false) _isCleaning = true;

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
              borderRadius: const BorderRadius.all(Radius.circular(10)))
          : null,
      child: InkWell(
        onLongPress: widget.location.isCloseable ?? false
            ? () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        icon: const Icon(Icons.warning_amber_rounded),
                        title: const Text('Mark as closed location'),
                        content: const Text(
                            'Would you like to mark this location as temporarily closed?'),
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
                    });
              }
            : null,
        onTap: widget.isActive
            ? () {
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
                          isCapacitySelectable:
                              widget.location.isCapacitySelectable,
                        );
                      });
                } else {
                  buildShareLocationDialog(context, widget.location.id);
                }
              }
            : () => _showErrorSnackBar(
                'Please check in first by pressing play button', context),
        child: Stack(alignment: AlignmentDirectional.center, children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.location.emoji != null) _buildCardEmoji(),
              _buildCardName(),
              if (!_isCleaning) _buildOnlineStatusDots(),
            ],
          ),
          if (_isCleaning)
            Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
            ),
          if (_isCleaning)
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Cleaning',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElapsedTime(timestamp: '2024-02-19 14:24:18.895235'),
              ],
            ),
        ]),
      ),
    );
  }

  void _closeLocation(int? locationId) {}

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

  @override
  Function() get onLocationChanged => widget.onChangedLocation;
}
