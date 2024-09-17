import 'package:flutter/material.dart';
import 'package:party_radar/models/post.dart';
import 'package:party_radar/services/post_service.dart';

class DeletePostDialog extends StatelessWidget {
  const DeletePostDialog({
    super.key,
    required this.post,
    required this.onDelete,
  });

  final Post post;
  final Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete post?"),
      content: const Text("This action cannot be undone!"),
      actions: [
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.close)),
        ElevatedButton(
            onPressed: () => _deletePost(context),
            child: const Icon(Icons.check))
      ],
    );
  }

  void _deletePost(BuildContext context) {
    PostService.deletePost(post.id!).then((isDeleted) {
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
      onDelete.call();
      Navigator.of(context).pop();
    });
  }
}
