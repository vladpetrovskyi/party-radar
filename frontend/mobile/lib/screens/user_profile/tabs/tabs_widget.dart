import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/models/friendship.dart';
import 'package:party_radar/screens/user_profile/tabs/friendship_tab.dart';
import 'package:party_radar/screens/user_profile/tabs/posts_tab.dart';
import 'package:party_radar/services/friendship_service.dart';
import 'package:party_radar/services/post_service.dart';

class ProfileTabsWidget extends StatefulWidget {
  const ProfileTabsWidget(
      {super.key, required this.tabController, this.initialIndex = 0});

  final TabController tabController;
  final int initialIndex;

  @override
  State<ProfileTabsWidget> createState() => _ProfileTabsWidgetState();
}

class _ProfileTabsWidgetState extends State<ProfileTabsWidget> {
  static const _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: widget.tabController,
            tabs: [
              Tab(
                child: FutureBuilder(
                    future: PostService.getPostCount(
                        FirebaseAuth.instance.currentUser?.displayName),
                    builder: (context, snapshot) {
                      return _TabText(
                          title: snapshot.hasData ? '${snapshot.data} ' : '',
                          subtitle: 'Post${snapshot.data == 1 ? '' : 's'}');
                    }),
              ),
              Tab(
                child: FutureBuilder(
                  future: FriendshipService.getFriendshipsCount(
                      FriendshipStatus.accepted),
                  builder: (context, snapshot) {
                    return _TabText(
                        title: snapshot.hasData ? '${snapshot.data} ' : '',
                        subtitle: 'Friend${snapshot.data == 1 ? '' : 's'}');
                  },
                ),
              ),
              Tab(
                child: FutureBuilder(
                  future: FriendshipService.getFriendshipsCount(
                      FriendshipStatus.requested),
                  builder: (context, snapshot) {
                    return _TabText(
                        title: snapshot.hasData ? '${snapshot.data} ' : '',
                        subtitle: 'Request${snapshot.data == 1 ? '' : 's'}');
                  },
                ),
              ),
            ],
          ),
          Flexible(
            child: TabBarView(
              controller: widget.tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                UserPostsTab(pageSize: _pageSize, onUpdate: () => _refresh()),
                FriendshipTab(
                  pageSize: _pageSize,
                  friendshipStatus: FriendshipStatus.accepted,
                  showLocation: true,
                  onUpdate: () => _refresh(),
                  getPopupMenu: (id, updateFriendship) =>
                      _getFriendshipTabPopupMenu(id, updateFriendship),
                ),
                FriendshipTab(
                  pageSize: _pageSize,
                  friendshipStatus: FriendshipStatus.requested,
                  cardPadding: const EdgeInsets.symmetric(vertical: 7.25),
                  onUpdate: () => _refresh(),
                  getPopupMenu: (id, updateFriendship) =>
                      _getFriendshipRequestTabPopupMenu(id, updateFriendship),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuButton _getFriendshipTabPopupMenu(
      int friendshipId, Function(FriendshipStatus, int) updateFriendship) {
    return PopupMenuButton<FriendshipStatus>(
      onSelected: (FriendshipStatus friendshipStatus) =>
          updateFriendship(friendshipStatus, friendshipId),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<FriendshipStatus>>[
        const PopupMenuItem<FriendshipStatus>(
          value: FriendshipStatus.rejected,
          child: Text('Delete'),
        ),
      ],
    );
  }

  PopupMenuButton _getFriendshipRequestTabPopupMenu(
      int friendshipId, Function(FriendshipStatus, int) updateFriendship) {
    return PopupMenuButton<FriendshipStatus>(
      onSelected: (friendshipStatus) =>
          updateFriendship(friendshipStatus, friendshipId),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<FriendshipStatus>>[
        const PopupMenuItem<FriendshipStatus>(
            value: FriendshipStatus.accepted, child: Text('Accept')),
        const PopupMenuItem<FriendshipStatus>(
            value: FriendshipStatus.rejected, child: Text('Decline')),
      ],
    );
  }

  void _refresh() => setState(() {});
}

class _TabText extends StatelessWidget {
  const _TabText({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
