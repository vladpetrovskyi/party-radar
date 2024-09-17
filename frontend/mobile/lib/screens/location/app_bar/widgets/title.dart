import 'package:flutter/material.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:provider/provider.dart';

class AppBarTitle extends StatelessWidget {
  const AppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (_, provider, __) {
        if (provider.editMode) {
          final TextEditingController controller =
          TextEditingController(text: provider.rootLocation?.name);
          return TextFormField(
            controller: controller,
            onFieldSubmitted: (val) => _updateTitle(val, provider),
            onTapOutside: (_) {
              _updateTitle(controller.text, provider);
              FocusManager.instance.primaryFocus?.unfocus();
            },
            style: const TextStyle(
              fontSize: 28,
            ),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color.fromRGBO(119, 136, 153, 0.05),
              border: UnderlineInputBorder(),
              isCollapsed: true,
            ),
          );
        }

        return SizedBox(
          height: 40,
          child: Hero(
            tag: 'logo_hero',
            child: Image.asset('assets/logo_app_bar.png'),
          ),
        );
      },
    );
  }

  void _updateTitle(String newTitle, LocationProvider provider) {
    var rootLocation = provider.rootLocation;
    if (rootLocation != null && rootLocation.name != newTitle) {
      rootLocation.name = newTitle;
      LocationService.updateLocation(rootLocation)
          .then((updated) => provider.loadRootLocation(reloadCurrent: true));
    }
  }
}
