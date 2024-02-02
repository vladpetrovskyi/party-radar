import 'package:flutter/material.dart';

class NoItemsFoundView extends StatelessWidget {
  const NoItemsFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    return  Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 32,
          horizontal: 16,
        ),
        child: Column(
          children: [
            Text(
              'No posts found',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(
              height: 16,
            ),
            const Text(
              'Add friends on your profile page or pull down to refresh',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}