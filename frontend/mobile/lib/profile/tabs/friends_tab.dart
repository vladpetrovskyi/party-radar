import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:party_radar/profile/tabs/widgets/not_found_widget.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/profile/tabs/widgets/friend_widget.dart';
import 'package:party_radar/common/services/friendship_service.dart';
import 'package:party_radar/common/services/image_service.dart';

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key, required this.pageSize, this.onUpdate});

  final int pageSize;
  final Function()? onUpdate;

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final PagingController<int, Friendship> _friendshipsPagingController =
      PagingController(firstPageKey: 0);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        _friendshipsPagingController.refresh();
        widget.onUpdate?.call();
      },
      child: PagedListView<int, Friendship>(
        pagingController: _friendshipsPagingController,
        builderDelegate: PagedChildBuilderDelegate<Friendship>(
          itemBuilder: (context, item, index) {
            return FutureBuilder(
                future: ImageService.getImage(item.friend.imageId, size: 50),
                builder: (context, snapshot) {
                  return snapshot.hasData
                      ? FriendWidget(
                          image: snapshot.data,
                          username: item.friend.username!,
                          subtitle: item.friend.locationName != null
                              ? Text('📍 ${item.friend.locationName!}')
                              : const Text('Offline 😴'),
                          popupMenu: _getPopupMenu(item.id),
                        )
                      : Container();
                });
          },
          noItemsFoundIndicatorBuilder: (_) => const NotFoundWidget(
              title: 'No friends found', message: 'Pull down to refresh'),
        ),
      ),
    );
  }

  PopupMenuButton _getPopupMenu(int friendshipId) {
    return PopupMenuButton<FriendshipStatus>(
      onSelected: (FriendshipStatus friendshipStatus) =>
          _updateFriendshipStatus(friendshipStatus, friendshipId),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<FriendshipStatus>>[
        const PopupMenuItem<FriendshipStatus>(
          value: FriendshipStatus.rejected,
          child: Text('Delete'),
        ),
      ],
    );
  }

  _updateFriendshipStatus(FriendshipStatus friendshipStatus, int friendshipId) {
    if (friendshipStatus == FriendshipStatus.rejected) {
      FriendshipService.deleteFriendship(friendshipId).then(
        (value) {
          if (value) {
            _friendshipsPagingController.refresh();
            widget.onUpdate?.call();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.red,
                content: Text(
                  'Could not update the friendship status, please retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }
        },
      );
    }
  }

  @override
  void initState() {
    _friendshipsPagingController.addPageRequestListener((pageKey) async {
      try {
        final newItems = await FriendshipService.getFriendships(
            FriendshipStatus.accepted, pageKey, widget.pageSize);
        final isLastPage = newItems.length < widget.pageSize;
        if (isLastPage) {
          _friendshipsPagingController.appendLastPage(newItems);
        } else {
          final nextPageKey = pageKey + newItems.length;
          _friendshipsPagingController.appendPage(newItems, nextPageKey);
        }
      } catch (error) {
        _friendshipsPagingController.error = error;
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _friendshipsPagingController.dispose();
    super.dispose();
  }
}
