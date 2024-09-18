import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:party_radar/models/friendship.dart';
import 'package:party_radar/screens/user_profile/tabs/widgets/friend_card.dart';
import 'package:party_radar/widgets/error_snack_bar.dart';
import 'package:party_radar/widgets/not_found_widget.dart';

import '../../../services/friendship_service.dart';

class FriendshipTab extends StatefulWidget {
  const FriendshipTab({
    super.key,
    required this.pageSize,
    this.onUpdate,
    required this.friendshipStatus,
    this.cardPadding,
    this.showLocation = false,
    required this.getPopupMenu,
  });

  final int pageSize;
  final Function()? onUpdate;
  final FriendshipStatus friendshipStatus;
  final EdgeInsetsGeometry? cardPadding;
  final bool showLocation;
  final Function(int, Function(FriendshipStatus, int)) getPopupMenu;

  @override
  State<FriendshipTab> createState() => _FriendshipTabState();
}

class _FriendshipTabState extends State<FriendshipTab> with ErrorSnackBar {
  final PagingController<int, Friendship> _friendshipPagingController =
      PagingController(firstPageKey: 0);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        _friendshipPagingController.refresh();
        widget.onUpdate?.call();
      },
      child: PagedListView<int, Friendship>(
        pagingController: _friendshipPagingController,
        builderDelegate: PagedChildBuilderDelegate<Friendship>(
          itemBuilder: (context, item, index) {
            return FriendCard(
              imageId: item.friend.imageId,
              username: item.friend.username,
              subtitle: widget.showLocation && item.friend.locationName != null
                  ? Text('📍 ${item.friend.locationName!}')
                  : const Text('Offline 😴'),
              padding: widget.cardPadding ?? EdgeInsets.zero,
              popupMenu: widget.getPopupMenu(item.id, _updateFriendshipStatus),
            );
          },
          noItemsFoundIndicatorBuilder: (_) => const NotFoundWidget(
              title: 'Nothing found', message: 'Pull down to refresh'),
        ),
      ),
    );
  }

  _updateFriendshipStatus(FriendshipStatus friendshipStatus, int friendshipId) {
    if (friendshipStatus == FriendshipStatus.rejected) {
      FriendshipService.deleteFriendship(friendshipId).then(
        (isDeleted) {
          if (isDeleted) {
            _friendshipPagingController.refresh();
            widget.onUpdate?.call();
          } else {
            showErrorSnackBar(
                'Could not update the friendship status, please retry',
                context);
          }
        },
      );
    }

    FriendshipService.updateFriendship(friendshipId, friendshipStatus)
        .then((isUpdated) {
      if (isUpdated) {
        _friendshipPagingController.refresh();
        widget.onUpdate?.call();
      } else {
        showErrorSnackBar(
            'Could not update the friendship status, please retry', context);
      }
    });
  }

  @override
  void initState() {
    _friendshipPagingController.addPageRequestListener((pageKey) async {
      try {
        final newItems = await FriendshipService.getFriendships(
            widget.friendshipStatus, pageKey, widget.pageSize);
        final isLastPage = newItems.length < widget.pageSize;
        if (isLastPage) {
          _friendshipPagingController.appendLastPage(newItems);
        } else {
          final nextPageKey = pageKey + newItems.length;
          _friendshipPagingController.appendPage(newItems, nextPageKey);
        }
      } catch (error) {
        _friendshipPagingController.error = error;
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _friendshipPagingController.dispose();
    super.dispose();
  }
}
