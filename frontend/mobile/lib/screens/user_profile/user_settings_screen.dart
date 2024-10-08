import 'package:flutter/material.dart';
import 'package:party_radar/screens/user_profile/dialogs/delete_account_dialog.dart';
import 'package:party_radar/services/user_service.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  List<String> _enabled = [];

  @override
  void initState() {
    super.initState();
    UserService.getUserTopics()
        .then((topics) => setState(() => _enabled = topics));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            Text(
              "Notifications",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Divider(),
            ListTile(
              title: const Text("Friendship requests"),
              subtitle:
                  const Text("Get notifications about new friendship requests"),
              trailing: getSwitch('friendship-requests', true),
            ),
            ListTile(
              title: const Text("Location availability updates"),
              subtitle: const Text(
                  "Get notifications when locations are marked as closed / opened"),
              trailing: getSwitch('location-availability', true),
            ),
            ListTile(
              title: const Text("New posts"),
              subtitle: const Text(
                  "Get notifications about new posts at the club you're currently at"),
              trailing: getSwitch('new-posts', true),
            ),
            // TODO: activate after this function is available
            // ListTile(
            //   enabled: false,
            //   title: const Text("Tags"),
            //   subtitle: const Text("Get notifications when you are tagged in posts"),
            //   trailing: getSwitch('post-tags', false),
            // ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return const DeleteAccountDialog();
                    });
              },
              child: const Text('Delete account'),
            )
          ],
        ),
      ),
    );
  }

  Widget getSwitch(String notificationType, bool isActive) => Switch(
        onChanged: isActive
            ? (bool? value) {
                if (value != null) {
                  if (value) {
                    UserService.subscribeToTopic(notificationType);
                    setState(() {
                      _enabled.add(notificationType);
                    });
                  } else {
                    UserService.unsubscribeFromTopic(notificationType);
                    setState(() {
                      _enabled.remove(notificationType);
                    });
                  }
                }
              }
            : null,
        value: _enabled.contains(notificationType),
      );
}
