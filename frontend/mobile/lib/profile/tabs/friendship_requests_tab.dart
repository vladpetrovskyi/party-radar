import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:party_radar/profile/tabs/widgets/friend_widget.dart';
import 'package:party_radar/profile/tabs/widgets/not_found_widget.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/services/friendship_service.dart';
import 'package:party_radar/common/services/image_service.dart';

class FriendshipRequestsTab extends StatefulWidget {
  const FriendshipRequestsTab(
      {super.key, required this.pageSize, this.updateTabCounter});

  final int pageSize;
  final Function()? updateTabCounter;

  @override
  State<FriendshipRequestsTab> createState() => _FriendshipRequestsTabState();
}

class _FriendshipRequestsTabState extends State<FriendshipRequestsTab> {
  final PagingController<int, Friendship> _friendshipRequestsPagingController =
      PagingController(firstPageKey: 0);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        _friendshipRequestsPagingController.refresh();
        widget.updateTabCounter?.call();
      },
      child: PagedListView<int, Friendship>(
        pagingController: _friendshipRequestsPagingController,
        builderDelegate: PagedChildBuilderDelegate<Friendship>(
          itemBuilder: (context, item, index) {
            return FutureBuilder(
              future: ImageService.getImage(item.friend.imageId, size: 50),
              builder: (context, snapshot) {
                return snapshot.hasData
                    ? FriendWidget(
                        padding: const EdgeInsets.symmetric(vertical: 7.25),
                        username: item.friend.username ?? '? ? ? ?',
                        image: snapshot.data!,
                        popupMenu: _getPopupMenu(item.id),
                      )
                    : Container();
              },
            );
          },
          noItemsFoundIndicatorBuilder: (_) => const NotFoundWidget(
              title: 'No requests found', message: 'Pull down to refresh'),
        ),
      ),
    );
  }

  PopupMenuButton _getPopupMenu(int friendshipId) {
    return PopupMenuButton<FriendshipStatus>(
      onSelected: (friendshipStatus) =>
          _updateFriendship(friendshipStatus, friendshipId),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<FriendshipStatus>>[
        const PopupMenuItem<FriendshipStatus>(
            value: FriendshipStatus.accepted, child: Text('Accept')),
        const PopupMenuItem<FriendshipStatus>(
            value: FriendshipStatus.rejected, child: Text('Decline')),
      ],
    );
  }

  void _updateFriendship(FriendshipStatus friendshipStatus, int friendshipId) {
    FriendshipService.updateFriendship(friendshipId, friendshipStatus)
        .then((isUpdated) {
      if (isUpdated) {
        _friendshipRequestsPagingController.refresh();
        widget.updateTabCounter?.call();
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
    });
  }

  @override
  void initState() {
    _friendshipRequestsPagingController.addPageRequestListener((pageKey) async {
      try {
        final newItems = await FriendshipService.getFriendships(
            FriendshipStatus.requested, pageKey, widget.pageSize);
        final isLastPage = newItems.length < widget.pageSize;
        if (isLastPage) {
          _friendshipRequestsPagingController.appendLastPage(newItems);
        } else {
          final nextPageKey = pageKey + newItems.length;
          _friendshipRequestsPagingController.appendPage(newItems, nextPageKey);
        }
      } catch (error) {
        _friendshipRequestsPagingController.error = error;
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _friendshipRequestsPagingController.dispose();
    super.dispose();
  }
}
