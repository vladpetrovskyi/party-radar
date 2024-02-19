import 'dart:async';

import 'package:flutter/material.dart';

class ElapsedTime extends StatefulWidget {
  final String timestamp;

  const ElapsedTime({
    super.key,
    required this.timestamp,
  });

  @override
  State<ElapsedTime> createState() => _ElapsedTimeState();
}

class _ElapsedTimeState extends State<ElapsedTime> {
  late Timer _timer;

  late DateTime _initialTime;
  late String _currentDuration;


  @override
  void didUpdateWidget(ElapsedTime oldWidget) {
    super.didUpdateWidget(oldWidget);

    if(widget.timestamp != oldWidget.timestamp) {
      _initialTime = _parseTimestamp();
      _currentDuration = _formatDuration(_calcElapsedTime());
    }
  }

  @override
  void initState() {
    super.initState();

    _initialTime = _parseTimestamp();
    _currentDuration = _formatDuration(_calcElapsedTime());

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        _currentDuration = _formatDuration(_calcElapsedTime());
      });
    });
  }

  Duration _calcElapsedTime() => _initialTime.difference(DateTime.now());

  DateTime _parseTimestamp() => DateTime.parse(widget.timestamp);

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _timer.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_currentDuration, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),);
  }
}
