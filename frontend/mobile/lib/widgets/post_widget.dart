import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/models/post.dart';
import 'package:party_radar/screens/user_profile/dialogs/delete_post.dart';
import 'package:party_radar/services/image_service.dart';
import 'package:party_radar/services/post_service.dart';
import 'package:party_radar/widgets/simple_location_dialog.dart';
import 'package:widget_zoom/widget_zoom.dart';

class PostWidget extends StatefulWidget {
  const PostWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.post,
    this.isEditable = false,
    this.onDelete,
    this.showImage = false,
    this.updateViewsCounter = false,
  });

  final String title;
  final String subtitle;
  final Post post;
  final bool isEditable;
  final Function()? onDelete;
  final bool showImage;
  final bool updateViewsCounter;

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _PostHeader(
            showImage: widget.showImage,
            title: widget.title,
            subtitle: widget.subtitle,
            post: widget.post,
          ),
          _PostActions(
            post: widget.post,
            updateViewsCounter: widget.updateViewsCounter,
            onDelete: widget.onDelete,
          )
        ],
      ),
    );
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.post,
    this.updateViewsCounter = false,
    this.onDelete,
  });

  final Post post;
  final bool updateViewsCounter;
  final Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    var openDialogLocation = _getLocationWithOpenDialogClickAction(post.location);
    return Container(
      margin: const EdgeInsets.only(right: 20, left: 20, bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(width: 0, color: Colors.transparent),
            ),
            onPressed: openDialogLocation != null &&
                openDialogLocation.children.isNotEmpty
                ? () => _openPositionDialog(openDialogLocation, context)
                : null,
            child: const Icon(FontAwesomeIcons.locationArrow),
          ),
          if (onDelete != null)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(width: 0, color: Colors.transparent),
              ),
              onPressed: () => showDialog(
                context: context,
                builder: (context) =>
                    DeletePostDialog(post: post, onDelete: onDelete!),
              ),
              child: const Icon(FontAwesomeIcons.trashCan),
            ),
        ],
      ),
    );
  }

  Location? _getLocationWithOpenDialogClickAction(Location location) {
    if (post.location.onClickAction == OnClickAction.openDialog) {
      return location;
    }
    for (Location child in location.children) {
      if (child.onClickAction == OnClickAction.openDialog) {
        return child;
      }
      var c = _getLocationWithOpenDialogClickAction(child);
      if (c?.onClickAction == OnClickAction.openDialog) {
        return c;
      }
    }
    return null;
  }

  void _openPositionDialog(Location openDialogLocation, BuildContext context) {
    if (updateViewsCounter) {
      PostService.increaseViewCountByOne(post.id);
    }

    showDialog(
      context: context,
      builder: (context) {
        return SimpleLocationDialog(
          locationName: openDialogLocation.children[0].name,
          imageId: openDialogLocation.imageId,
          username: post.username,
          capacity: openDialogLocation.isCapacitySelectable ?? false
              ? post.capacity
              : null,
          postId: post.id,
        );
      },
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({
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
