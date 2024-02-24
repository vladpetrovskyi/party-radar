import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/post/actions.dart';
import 'package:party_radar/common/post/header.dart';

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
          PostHeader(
            showImage: widget.showImage,
            title: widget.title,
            subtitle: widget.subtitle,
            post: widget.post,
          ),
          PostActions(
            post: widget.post,
            updateViewsCounter: widget.updateViewsCounter,
            onDelete: widget.onDelete,
          )
        ],
      ),
    );
  }
}
