import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';

class PostWidget extends StatelessWidget {
  const PostWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.post,
    this.image,
  });

  final String title;
  final String subtitle;
  final Post post;
  final Image? image;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onLongPress: null, //TODO: dialog with exact location OR delete post (with dropdown menu)
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: image != null
                  ? ClipOval(
                      child: SizedBox(width: 50, height: 50, child: image),
                    )
                  : null,
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(subtitle),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _getLocationHeader(post),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                  ),
                  Text(
                    _getLocationSubheader(post),
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
}
