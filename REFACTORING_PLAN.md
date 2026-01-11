# 🔧 KẾ HOẠCH REFACTORING CHI TIẾT

## 📋 TỔNG QUAN

Kế hoạch này chia refactoring thành **4 Phases** có thể thực hiện độc lập, theo thứ tự ưu tiên từ cao đến thấp.

---

## 🎯 PHASE 1: TÁCH DATABASE SERVICE (2-3 ngày)

### Mục tiêu:
Tách `database_service.dart` (850 dòng) thành các Repository nhỏ hơn, dễ quản lý.

### Các bước thực hiện:

#### **Bước 1.1: Tạo cấu trúc thư mục mới**

```bash
mkdir -p lib/data/repositories
mkdir -p lib/data/datasources/firebase
```

#### **Bước 1.2: Tạo User Repository**

**File mới:** `lib/data/repositories/user_repository.dart`

```dart
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/user_model.dart';

class UserRepository {
  final String? uid;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  UserRepository({this.uid});
  
  DatabaseReference get _usersRef => _database.ref('users');
  DatabaseReference? get userRef => uid != null ? _usersRef.child(uid!) : null;
  
  // Di chuyển các methods từ DatabaseService:
  // - createNewUser()
  // - updateUserData()
  // - updateUserAvatar()
  // - userData (Stream)
  // - getProjectMembers()
}
```

**Các methods cần di chuyển từ `database_service.dart`:**
- Lines 33-45: `createNewUser()`
- Lines 47-62: `updateUserData()`
- Lines 64-69: `updateUserAvatar()`
- Lines 71-86: `userData` getter
- Lines 88-102: `getProjectMembers()`

#### **Bước 1.3: Tạo Project Repository**

**File mới:** `lib/data/repositories/project_repository.dart`

```dart
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/project_model.dart';

class ProjectRepository {
  final String? uid;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  ProjectRepository({this.uid});
  
  DatabaseReference get _projectsRef => _database.ref('projects');
  
  // Di chuyển các methods từ DatabaseService:
  // - createProject()
  // - joinProjectByCode()
  // - getProjects()
  // - getProjectById()
  // - removeMember()
  // - updateMemberRole()
  // - toggleProjectLock()
  // - deleteProject()
  // - _generateJoinCode() (private helper)
}
```

**Các methods cần di chuyển:**
- Lines 106-112: `_generateJoinCode()`
- Lines 114-139: `createProject()`
- Lines 141-172: `joinProjectByCode()`
- Lines 174-202: `getProjects()`
- Lines 204-213: `getProjectById()`
- Lines 215-221: `removeMember()`
- Lines 223-231: `updateMemberRole()`
- Lines 233-235: `toggleProjectLock()`
- Lines 237-239: `deleteProject()`

#### **Bước 1.4: Tạo Sprint Repository**

**File mới:** `lib/data/repositories/sprint_repository.dart`

```dart
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/sprint_model.dart';

class SprintRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  DatabaseReference get _sprintsRef => _database.ref('sprints');
  
  // Di chuyển các methods từ DatabaseService:
  // - addSprint()
  // - addSprintWithGoal()
  // - updateSprintStatus()
  // - updateSprintPriority()
  // - updateSprintGoal()
  // - getSprints()
  // - checkAndUpdateSprintStatuses()
}
```

**Các methods cần di chuyển:**
- Lines 317-332: `addSprint()`
- Lines 632-651: `addSprintWithGoal()`
- Lines 334-338: `updateSprintStatus()`
- Lines 340-342: `updateSprintPriority()`
- Lines 620-629: `updateSprintGoal()`
- Lines 344-363: `getSprints()`
- Lines 365-386: `checkAndUpdateSprintStatuses()`

#### **Bước 1.5: Tạo Task Repository**

**File mới:** `lib/data/repositories/task_repository.dart`

```dart
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/task_model.dart';
import 'package:untitled3/models/project_task_model.dart';

class TaskRepository {
  final String? uid;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  TaskRepository({this.uid});
  
  DatabaseReference get _tasksRef => _database.ref('tasks');
  DatabaseReference? get personalTasksRef => 
      uid != null ? _database.ref('users').child(uid!).child('personal_tasks') : null;
  
  // Personal Tasks
  // - personalTasks (Stream)
  // - addPersonalTask()
  // - updatePersonalTaskStatus()
  // - updatePersonalTaskEvidence()
  // - deletePersonalTask()
  
  // Project Tasks
  // - addProjectTask()
  // - updateProjectTaskAssignee()
  // - updateProjectTaskStatus()
  // - updateProjectTaskEvidence()
  // - getProjectTasksByStory()
  // - getProjectTasks()
  // - updateTaskDoDChecklist()
}
```

