import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CountdownTimerWidget extends StatefulWidget {
  final DateTime? dueDate;
  final bool isOverdue;

  const CountdownTimerWidget({
    super.key,
    required this.dueDate,
    required this.isOverdue,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Duration? _remaining;
  late DateTime _lastUpdate;

  @override
  void initState() {
    super.initState();
    _lastUpdate = DateTime.now();
    _updateRemaining();
    // Update every second
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _updateRemaining();
        });
        _startTimer();
      }
    });
  }

  void _updateRemaining() {
    if (widget.dueDate == null) {
      _remaining = null;
      return;
    }
    final now = DateTime.now();
    if (widget.dueDate!.isBefore(now)) {
      _remaining = null;
      return;
    }
    _remaining = widget.dueDate!.difference(now);
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dueDate == null) {
      return const SizedBox.shrink();
    }

    if (widget.isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade700),
            const SizedBox(width: 4),
            Text(
              'QUÁ HẠN',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (_remaining == null) {
      return const SizedBox.shrink();
    }

    final isUrgent = _remaining!.inHours < 24;
    final isVeryUrgent = _remaining!.inHours < 6;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isVeryUrgent
            ? Colors.orange.shade50
            : isUrgent
                ? Colors.yellow.shade50
                : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isVeryUrgent
              ? Colors.orange
              : isUrgent
                  ? Colors.orange.shade300
                  : Colors.blue.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVeryUrgent ? Icons.timer_off : Icons.timer,
            size: 14,
            color: isVeryUrgent
                ? Colors.orange.shade700
                : isUrgent
                    ? Colors.orange.shade600
                    : Colors.blue.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDuration(_remaining!),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isVeryUrgent
                  ? Colors.orange.shade700
                  : isUrgent
                      ? Colors.orange.shade600
                      : Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
