import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/services/post_service.dart';

class PostWidget extends StatefulWidget {
  const PostWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.post,
    this.image,
    this.isEditable = false,
    this.onDelete
  });

  final String title;
  final String subtitle;
  final Post post;
  final Image? image;
  final bool isEditable;
  final Function()? onDelete;

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  late Offset _tapPosition;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTapDown: _storePosition,
        onLongPress: widget.isEditable ? () => _showPopupMenu() : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: widget.image != null
                  ? ClipOval(
                      child:
                          SizedBox(width: 50, height: 50, child: widget.image),
                    )
                  : null,
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
            PostService.deletePost(widget.post.id!).then((value) {
              if (!value) {
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
