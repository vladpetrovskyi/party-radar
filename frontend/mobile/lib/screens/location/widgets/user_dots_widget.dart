import 'package:flutter/material.dart';
import 'package:party_radar/services/location_service.dart';

class UserDotsWidget extends StatefulWidget {
  const UserDotsWidget({
    super.key,
    required this.locationId,
    this.alignment = WrapAlignment.start,
  });

  final int locationId;
  final WrapAlignment alignment;

  @override
  State<UserDotsWidget> createState() => _UserDotsWidgetState();
}

class _UserDotsWidgetState extends State<UserDotsWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: LocationService.getLocationUserCount(widget.locationId),
      builder: (context, snapshot) {
        return snapshot.hasData
            ? UserDots(userCount: snapshot.data!, alignment: widget.alignment)
            : Container();
      },
    );
  }
}

class UserDots extends StatelessWidget {
  const UserDots({super.key, this.alignment, required this.userCount});

  final WrapAlignment? alignment;
  final int userCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignment ?? WrapAlignment.start,
      children: List.generate(
        userCount,
        (index) => Padding(
          padding: const EdgeInsets.all(1.0),
          child: Icon(
            Icons.circle,
            size: 10,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
