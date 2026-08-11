import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LauncherDate extends StatelessWidget {
  const LauncherDate({super.key});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.now();

    return Text(
      DateFormat('EEEE, d MMMM').format(date),
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
    );
  }
}
