import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/profile/tabs/friends_tab.dart';
import 'package:party_radar/profile/tabs/friendship_requests_tab.dart';
import 'package:party_radar/profile/tabs/posts_tab.dart';
import 'package:party_radar/common/services/friendship_service.dart';
import 'package:party_radar/common/services/post_service.dart';

class ProfileTabsWidget extends StatefulWidget {
  const ProfileTabsWidget({super.key, required this.tabController, this.initialIndex = 0});

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
                    future: PostService.getPostCount(FirebaseAuth.instance.currentUser?.displayName),
                    builder: (context, snapshot) {
                      return _getTabText(
                          snapshot.hasData ? '${snapshot.data} ' : '',
                          'Post${snapshot.data == 1 ? '' : 's'}');
                    }),
              ),
              Tab(
                child: FutureBuilder(
                  future: FriendshipService.getFriendshipsCount(FriendshipStatus.accepted),
                  builder: (context, snapshot) {
                    return _getTabText(
                        snapshot.hasData ? '${snapshot.data} ' : '',
                        'Friend${snapshot.data == 1 ? '' : 's'}');
                  },
                ),
              ),
              Tab(
                child: FutureBuilder(
                  future:
                      FriendshipService.getFriendshipsCount(FriendshipStatus.requested),
                  builder: (context, snapshot) {
                    return _getTabText(
                        snapshot.hasData ? '${snapshot.data} ' : '',
                        'Request${snapshot.data == 1 ? '' : 's'}');
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
                FriendsTab(pageSize: _pageSize, onUpdate: () => _refresh()),
                FriendshipRequestsTab(pageSize: _pageSize, onUpdate: () => _refresh()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _refresh() {
    setState(() {});
  }

  Row _getTabText(String value, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          text,
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
