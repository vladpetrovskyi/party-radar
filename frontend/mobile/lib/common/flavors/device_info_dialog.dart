import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/common/flavors/device_utils.dart';
import 'package:party_radar/common/flavors/flavor_config.dart';

class DeviceInfoDialog extends StatelessWidget {
  const DeviceInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.only(bottom: 10.0),
      title: Container(
        padding: const EdgeInsets.all(15.0),
        color: FlavorConfig.instance.color,
        child: const Text(
          'Device Info',
          style: TextStyle(color: Colors.white),
        ),
      ),
      titlePadding: const EdgeInsets.all(0),
      content: _getContent(),
    );
  }

  Widget _getContent() {
    if (Platform.isAndroid) {
      return _androidContent();
    }
    if (Platform.isIOS) {
      return _iOSContent();
    }
    return const Text("You're not on Android neither iOS");
  }

  Widget _iOSContent() {
    return FutureBuilder(
        future: DeviceUtils.iosDeviceInfo(),
        builder: (context, AsyncSnapshot<IosDeviceInfo> snapshot) {
          if (!snapshot.hasData) return Container();

          IosDeviceInfo device = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                _buildTile('Flavor:', FlavorConfig.instance.name),
                _buildTile('Build mode:', DeviceUtils.currentBuildMode().toString()),
                _buildTile('Physical device?:', device.isPhysicalDevice.toString()),
                _buildTile('Device:', device.name),
                _buildTile('Model:', device.model),
                _buildTile('System name:', device.systemName),
                _buildTile('System version:', device.systemVersion)
              ],
            ),
          );
        });
  }

  Widget _androidContent() {
    return FutureBuilder(
        future: DeviceUtils.androidDeviceInfo(),
        builder: (context, AsyncSnapshot<AndroidDeviceInfo> snapshot) {
          if (!snapshot.hasData) return Container();
          AndroidDeviceInfo device = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                _buildTile('Flavor:', FlavorConfig.instance.name),
                _buildTile('Build mode:', DeviceUtils.currentBuildMode().name),
                _buildTile('Physical device?:', '${device.isPhysicalDevice}'),
                _buildTile('Manufacturer:', device.manufacturer),
                _buildTile('Model:', device.model),
                _buildTile('Android version:', device.version.release),
                _buildTile('Android SDK:', '${device.version.sdkInt}')
              ],
            ),
          );
        });
  }

  Widget _buildTile(String key, String value) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Row(
        children: <Widget>[
          Text(
            key,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value)
        ],
      ),
    );
  }
}
