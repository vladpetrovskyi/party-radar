import 'package:flutter/material.dart';
import 'package:party_radar/common/services/image_service.dart';
import 'package:widget_zoom/widget_zoom.dart';

class SimpleLocationDialog extends StatelessWidget {
  const SimpleLocationDialog({
    super.key,
    required this.locationName,
    this.imageId,
    this.username,
    this.views,
    this.capacity,
  });

  final String locationName;
  final int? imageId;
  final String? username;
  final int? views;
  final int? capacity;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(title: _buildDialogTitle(context), children: [
      if (capacity != null || views != null) _buildDescription(),
      _getDivider(),
      if (imageId != null) _buildImage(),
      _getDivider(),
      _buildBackButton(context),
    ]);
  }

  Widget _getDivider() => const Divider(
        indent: 32,
        endIndent: 32,
        height: 32,
        color: Colors.grey,
        thickness: 0.5,
      );

  Widget _buildBackButton(BuildContext context) => SimpleDialogOption(
        child: const Center(
          child: Text(
            'BACK',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      );

  Widget _buildImage() => FutureBuilder(
        future: ImageService.getImage(imageId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: WidgetZoom(
                  heroAnimationTag: 'tag-$locationName$username',
                  zoomWidget: snapshot.data!),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      );

  Widget _buildDescription() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (capacity != null)
            Text(
              'Free spots: $capacity',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          if (views != null && capacity != null)
            const Text(
              ' | ',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          if (views != null)
            Text(
              'Views: $views',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
        ],
      );

  Widget _buildDialogTitle(BuildContext context) => Text(
        'Location: $locationName',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 28),
      );
}
