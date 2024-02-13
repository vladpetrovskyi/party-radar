import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/services/image_service.dart';
import 'package:party_radar/common/services/post_service.dart';
import 'package:party_radar/common/simple_location_dialog.dart';
import 'package:widget_zoom/widget_zoom.dart';

class PostWidget extends StatefulWidget {
  const PostWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.post,
    this.isEditable = false,
    this.onDelete,
    this.imageId,
  });

  final String title;
  final String subtitle;
  final Post post;
  final bool isEditable;
  final Function()? onDelete;
  final int? imageId;

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  late Offset _tapPosition;

  void _openPositionDialog(Location openDialogLocation) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleLocationDialog(
          locationName: openDialogLocation.children[0].name,
          imageId: openDialogLocation.imageId,
          username: widget.post.username,
        );
      },
    );
  }

  Location? _getOpenDialogLocation(Location location) {
    if (widget.post.location.onClickAction == OnClickAction.openDialog) {
      return location;
    }
    for (Location child in location.children) {
      if (child.onClickAction == OnClickAction.openDialog) {
        return child;
      }
      var c = _getOpenDialogLocation(child);
      if (c?.onClickAction == OnClickAction.openDialog) {
        return c;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    var openDialogLocation = _getOpenDialogLocation(widget.post.location);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTapDown: widget.isEditable ? _storePosition : null,
        onLongPress: widget.isEditable ? () => _showPopupMenu() : null,
        onTap:
            openDialogLocation != null && openDialogLocation.children.isNotEmpty
                ? () => _openPositionDialog(openDialogLocation)
                : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: _getLeadingImage(),
              title: Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(widget.subtitle),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _getLocationHeader(widget.post),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                  ),
                  Text(
                    _getLocationSubheader(widget.post),
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _getLeadingImage() => widget.imageId != null
      ? FutureBuilder(
          future: ImageService.getImage(widget.imageId, size: 50),
          builder: (context, snapshot) {
            return snapshot.hasData
                ? ClipOval(
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: WidgetZoom(
                          heroAnimationTag: 'tag-${widget.post.id}',
                          zoomWidget: snapshot.data!),
                    ),
                  )
                : const SizedBox();
          },
        )
      : null;

  String _getLocationHeader(Post post) {
    if (post.type == PostType.start) {
      return 'ARRIVED';
    }
    if (post.type == PostType.ongoing) {
      return '${post.location.children[0].name} ${post.location.children[0].emoji}';
    }
    if (post.type == PostType.end) {
      return 'LEFT';
    }
    return '';
  }

  String _getLocationSubheader(Post post) {
    if (post.type == PostType.start) {
      return '- - - -';
    }
    if (post.type == PostType.ongoing &&
        post.location.children[0].children.isNotEmpty) {
      return '${post.location.children[0].children[0].name} ${post.location.children[0].children[0].emoji}';
    }
    if (post.type == PostType.end) {
      return '- - - -';
    }
    return '';
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _showPopupMenu() {
    final RenderObject? overlay =
        Overlay.of(context).context.findRenderObject();

    showMenu(
      context: context,
      position: RelativeRect.fromRect(_tapPosition & const Size(40, 40),
          Offset.zero & overlay!.semanticBounds.size),
      items: <PopupMenuEntry<Post>>[
        PopupMenuItem<Post>(
          onTap: () {
            PostService.deletePost(widget.post.id!).then((isDeleted) {
              if (!isDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text(
                      'Post could not be deleted',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                );
                return;
              }
              widget.onDelete?.call();
            });
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
