import 'package:flutter/material.dart';
import 'package:party_radar/models/friendship.dart';
import 'package:party_radar/services/friendship_service.dart';
import 'package:party_radar/services/image_service.dart';
import 'package:widget_zoom/widget_zoom.dart';

class FriendWidget extends StatefulWidget {
  const FriendWidget({
    super.key,
    required this.username,
    this.subtitle,
    this.popupMenu,
    required this.padding,
    this.imageId,
  });

  final String username;
  final Text? subtitle;
  final PopupMenuButton? popupMenu;
  final EdgeInsetsGeometry padding;
  final int? imageId;

  @override
  State<FriendWidget> createState() => _FriendWidgetState();
}

class _FriendWidgetState extends State<FriendWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7.25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: _getLeadingImage(),
              title: Text(
                widget.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: widget.subtitle,
              trailing: FutureBuilder(
                  future: _getTrailingButton(),
                  builder: (_, snapshot) =>
                      snapshot.hasData ? snapshot.data! : const SizedBox()),
            ),
          ],
        ),
      ),
    );
  }

  Future<Widget> _getTrailingButton() async {
    var friendship =
        await FriendshipService.getFriendshipByUsername(widget.username);

    if (friendship?.status == FriendshipStatus.requested) {
      return OutlinedButton(
          onPressed: () => FriendshipService.deleteFriendship(friendship!.id)
              .then((_) => setState(() {})),
          child: const Text('Request sent'));
    }

    if (friendship?.status == FriendshipStatus.accepted) {
      return const OutlinedButton(
        onPressed: null,
        child: Text('Following'),
      );
    }

    return FilledButton(
        onPressed: () =>
            FriendshipService.createFriendshipRequest(widget.username)
                .then((_) => setState(() {})),
        child: const Text('Send request'));
  }

  Widget? _getLeadingImage() => FutureBuilder(
        future: ImageService.get(widget.imageId, size: 50),
        builder: (context, snapshot) {
          return snapshot.hasData
              ? ClipOval(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: WidgetZoom(
                        heroAnimationTag: 'tag-${widget.username}-list',
                        zoomWidget: snapshot.data!),
                  ),
                )
              : const SizedBox();
        },
      );
}
