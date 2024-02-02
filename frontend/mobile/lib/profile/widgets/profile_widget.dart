import 'package:flutter/material.dart';

class ProfileWidget extends StatelessWidget {
  final bool isEdit;
  final VoidCallback onClicked;
  final Image? image;

  const ProfileWidget({
    super.key,
    this.isEdit = false,
    required this.onClicked,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Center(child: buildImage(context: context));
  }

  Widget buildImage({required BuildContext context}) {
    final color = Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        ClipOval(
          child: Material(color: Colors.transparent, child: image),
        ),
        Positioned(bottom: 0, right: 4, child: buildEditIcon(color)),
      ],
    );
  }

  Widget buildEditIcon(Color color) => buildCircle(
        color: Colors.white,
        all: 3,
        child: InkWell(
          onTap: onClicked,
          child: buildCircle(
            color: color,
            all: 8,
            child: Icon(
              isEdit ? Icons.add_a_photo : Icons.edit,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );

  Widget buildCircle({
    required Widget child,
    required double all,
    required Color color,
  }) =>
      ClipOval(
        child: Container(
          padding: EdgeInsets.all(all),
          color: color,
          child: child,
        ),
      );
}
