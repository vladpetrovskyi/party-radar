import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfoDialog extends StatelessWidget {
  const AppInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: title,
      children: [
        getText('Legal: '),
        const SizedBox(height: 12),
        getLink(
            '• Privacy policy', 'https://www.party-radar.app/privacy-policy'),
        const SizedBox(height: 6),
        getLink('• Terms and conditions',
            'https://www.party-radar.app/terms-and-conditions'),
        const SizedBox(height: 24),
        getText('Credits/Attributions:'),
        const SizedBox(height: 12),
        getCenteredLink('• User icons created by kmg design - Flaticon',
            'https://www.flaticon.com/free-icons/user'),
        const SizedBox(height: 6),
        getCenteredLink('• Radar icons created by Freepik - Flaticon',
            'https://www.flaticon.com/free-icons/radar'),
        const SizedBox(height: 12),
        getDialogOptionLink(
            'SEND A FEEDBACK', 'https://www.party-radar.app/contact'),
        getDialogOptionLink(
            'REPORT AN ERROR', 'https://www.party-radar.app/contact'),
        SimpleDialogOption(
          child: const Center(
            child: Text(
              'BACK',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget get title => const Center(
    child: Text(
      'Infos',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
  );

  Widget getText(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      text,
      style: const TextStyle(fontSize: 20),
    ),
  );

  Widget getLink(String label, String uri) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: InkWell(
        child: Text(label, style: const TextStyle(fontSize: 16)),
        onTap: () => launchUrl(Uri.parse(uri))),
  );

  Widget getCenteredLink(String label, String uri) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Center(
      child: InkWell(
          child: const Text('• User icons created by kmg design - Flaticon',
              style: TextStyle(fontSize: 16)),
          onTap: () => launchUrl(
              Uri.parse('https://www.flaticon.com/free-icons/user'))),
    ),
  );

  Widget getDialogOptionLink(String label, String uri) => SimpleDialogOption(
    child: Center(
      child: Text(
        label,
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ),
    onPressed: () => launchUrl(Uri.parse(uri)),
  );
}