**Các methods cần di chuyển:**
- Lines 243-257: `personalTasks` getter
- Lines 259-282: `addPersonalTask()`
- Lines 284-294: `updatePersonalTaskStatus()`
- Lines 296-306: `updatePersonalTaskEvidence()`
- Lines 308-313: `deletePersonalTask()`
- Lines 483-507: `addProjectTask()`
- Lines 509-514: `updateProjectTaskAssignee()`
- Lines 516-523: `updateProjectTaskStatus()`
- Lines 525-534: `updateProjectTaskEvidence()`
- Lines 536-551: `getProjectTasksByStory()`
- Lines 553-568: `getProjectTasks()`
- Lines 611-616: `updateTaskDoDChecklist()`

#### **Bước 1.6: Tạo User Story Repository**

**File mới:** `lib/data/repositories/user_story_repository.dart`

```dart
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/user_story_model.dart';

class UserStoryRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  DatabaseReference get _storiesRef => _database.ref('stories');
  
  // Di chuyển các methods từ DatabaseService:
  // - addUserStory()
  // - addStoryToSprint()
  // - getStoriesForSprint()
  // - getBacklog()
  // - updateUserStory()
}
```

**Các methods cần di chuyển:**
- Lines 388-403: `addUserStory()`
- Lines 405-415: `addStoryToSprint()`
- Lines 417-438: `getStoriesForSprint()`
- Lines 440-460: `getBacklog()`
- Lines 462-479: `updateUserStory()`

#### **Bước 1.7: Tạo Retrospective Repository**

**File mới:** `lib/data/repositories/retrospective_repository.dart`

```dart
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/retrospective_model.dart';

class RetrospectiveRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  DatabaseReference get _retroItemsRef => _database.ref('retro_items');
  DatabaseReference get _actionItemsRef => _database.ref('action_items');
  
  // Di chuyển các methods từ DatabaseService:
  // - addRetroItem()
  // - getRetroItems()
  // - voteRetroItem()
  // - addActionItem()
  // - getActionItems()
  // - toggleActionItem()
}
```

**Các methods cần di chuyển:**
- Lines 658-676: `addRetroItem()`
- Lines 678-699: `getRetroItems()`
- Lines 701-718: `voteRetroItem()`
- Lines 720-735: `addActionItem()`
- Lines 737-754: `getActionItems()`
- Lines 756-761: `toggleActionItem()`

#### **Bước 1.8: Tạo Daily Standup Repository**

**File mới:** `lib/data/repositories/daily_standup_repository.dart`

```dart
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/daily_standup_model.dart';

class DailyStandupRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  DatabaseReference get _standupRef => _database.ref('daily_standups');
  
  // Di chuyển các methods từ DatabaseService:
  // - addDailyStandup()
  // - getDailyStandups()
  // - hasUserSubmittedToday()
}
```

**Các methods cần di chuyển:**
- Lines 767-791: `addDailyStandup()`
- Lines 793-812: `getDailyStandups()`
- Lines 814-850: `hasUserSubmittedToday()` (nếu có)

#### **Bước 1.9: Tạo Definition of Done Repository**

**File mới:** `lib/data/repositories/dod_repository.dart`

```dart
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/definition_of_done_model.dart';

class DefinitionOfDoneRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  DatabaseReference get _dodRef => _database.ref('definition_of_done');
  
  // Di chuyển các methods từ DatabaseService:
  // - createDefinitionOfDone()
  // - getDefinitionOfDone()
}
```

**Các methods cần di chuyển:**
- Lines 574-594: `createDefinitionOfDone()`
- Lines 596-609: `getDefinitionOfDone()`

#### **Bước 1.10: Update imports trong toàn bộ dự án**

Sau khi tạo xong các repositories, cần update imports trong tất cả screens:

**Trước:**
```dart
import 'package:untitled3/services/database_service.dart';

// Sử dụng:
DatabaseService().createProject(...);
DatabaseService(uid: userId).userData;
```

**Sau:**
```dart
import 'package:untitled3/data/repositories/project_repository.dart';
import 'package:untitled3/data/repositories/user_repository.dart';

// Sử dụng:
ProjectRepository(uid: userId).createProject(...);
UserRepository(uid: userId).userData;
```

