import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/post/dialogs/delete_post.dart';
import 'package:party_radar/common/services/post_service.dart';
import 'package:party_radar/common/simple_location_dialog.dart';

class PostActions extends StatelessWidget {
  const PostActions({
    super.key,
    required this.post,
    this.updateViewsCounter = false,
    this.onDelete,
  });

  final Post post;
  final bool updateViewsCounter;
  final Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    var openDialogLocation = _getOpenDialogLocation(post.location);
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
            child: const Icon(
              FontAwesomeIcons.locationArrow,
              size: 18,
            ),
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
              child: const Icon(
                FontAwesomeIcons.trashCan,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Location? _getOpenDialogLocation(Location location) {
    if (post.location.onClickAction == OnClickAction.openDialog) {
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
