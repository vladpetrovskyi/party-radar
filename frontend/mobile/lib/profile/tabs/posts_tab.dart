import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:party_radar/profile/tabs/widgets/not_found_widget.dart';
import 'package:party_radar/common/post/post_widget.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/services/post_service.dart';
import 'package:party_radar/common/services/user_service.dart';

class UserPostsTab extends StatefulWidget {
  const UserPostsTab({super.key, required this.pageSize, this.onUpdate});

  final int pageSize;
  final Function()? onUpdate;

  @override
  State<UserPostsTab> createState() => _UserPostsTabState();
}

class _UserPostsTabState extends State<UserPostsTab> {
  final PagingController<int, Post> _postPagingController =
      PagingController(firstPageKey: 0);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        _postPagingController.refresh();
        widget.onUpdate?.call();
      },
      child: PagedListView<int, Post>(
        pagingController: _postPagingController,
        builderDelegate: PagedChildBuilderDelegate<Post>(
          itemBuilder: (context, item, index) {
            return PostWidget(
              title: item.location.name,
              subtitle: DateFormat("MMM d, HH:mm").format(item.timestamp),
              post: item,
              isEditable: true,
              onDelete: () {
                _postPagingController.refresh();
                widget.onUpdate?.call();
              },
            );
          },
          noItemsFoundIndicatorBuilder: (_) => const NotFoundWidget(
              title: 'No posts found', message: 'Pull down to refresh'),
        ),
      ),
    );
  }

  @override
  void initState() {
    FirebaseAnalytics.instance.logScreenView(screenName: 'User Posts', screenClass: 'Tab');

    _postPagingController.addPageRequestListener((pageKey) async {
      try {
        var user = await UserService.getUser();
        final newItems =
            await PostService.getUserPosts(pageKey, widget.pageSize, user?.id);
        final isLastPage = newItems.length < widget.pageSize;
        if (isLastPage) {
          _postPagingController.appendLastPage(newItems);
        } else {
          final nextPageKey = pageKey + newItems.length;
          _postPagingController.appendPage(newItems, nextPageKey);
        }
      } catch (error) {
        _postPagingController.error = error;
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _postPagingController.dispose();
    super.dispose();
  }
}