#### **Bước 1.11: Testing**

Sau khi refactor xong Phase 1:
1. Run app và test tất cả features
2. Đảm bảo không có regression bugs
3. Có thể xóa `database_service.dart` nếu không còn sử dụng

---

## 🎯 PHASE 2: TÁCH LOGIC TỪ SCREENS (3-4 ngày)

### Mục tiêu:
Di chuyển business logic từ screens vào controllers/view models.

### Các bước thực hiện:

#### **Bước 2.1: Tạo cấu trúc thư mục**

```bash
mkdir -p lib/presentation/controllers
mkdir -p lib/presentation/screens/auth
mkdir -p lib/presentation/screens/project
mkdir -p lib/presentation/screens/sprint
mkdir -p lib/presentation/screens/task
mkdir -p lib/presentation/screens/profile
```

#### **Bước 2.2: Tạo Project Controller**

**File mới:** `lib/presentation/controllers/project_controller.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:untitled3/data/repositories/project_repository.dart';
import 'package:untitled3/models/project_model.dart';

class ProjectController extends ChangeNotifier {
  final ProjectRepository _repository;
  
  ProjectController(this._repository);
  
  List<Project> _projects = [];
  bool _isLoading = false;
  String? _error;
  
  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Business logic methods
  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Subscribe to stream
      _repository.getProjects().listen((projects) {
        _projects = projects;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> createProject({
    required String name,
    required String description,
    required int maxMembers,
    DateTime? deadline,
  }) async {
    try {
      await _repository.createProject(name, description, maxMembers, deadline);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<String> joinProject(String code) async {
    return await _repository.joinProjectByCode(code);
  }
  
  // ... other methods
}
```

#### **Bước 2.3: Refactor project_details_screen.dart**

**Trước (1407 dòng):**
```dart
class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Project?>(
      stream: DatabaseService().getProjectById(widget.projectId),
      builder: (context, snapshot) {
        // 1400 dòng code UI + logic lẫn lộn
      }
    );
  }
}
```

**Sau (chia thành nhiều files nhỏ):**

1. **project_details_screen.dart** (~200 dòng) - Chỉ UI
2. **project_summary_tab.dart** (~150 dòng) - Tab Summary
3. **project_backlog_tab.dart** (~200 dòng) - Tab Backlog
4. **project_sprints_tab.dart** (~150 dòng) - Tab Sprints
5. **project_controller.dart** (~200 dòng) - Business logic

#### **Bước 2.4: Tạo Sprint Controller**

**File mới:** `lib/presentation/controllers/sprint_controller.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:untitled3/data/repositories/sprint_repository.dart';
import 'package:untitled3/models/sprint_model.dart';

class SprintController extends ChangeNotifier {
  final SprintRepository _repository;
  
  SprintController(this._repository);
  
  List<Sprint> _sprints = [];
  bool _isLoading = false;
  String? _error;
  
  // Business logic methods
  Future<void> loadSprints(String projectId) async { ... }
  Future<bool> createSprint(...) async { ... }
  Future<void> updateSprintStatus(...) async { ... }
  // ... other methods
}
```

#### **Bước 2.5: Refactor sprint_details_screen.dart**

Tách thành:
1. **sprint_details_screen.dart** (~150 dòng) - Main UI
2. **sprint_kanban_board.dart** (~200 dòng) - Kanban board widget
3. **sprint_task_card.dart** (~100 dòng) - Task card widget
4. **sprint_controller.dart** (~150 dòng) - Business logic

#### **Bước 2.6: Tạo Task Controller**

**File mới:** `lib/presentation/controllers/task_controller.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:untitled3/data/repositories/task_repository.dart';
import 'package:untitled3/models/task_model.dart';
import 'package:untitled3/models/project_task_model.dart';

class TaskController extends ChangeNotifier {
  final TaskRepository _repository;
  
  TaskController(this._repository);
  
  // Personal tasks
  List<Task> _personalTasks = [];
  
  // Project tasks
  List<ProjectTask> _projectTasks = [];
  
  // Business logic methods
  Future<void> loadPersonalTasks() async { ... }
  Future<bool> createPersonalTask(...) async { ... }
  Future<void> updateTaskStatus(...) async { ... }
  // ... other methods
}
```

#### **Bước 2.7: Refactor các screens còn lại**

