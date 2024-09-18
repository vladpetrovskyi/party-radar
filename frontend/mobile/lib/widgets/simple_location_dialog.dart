import 'package:flutter/material.dart';
import 'package:party_radar/services/image_service.dart';
import 'package:party_radar/services/post_service.dart';
import 'package:widget_zoom/widget_zoom.dart';

class SimpleLocationDialog extends StatelessWidget {
  const SimpleLocationDialog({
    super.key,
    required this.locationName,
    this.imageId,
    this.username,
    this.capacity,
    this.postId,
  });

  final String locationName;
  final int? imageId;
  final String? username;
  final int? capacity;
  final int? postId;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: title,
      children: [
        description,
        divider,
        if (imageId != null) image,
        divider,
        _getBackButton(context),
      ],
    );
  }

  Widget get title => Text(
        'Location: $locationName',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 28),
      );

  Widget get description => FutureBuilder(
        future: PostService.getPostViewsCount(postId),
        builder: (context, snapshot) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (capacity != null)
              Text(
                'Free spots: $capacity',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            if (snapshot.hasData && snapshot.data != null && capacity != null)
              const Text(
                ' | ',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            if (snapshot.hasData && snapshot.data != null)
              Text(
                'Views: ${snapshot.data!}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
          ],
        ),
      );

  Widget get divider => const Divider(
        indent: 32,
        endIndent: 32,
        height: 32,
        color: Colors.grey,
        thickness: 0.5,
      );

  Widget get image => FutureBuilder(
        future: ImageService.get(imageId),
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

  Widget _getBackButton(BuildContext context) => Center(
        child: SimpleDialogOption(
          child: const Text(
            'BACK',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
}
