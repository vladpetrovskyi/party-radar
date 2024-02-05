import 'package:flutter/material.dart';
import 'package:widget_zoom/widget_zoom.dart';

class FriendWidget extends StatelessWidget {
  const FriendWidget({
    super.key,
    required this.image,
    this.username,
    this.subtitle,
    required this.popupMenu,
    this.padding = EdgeInsets.zero,
  });

  final Image image;
  final String? username;
  final Text? subtitle;
  final PopupMenuButton? popupMenu;
  final EdgeInsetsGeometry padding;

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
              leading: ClipOval(
                child: SizedBox(
                    width: 50,
                    height: 50,
                    child: WidgetZoom(
                        heroAnimationTag: 'tag-$username', zoomWidget: image)),
              ),
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
}