Áp dụng pattern tương tự cho:
- `user_story_detail_screen.dart`
- `retrospective_screen.dart`
- `daily_standup_screen.dart`
- `task_screen.dart`
- `project_list_screen.dart`

#### **Bước 2.8: Update main.dart để inject controllers**

```dart
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProjectController(ProjectRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => SprintController(SprintRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskController(TaskRepository()),
        ),
        // ... other controllers
      ],
      child: const MyApp(),
    ),
  );
}
```

**Lưu ý:** Cần thêm `provider` vào `pubspec.yaml`:
```yaml
dependencies:
  provider: ^6.0.0
```

---

## 🎯 PHASE 3: THÊM VALIDATION LAYER (1-2 ngày)

### Mục tiêu:
Tách validation logic ra khỏi UI và controllers.

#### **Bước 3.1: Tạo Validators**

**File mới:** `lib/core/utils/validators.dart`

```dart
class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }
  
  // Project name validation
  static String? validateProjectName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tên dự án không được để trống';
    }
    if (value.length < 3) {
      return 'Tên dự án phải có ít nhất 3 ký tự';
    }
    return null;
  }
  
  // Sprint date validation
  static String? validateSprintDates(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return 'Vui lòng chọn ngày bắt đầu và kết thúc';
    }
    if (end.isBefore(start)) {
      return 'Ngày kết thúc phải sau ngày bắt đầu';
    }
    if (end.difference(start).inDays > 30) {
      return 'Sprint không nên dài quá 30 ngày';
    }
    return null;
  }
  
  // Task validation
  static String? validateTaskTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tên task không được để trống';
    }
    return null;
  }
  
  // Story points validation
  static String? validateStoryPoints(String? value) {
    if (value == null || value.isEmpty) {
      return 'Story points không được để trống';
    }
    final points = int.tryParse(value);
    if (points == null || points < 0) {
      return 'Story points phải là số dương';
    }
    if (points > 100) {
      return 'Story points không nên quá 100';
    }
    return null;
  }
}
```

#### **Bước 3.2: Sử dụng Validators trong UI**

**Trước:**
```dart
TextField(
  controller: _emailController,
  decoration: InputDecoration(
    labelText: 'Email',
    errorText: _emailError, // Manual validation
  ),
)
```

**Sau:**
```dart
TextFormField(
  controller: _emailController,
  decoration: InputDecoration(labelText: 'Email'),
  validator: Validators.validateEmail,
)
```

#### **Bước 3.3: Tạo Input Formatters**

**File mới:** `lib/core/utils/formatters.dart`

```dart
import 'package:intl/intl.dart';

class Formatters {
  // Date formatter
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  // DateTime formatter
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
  
  // Relative time (e.g., "2 hours ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
  
  // Number formatter
  static String formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }
}
```

---

## 🎯 PHASE 4: TỔ CHỨC LẠI CẤU TRÚC THƯ MỤC (1 ngày)

### Mục tiêu:
Di chuyển files vào cấu trúc thư mục mới theo Clean Architecture.

#### **Bước 4.1: Di chuyển Models**

```bash
mkdir -p lib/data/models
mv lib/models/* lib/data/models/
rmdir lib/models
```

Update imports trong toàn bộ dự án:
```dart
// Trước
import 'package:untitled3/models/user_model.dart';

// Sau
import 'package:untitled3/data/models/user_model.dart';
```

#### **Bước 4.2: Di chuyển Screens**

```bash
mkdir -p lib/presentation/screens
mv lib/screens/* lib/presentation/screens/
rmdir lib/screens
```

Tổ chức lại screens theo features:
```bash
mkdir -p lib/presentation/screens/auth
mkdir -p lib/presentation/screens/project
mkdir -p lib/presentation/screens/sprint
mkdir -p lib/presentation/screens/task
mkdir -p lib/presentation/screens/profile
mkdir -p lib/presentation/screens/dashboard

# Di chuyển files vào đúng thư mục
mv lib/presentation/screens/login_screen.dart lib/presentation/screens/auth/
mv lib/presentation/screens/signup_screen.dart lib/presentation/screens/auth/
# ... tương tự cho các screens khác
```

#### **Bước 4.3: Di chuyển Widgets**

```bash
mkdir -p lib/presentation/widgets/common
mkdir -p lib/presentation/widgets/project
mkdir -p lib/presentation/widgets/task
mv lib/widgets/* lib/presentation/widgets/common/
rmdir lib/widgets
```

#### **Bước 4.4: Tạo Core folder**

