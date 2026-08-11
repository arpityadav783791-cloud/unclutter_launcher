import 'package:flutter/material.dart';

import '../../apps/models/app_model.dart';

class LauncherAppList extends StatelessWidget {
  final List<AppModel> apps;

  const LauncherAppList({super.key, required this.apps});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            app.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
          ),
        );
      },
    );
  }
}
