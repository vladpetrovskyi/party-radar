import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/flavors/flavor_config.dart';
import 'package:party_radar/screens/user_profile/dialogs/friendship_request.dart';
import 'package:party_radar/screens/user_profile/edit_profile_screen.dart';
import 'package:party_radar/screens/user_profile/tabs/tabs_widget.dart';
import 'package:party_radar/screens/user_profile/widgets/appbar_widget.dart';
import 'package:party_radar/screens/user_profile/widgets/profile_widget.dart';
import 'package:party_radar/services/image_service.dart';
import 'package:party_radar/services/user_service.dart';
import 'package:party_radar/widgets/error_snack_bar.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen(
      {super.key, this.initialTabIndex = 0, this.onTabChanged});

  final int initialTabIndex;
  final Function(int)? onTabChanged;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin, ErrorSnackBar {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTabIndex);
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
                return FutureBuilder(
                  future: _getProfilePicture(),
                  builder: (context, imageSnapshot) {
                    if (imageSnapshot.hasData) {
                      return Column(
                        children: [
                          ProfileWidget(
                            image: imageSnapshot.data,
                            onClicked: () => _openEditPage(imageSnapshot.data!),
                          ),
                          const SizedBox(height: 24),
                          _username(snapshot.data, imageSnapshot.data!),
                          const SizedBox(height: 18),
                          Expanded(
                            child: ProfileTabsWidget(
                                tabController: _tabController),
                          ),
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
      floatingActionButton: _getFloatingActionButton(),
    );
  }

  Widget _username(User? user, Image image) {
    bool usernameExists =
        user?.displayName != null && user!.displayName!.isNotEmpty;
    return GestureDetector(
      onTap: () {
        if (!usernameExists) {
          _openEditPage(image);
        }
      },
      child: Text(
        usernameExists ? user.displayName! : 'Add username...',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: user?.displayName != null ? Colors.white : Colors.grey,
        ),
      ),
    );
  }

  Widget _getFloatingActionButton() => FloatingActionButton(
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
      );

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
          .push(
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(image: image),
            ),
          )
          .then((value) => setState(() {}));
    } else if (currentUser != null &&
        !currentUser.emailVerified &&
        FlavorConfig.instance.flavor == Flavor.prod) {
      showErrorSnackBar('Please verify your email address', context);
    } else {
      showErrorSnackBar('Internal error', context);
    }
  }
}
