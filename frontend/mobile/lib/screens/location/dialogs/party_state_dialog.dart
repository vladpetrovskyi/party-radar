import 'package:flutter/material.dart';

class PartyStateDialog extends StatelessWidget {
  const PartyStateDialog({
    super.key,
    required this.onAccept,
    required this.title,
    required this.content,
  });

  final Function() onAccept;
  final String title;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        buttonPadding: const EdgeInsets.all(5),
        title: Text(title),
        content: content,
        actions: <Widget>[
          ElevatedButton(
            child: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop();
              onAccept();
            },
          ),
        ],
      );
    });
  }
}
