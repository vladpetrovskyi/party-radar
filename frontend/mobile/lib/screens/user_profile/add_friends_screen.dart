import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:party_radar/models/user.dart';
import 'package:party_radar/screens/user_profile/widgets/friend_tile.dart';
import 'package:party_radar/services/user_service.dart';
import 'package:party_radar/widgets/not_found_widget.dart';

class AddFriendsScreen extends StatefulWidget {
  const AddFriendsScreen({super.key});

  @override
  State<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  String _usernameQuery = '';

  static const _pageSize = 10;

  final PagingController<int, User> _friendsPagingController =
      PagingController(firstPageKey: 0);
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void dispose() {
    _friendsPagingController.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _friendsPagingController.addPageRequestListener((pageKey) async {
      try {
        final newItems =
            await UserService.getUsers(_usernameQuery, pageKey, _pageSize);
        final isLastPage = newItems.length < _pageSize;
        if (isLastPage) {
          _friendsPagingController.appendLastPage(newItems);
        } else {
          final nextPageKey = pageKey + newItems.length;
          _friendsPagingController.appendPage(newItems, nextPageKey);
        }
      } catch (error) {
        _friendsPagingController.error = error;
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
          _friendsPagingController.refresh();
        },
        child: PagedListView<int, User>(
          pagingController: _friendsPagingController,
          builderDelegate: PagedChildBuilderDelegate<User>(
            itemBuilder: (context, item, index) {
              return FriendWidget(
                imageId: item.imageId,
                username: item.username!,
                subtitle: item.locationName != null
                    ? Text('📍 ${item.locationName!}')
                    : null,
                padding: EdgeInsets.zero,
              );
            },
            noItemsFoundIndicatorBuilder: (_) => const NotFoundWidget(
              title: 'No users found',
              message: 'Pull down to refresh',
            ),
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() => AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          enabled: _usernameQuery.isNotEmpty
              ? true
              : _friendsPagingController.itemList?.isNotEmpty,
          controller: _textEditingController,
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            _usernameQuery = value;
            _friendsPagingController.refresh();
          },
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: const InputDecoration(
            hintText: 'Search friends by username...',
            fillColor: Colors.white,
          ),
        ),
      );
}
