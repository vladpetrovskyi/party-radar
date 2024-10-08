import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:party_radar/widgets/not_found_widget.dart';
import 'package:party_radar/widgets/post_widget.dart';
import 'package:party_radar/models/post.dart';
import 'package:party_radar/services/post_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.locationId});

  final int locationId;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _usernameQuery = '';

  static const _pageSize = 10;

  final TextEditingController _textEditingController = TextEditingController();

  final PagingController<int, Post> _feedPagingController =
      PagingController(firstPageKey: 0);

  @override
  void dispose() {
    _feedPagingController.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _feedPagingController.addPageRequestListener((pageKey) async {
      try {
        final newItems = await PostService.getFeed(
            pageKey, _pageSize, _usernameQuery, widget.locationId);
        final isLastPage = newItems.length < _pageSize;
        setState(() {
          if (isLastPage) {
            _feedPagingController.appendLastPage(newItems);
          } else {
            final nextPageKey = pageKey + newItems.length;
            _feedPagingController.appendPage(newItems, nextPageKey);
          }
        });
      } catch (error) {
        _feedPagingController.error = error;
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          _feedPagingController.refresh();
        },
        child: PagedListView<int, Post>(
          pagingController: _feedPagingController,
          builderDelegate: PagedChildBuilderDelegate<Post>(
            itemBuilder: (context, item, index) {
              return PostWidget(
                title: item.username!,
                subtitle: _getTimestampString(item.timestamp),
                post: item,
                showImage: true,
                updateViewsCounter: true,
              );
            },
            noItemsFoundIndicatorBuilder: (_) => const NotFoundWidget(
              title: 'No posts found',
              message:
                  'Add friends on your profile page or pull down to refresh',
            ),
          ),
        ),
      ),
    );
  }

  String _getTimestampString(DateTime dateTime) {
    Duration postTime = DateTime.now().difference(dateTime.toLocal());
    if (postTime.inDays > 3) {
      return DateFormat("MMM d").format(dateTime.toLocal());
    } else if (postTime.inMinutes > 60) {
      return "${postTime.inHours} hour${postTime.inHours == 1 ? '' : 's'} ago";
    } else if (postTime.inMinutes > 0) {
      return '${postTime.inMinutes} min. ago';
    }
    return 'now';
  }

  AppBar buildAppBar() {
    return AppBar(
      title: TextField(
        enabled: _usernameQuery.isNotEmpty
            ? true
            : _feedPagingController.itemList?.isNotEmpty ?? false,
        controller: _textEditingController,
        style: const TextStyle(color: Colors.white),
        onChanged: (value) {
          _usernameQuery = value;
          _feedPagingController.refresh();
        },
        decoration: const InputDecoration(
          hintText: 'Filter by username...',
          fillColor: Colors.white,
          prefixIcon: Icon(
            Icons.search,
          ),
        ),
      ),
    );
  }
}
