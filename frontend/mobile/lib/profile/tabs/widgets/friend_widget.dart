import 'package:flutter/material.dart';
import 'package:party_radar/common/services/image_service.dart';
import 'package:widget_zoom/widget_zoom.dart';

class FriendWidget extends StatelessWidget {
  const FriendWidget({
    super.key,
    this.username,
    this.subtitle,
    required this.popupMenu,
    this.padding = EdgeInsets.zero,
    this.imageId,
  });

  final String? username;
  final Text? subtitle;
  final PopupMenuButton? popupMenu;
  final EdgeInsetsGeometry padding;
  final int? imageId;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: _getLeadingImage(),
              title: Text(
                username ?? '? ? ? ?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: subtitle,
              trailing: popupMenu,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _getLeadingImage() => FutureBuilder(
        future: ImageService.getImage(imageId, size: 50),
        builder: (context, snapshot) {
          return snapshot.hasData
              ? ClipOval(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: WidgetZoom(
                        heroAnimationTag: 'tag-$username',
                        zoomWidget: snapshot.data!),
                  ),
                )
              : const SizedBox();
        },
      );
}
