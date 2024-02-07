import 'package:flutter/material.dart';
import 'package:party_radar/common/services/image_service.dart';
import 'package:widget_zoom/widget_zoom.dart';

class SimpleLocationDialog extends StatelessWidget {
  const SimpleLocationDialog({
    super.key,
    required this.locationName,
    this.imageId,
    this.username,
  });

  final String locationName;
  final int? imageId;
  final String? username;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(title: _buildDialogTitle(context), children: [
      if (imageId != null) _buildImage(),
      const SizedBox(height: 12),
      _buildBackButton(context)
    ]);
  }

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
            return WidgetZoom(
                heroAnimationTag: 'tag-$locationName$username',
                zoomWidget: snapshot.data!);
          }
          return const CircularProgressIndicator();
        },
      );

  Widget _buildDialogTitle(BuildContext context) => Text(
        username != null
            ? 'Location of $username: $locationName'
            : 'Location: $locationName',
    style: const TextStyle(fontWeight: FontWeight.bold),
      );
}
