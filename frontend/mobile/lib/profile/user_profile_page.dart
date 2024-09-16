import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/common/flavors/flavor_config.dart';
import 'package:party_radar/profile/dialogs/friendship_request.dart';
import 'package:party_radar/profile/edit_profile_page.dart';
import 'package:party_radar/profile/tabs/tabs_widget.dart';
import 'package:party_radar/profile/widgets/appbar_widget.dart';
import 'package:party_radar/profile/widgets/profile_widget.dart';
import 'package:party_radar/common/services/image_service.dart';
import 'package:party_radar/common/services/user_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({
    super.key,
    this.initialTabIndex = 0,
    this.onTabChanged
  });

  final int initialTabIndex;
  final Function(int)? onTabChanged;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      widget.onTabChanged?.call(_tabController.index);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Cannot load the page'));
          } else {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
                return const CircularProgressIndicator();
              case ConnectionState.active:
              case ConnectionState.done:
                var user = snapshot.data;
                return FutureBuilder(
                  future: _getProfilePicture(),
                  builder: (context, imageSnapshot) {
                    bool usernameExists = user?.displayName != null &&
                        user!.displayName!.isNotEmpty;
                    if (imageSnapshot.hasData) {
                      return Column(
                        children: [
                          ProfileWidget(
                            image: imageSnapshot.data,
                            onClicked: () => _openEditPage(imageSnapshot.data!),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () {
                              if (!usernameExists) {
                                _openEditPage(imageSnapshot.data!);
                              }
                            },
                            child: Text(
                              usernameExists
                                  ? user.displayName!
                                  : 'Add username...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: user?.displayName != null
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Expanded(
                              child: ProfileTabsWidget(
                                  tabController: _tabController)),
                        ],
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                );
            }
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: FirebaseAuth.instance.currentUser?.displayName != null
            ? () {
                showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return const FriendshipRequestDialog();
                  },
                ).then((value) {
                  if (value != null && value) setState(() {});
                });
              }
            : () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(
                      'Please select a username first!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
        child: const Icon(Icons.person_add_alt_outlined),
      ),
    );
  }

  Future<Image?> _getProfilePicture() async {
    var user = await UserService.getUser();
    return ImageService.get(user?.imageId, size: 128);
  }

  _openEditPage(Image image) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null &&
        (currentUser.emailVerified ||
            FlavorConfig.instance.flavor != Flavor.prod)) {
      Navigator.of(context)
          .push(MaterialPageRoute(
        builder: (context) => EditProfilePage(image: image),
      ))
          .then((value) {
        setState(() {});
      });
    } else if (currentUser != null &&
        !currentUser.emailVerified &&
        FlavorConfig.instance.flavor == Flavor.prod) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email address'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Internal error'),
        ),
      );
    }
  }
}
