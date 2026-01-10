import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled3/models/task_model.dart';
import 'package:untitled3/data/repositories/task_repository.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Not logged in"));

    return StreamBuilder<List<Task>>(
      // FIX: Point back to the personalTasks stream
      stream: TaskRepository(uid: user.uid).personalTasks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "No personal tasks yet. Add one in the 'My Tasks' tab!",
              style: GoogleFonts.poppins(),
            ),
          );
        }

        final tasks = snapshot.data!;
        final totalTasks = tasks.length;
        final doneTasks = tasks
            .where((task) => task.status == TaskStatus.done)
            .length;
        final progress = totalTasks > 0 ? doneTasks / totalTasks : 0.0;

        final priority1Tasks = tasks.where((t) => t.priority == 1).toList();
        final priority2Tasks = tasks.where((t) => t.priority == 2).toList();
        final priority3Tasks = tasks.where((t) => t.priority == 3).toList();

        final recentIncompleteTasks = tasks
            .where((t) => t.status != TaskStatus.done)
            .take(4)
            .toList();

        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildBarChartSection(tasks),
                const SizedBox(height: 30),
                _buildCircularProgressSection(
                  priority1Tasks,
                  priority2Tasks,
                  priority3Tasks,
                ),
                const SizedBox(height: 30),
                _buildOverallProgressSection(progress),
                const SizedBox(height: 30),
                _buildScheduleSection(recentIncompleteTasks),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBarChartSection(List<Task> tasks) {
    double totalByPriority(int priority) =>
        tasks.where((t) => t.priority == priority).length.toDouble();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (tasks.isNotEmpty ? tasks.length.toDouble() : 10),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(),
            topTitles: AxisTitles(),
            bottomTitles: AxisTitles(),
            rightTitles: AxisTitles(),
          ),
          barTouchData: BarTouchData(enabled: false),
          barGroups: [
            _makeBarGroup(0, totalByPriority(1), const Color(0xFF536DFE)),
            _makeBarGroup(1, totalByPriority(2), const Color(0xFF7C4DFF)),
            _makeBarGroup(2, totalByPriority(3), const Color(0xFFF06292)),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
      ],
    );
  }

  Widget _buildCircularProgressSection(
    List<Task> p1,
    List<Task> p2,
    List<Task> p3,
  ) {
    double getProgress(List<Task> taskList) {
      if (taskList.isEmpty) return 0.0;
      return taskList.where((t) => t.status == TaskStatus.done).length /
          taskList.length;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ProgressCircle(
          value: (getProgress(p1) * 100).toInt(),
          label: 'High',
          color: const Color(0xFF536DFE),
        ),
        _ProgressCircle(
          value: (getProgress(p2) * 100).toInt(),
          label: 'Medium',
          color: const Color(0xFF7C4DFF),
        ),
        _ProgressCircle(
          value: (getProgress(p3) * 100).toInt(),
          label: 'Low',
          color: const Color(0xFFF06292),
        ),
      ],
    );
  }

  Widget _buildOverallProgressSection(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Overall Progress",
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF7C4DFF),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Text(
              "${(progress * 100).toStringAsFixed(0)}%",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleSection(List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            "Pending Tasks",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                "No pending tasks. Great job!",
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ...tasks.map(
            (task) => _ScheduleTile(
              task: task.title,
              color: _getPriorityColorForTask(task),
            ),
          ),
      ],
    );
  }

  Color _getPriorityColorForTask(Task task) {
    switch (task.priority) {
      case 1:
        return const Color(0xFF536DFE).withValues(alpha: 0.8);
      case 2:
        return const Color(0xFF7C4DFF).withValues(alpha: 0.8);
      case 3:
        return const Color(0xFFF06292).withValues(alpha: 0.8);
      default:
        return Colors.grey.withValues(alpha: 0.8);
    }
  }
}

class _ProgressCircle extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _ProgressCircle({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 8,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  "$value%",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final String task;
  final Color color;

  const _ScheduleTile({required this.task, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        task,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}