```bash
mkdir -p lib/core/constants
mkdir -p lib/core/theme
mkdir -p lib/core/utils
mkdir -p lib/core/errors
```

**File mới:** `lib/core/constants/app_constants.dart`
```dart
class AppConstants {
  static const String appName = 'DAMobile';
  static const int maxProjectMembers = 20;
  static const int maxSprintDays = 30;
  static const int minPasswordLength = 6;
  
  // Firebase collections
  static const String usersCollection = 'users';
  static const String projectsCollection = 'projects';
  static const String sprintsCollection = 'sprints';
  static const String tasksCollection = 'tasks';
}
```

#### **Bước 4.5: Update tất cả imports**

Sử dụng IDE để tự động update imports:
- VS Code: `Ctrl+Shift+H` để find & replace
- Android Studio: `Ctrl+Shift+R`

Hoặc sử dụng script:
```bash
find lib -name "*.dart" -exec sed -i 's/package:untitled3\/models\//package:untitled3\/data\/models\//g' {} +
find lib -name "*.dart" -exec sed -i 's/package:untitled3\/screens\//package:untitled3\/presentation\/screens\//g' {} +
```

#### **Bước 4.6: Testing cuối cùng**

1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter analyze` để check errors
4. Run `flutter test`
5. Run app và test tất cả features

---

## 📊 CHECKLIST TỔNG THỂ

### Phase 1: Tách Database Service
- [ ] Tạo UserRepository
- [ ] Tạo ProjectRepository
- [ ] Tạo SprintRepository
- [ ] Tạo TaskRepository
- [ ] Tạo UserStoryRepository
- [ ] Tạo RetrospectiveRepository
- [ ] Tạo DailyStandupRepository
- [ ] Tạo DefinitionOfDoneRepository
- [ ] Update imports trong screens
- [ ] Test toàn bộ app
- [ ] Xóa database_service.dart (optional)

### Phase 2: Tách Logic từ Screens
- [ ] Thêm provider package
- [ ] Tạo ProjectController
- [ ] Tạo SprintController
- [ ] Tạo TaskController
- [ ] Refactor project_details_screen.dart
- [ ] Refactor sprint_details_screen.dart
- [ ] Refactor user_story_detail_screen.dart
- [ ] Refactor các screens còn lại
- [ ] Update main.dart với providers
- [ ] Test toàn bộ app

### Phase 3: Thêm Validation Layer
- [ ] Tạo Validators class
- [ ] Tạo Formatters class
- [ ] Update forms với validators
- [ ] Test validation logic
- [ ] Update error handling

### Phase 4: Tổ chức lại cấu trúc
- [ ] Di chuyển models
- [ ] Di chuyển screens
- [ ] Di chuyển widgets
- [ ] Tạo core folder
- [ ] Update tất cả imports
- [ ] Run flutter analyze
- [ ] Test toàn bộ app
- [ ] Update documentation

---

## ⚠️ LƯU Ý QUAN TRỌNG

1. **Backup trước khi refactor:**
   ```bash
   git checkout -b refactor-phase-1
   git commit -am "Backup before refactoring"
   ```

2. **Làm từng phase một:**
   - Không làm nhiều phase cùng lúc
   - Commit sau mỗi bước nhỏ
   - Test kỹ trước khi chuyển sang phase tiếp theo

3. **Testing:**
   - Viết tests trước khi refactor (nếu có thể)
   - Test manual sau mỗi thay đổi lớn
   - Sử dụng Git để rollback nếu có vấn đề

4. **Documentation:**
   - Update README.md sau mỗi phase
   - Document các breaking changes
   - Update CHANGELOG.md

---

## 📈 KẾT QUẢ MONG ĐỢI

Sau khi hoàn thành 4 phases:

✅ **Code Quality:**
- Mỗi file < 300 dòng
- Separation of concerns rõ ràng
- Dễ đọc, dễ hiểu, dễ maintain

✅ **Testability:**
- Business logic có thể test độc lập
- UI có thể test với mock data
- Test coverage > 70%

✅ **Scalability:**
- Dễ thêm features mới
- Dễ thay đổi backend
- Dễ optimize performance

✅ **Team Collaboration:**
- Nhiều người có thể làm việc song song
- Ít conflict khi merge code
- Onboarding developers mới dễ dàng hơn

---

**Thời gian ước tính:** 7-10 ngày làm việc
**Độ ưu tiên:** Cao
**Risk level:** Trung bình (có thể rollback bằng Git)
