import 'package:flutter/foundation.dart';
import 'package:untitled3/data/repositories/project_repository.dart';
import 'package:untitled3/models/project_model.dart';

/// Provider for managing project data with real-time updates
class ProjectProvider with ChangeNotifier {
  final ProjectRepository _repository;
  List<Project> _projects = [];
  bool _isLoading = true;
  String? _error;

  ProjectProvider(this._repository) {
    _init();
  }

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get projectCount => _projects.length;

  void _init() {
    _repository.getProjects().listen(
      (projects) {
        _projects = projects;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Get active projects (with deadline in the future or no deadline)
  List<Project> get activeProjects {
    final now = DateTime.now();
    return _projects.where((project) {
      if (project.deadline == null) return true;
      return project.deadline!.isAfter(now);
    }).toList();
  }

  /// Get overdue projects
  List<Project> get overdueProjects {
    final now = DateTime.now();
    return _projects.where((project) {
      if (project.deadline == null) return false;
      return project.deadline!.isBefore(now);
    }).toList();
  }

  /// Get project by ID
  Project? getProjectById(String id) {
    try {
      return _projects.firstWhere((project) => project.id == id);
    } catch (e) {
      return null;
    }
  }
}
