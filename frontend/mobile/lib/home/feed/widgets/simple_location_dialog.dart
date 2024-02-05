import 'package:flutter/material.dart';
import 'package:party_radar/common/services/image_service.dart';
import 'package:widget_zoom/widget_zoom.dart';

class SimpleLocationDialog extends StatelessWidget {
  const SimpleLocationDialog({
    super.key,
    required this.dialogName,
    this.imageId,
  });

  final String dialogName;
  final int? imageId;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(title: _buildDialogTitle(), children: [
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
                heroAnimationTag: 'tag-$dialogName',
                zoomWidget: snapshot.data!);
          }
          return const CircularProgressIndicator();
        },
      );

  Widget _buildDialogTitle() => Text(
        'Location: $dialogName',
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
}
