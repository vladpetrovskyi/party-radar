import 'package:flutter/material.dart';
import 'package:party_radar/services/friendship_service.dart';
import 'package:party_radar/util/validators.dart';

class FriendshipRequestDialog extends StatefulWidget {
  const FriendshipRequestDialog({super.key});

  @override
  State<FriendshipRequestDialog> createState() =>
      _FriendshipRequestDialogState();
}

class _FriendshipRequestDialogState extends State<FriendshipRequestDialog> {
  final TextEditingController _usernameFieldController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AlertDialog(
          title: const Text('Friendship request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a full and correct username'),
              const SizedBox(
                height: 14,
              ),
              Form(
                key: _formKey,
                child: TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _usernameFieldController,
                  decoration: const InputDecoration(
                    label: Text('Username'),
                    border: OutlineInputBorder(),
                  ),
                  validator: (input) => input == null ||
                          input.isEmpty ||
                          UsernameValidator.isValid(input)
                      ? null
                      : 'Allowed characters: a-z, 0-9, ._-',
                ),
              )
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: const Icon(Icons.check),
              onPressed: () {
                if (_usernameFieldController.text.isNotEmpty &&
                    (_formKey.currentState?.validate() ?? false)) {
                  FriendshipService.createFriendshipRequest(
                          _usernameFieldController.text)
                      .then((isSuccessful) {
                    Navigator.of(context).pop(isSuccessful);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: isSuccessful ? null : Colors.red,
                        content: Text(
                          isSuccessful
                              ? 'Request to ${_usernameFieldController.text} has been sent!'
                              : 'Request could not be sent: wrong username or user does not exist!',
                          style: isSuccessful ? null : const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                    if (isSuccessful) _usernameFieldController.clear();
                  });
                }
              },
            ),
          ],
        ),
      );
    });
  }
}
