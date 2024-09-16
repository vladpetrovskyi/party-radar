import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/services/image_service.dart';
import 'package:widget_zoom/widget_zoom.dart';

class PostHeader extends StatelessWidget {
  const PostHeader({
    super.key,
    required this.showImage,
    required this.title,
    required this.subtitle,
    required this.post,
  });

  final bool showImage;
  final String title;
  final String subtitle;
  final Post post;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: showImage ? leadingImage : null,
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
            headerText,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
          ),
          Text(
            subheaderText,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  String get headerText {
    if (post.type == PostType.start) {
      return 'ARRIVED';
    }
    if (post.type == PostType.ongoing) {
      return '${post.location.children[0].name} ${post.location.children[0].emoji ?? ''}'
          .trim();
    }
    if (post.type == PostType.end) {
      return 'LEFT';
    }
    return '';
  }

  String get subheaderText {
    if (post.type == PostType.start) {
      return '- - - -';
    }
    if (post.type == PostType.ongoing &&
        post.location.children[0].children.isNotEmpty) {
      return '${post.location.children[0].children[0].name} ${post.location.children[0].children[0].emoji ?? ''}'
          .trim();
    }
    if (post.type == PostType.end) {
      return '- - - -';
    }
    return '';
  }

  Widget get leadingImage => FutureBuilder(
        future: ImageService.get(post.imageId, size: 40),
        builder: (context, snapshot) {
          return snapshot.hasData
              ? ClipOval(
                  child: SizedBox(
                    child: WidgetZoom(
                        heroAnimationTag: 'tag-${post.imageId}-${DateTime.now()}',
                        zoomWidget: snapshot.data!),
                  ),
                )
              : const SizedBox();
        },
      );
}
