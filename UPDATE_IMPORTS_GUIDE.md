# 🔄 HƯỚNG DẪN UPDATE IMPORTS - CÁC SCREENS CÒN LẠI

## ✅ ĐÃ HOÀN THÀNH

- [x] `profile_screen.dart` → UserRepository
- [x] `project_list_screen.dart` → ProjectRepository

## 📋 CÒN LẠI (~15 screens)

### 🔍 CÁCH TÌM VÀ THAY THẾ

#### Bước 1: Tìm DatabaseService trong file
```bash
# Trong VS Code/Android Studio
Ctrl+F trong file: "DatabaseService"
```

#### Bước 2: Xác định repository cần dùng

| DatabaseService Method | Repository | Import |
|----------------------|------------|--------|
| `createNewUser()`, `updateUserData()`, `updateUserAvatar()`, `userData`, `getProjectMembers()` | UserRepository | `import 'package:untitled3/data/repositories/user_repository.dart';` |
| `createProject()`, `joinProjectByCode()`, `getProjects()`, `getProjectById()`, `removeMember()`, `updateMemberRole()`, `toggleProjectLock()`, `deleteProject()` | ProjectRepository | `import 'package:untitled3/data/repositories/project_repository.dart';` |
| `addSprint()`, `addSprintWithGoal()`, `updateSprintStatus()`, `updateSprintPriority()`, `updateSprintGoal()`, `getSprints()`, `checkAndUpdateSprintStatuses()` | SprintRepository | `import 'package:untitled3/data/repositories/sprint_repository.dart';` |
| `personalTasks`, `addPersonalTask()`, `updatePersonalTaskStatus()`, `updatePersonalTaskEvidence()`, `deletePersonalTask()`, `addProjectTask()`, `updateProjectTaskAssignee()`, `updateProjectTaskStatus()`, `updateProjectTaskEvidence()`, `getProjectTasksByStory()`, `getProjectTasks()`, `updateTaskDoDChecklist()` | TaskRepository | `import 'package:untitled3/data/repositories/task_repository.dart';` |
| `addUserStory()`, `addStoryToSprint()`, `getStoriesForSprint()`, `getBacklog()`, `updateUserStory()` | UserStoryRepository | `import 'package:untitled3/data/repositories/user_story_repository.dart';` |
| `addRetroItem()`, `getRetroItems()`, `voteRetroItem()`, `addActionItem()`, `getActionItems()`, `toggleActionItem()` | RetrospectiveRepository | `import 'package:untitled3/data/repositories/retrospective_repository.dart';` |
| `addDailyStandup()`, `getDailyStandups()`, `getTodayStandup()`, `getSprintBlockers()` | DailyStandupRepository | `import 'package:untitled3/data/repositories/daily_standup_repository.dart';` |
| `createDefinitionOfDone()`, `getDefinitionOfDone()` | DefinitionOfDoneRepository | `import 'package:untitled3/data/repositories/dod_repository.dart';` |

#### Bước 3: Thay thế

**Trước:**
```dart
import 'package:untitled3/services/database_service.dart';

DatabaseService(uid: userId).createProject(...);
```

**Sau:**
```dart
import 'package:untitled3/data/repositories/project_repository.dart';

ProjectRepository(uid: userId).createProject(...);
```

---

## 📝 DANH SÁCH CHI TIẾT CÁC SCREENS

### 1. ⚠️ `project_details_screen.dart` (PHỨC TẠP - 1,407 dòng)

**Repositories cần:**
- ProjectRepository
- SprintRepository
- UserStoryRepository
- UserRepository (cho getProjectMembers)

**Các thay thế:**

```dart
// Line ~9: Import
- import 'package:untitled3/services/database_service.dart';
+ import 'package:untitled3/data/repositories/project_repository.dart';
+ import 'package:untitled3/data/repositories/sprint_repository.dart';
+ import 'package:untitled3/data/repositories/user_story_repository.dart';
+ import 'package:untitled3/data/repositories/user_repository.dart';

// Tìm tất cả DatabaseService() và thay thế:
// - Project operations → ProjectRepository()
// - Sprint operations → SprintRepository()
// - User story operations → UserStoryRepository()
// - getProjectMembers() → UserRepository()
```

**Lưu ý:** File này rất lớn, nên làm từng phần:
1. Thay import trước
2. Thay từng method một
3. Test sau mỗi vài thay đổi

---

### 2. ⚠️ `sprint_details_screen.dart` (PHỨC TẠP - 1,046 dòng)

**Repositories cần:**
- SprintRepository
- TaskRepository
- UserStoryRepository
- UserRepository

**Các thay thế:**

```dart
// Import
- import 'package:untitled3/services/database_service.dart';
+ import 'package:untitled3/data/repositories/sprint_repository.dart';
+ import 'package:untitled3/data/repositories/task_repository.dart';
+ import 'package:untitled3/data/repositories/user_story_repository.dart';
+ import 'package:untitled3/data/repositories/user_repository.dart';

// Methods:
// - checkAndUpdateSprintStatuses() → SprintRepository()
// - getProjectTasks() → TaskRepository()
// - addProjectTask() → TaskRepository()
// - updateProjectTaskStatus() → TaskRepository()
// - getStoriesForSprint() → UserStoryRepository()
// - getProjectMembers() → UserRepository()
```

---

### 3. ⚠️ `user_story_detail_screen.dart` (PHỨC TẠP - 993 dòng)

**Repositories cần:**
- UserStoryRepository
- TaskRepository
- UserRepository
- DefinitionOfDoneRepository

**Các thay thế:**

```dart
// Import
- import 'package:untitled3/services/database_service.dart';
+ import 'package:untitled3/data/repositories/user_story_repository.dart';
+ import 'package:untitled3/data/repositories/task_repository.dart';
+ import 'package:untitled3/data/repositories/user_repository.dart';
+ import 'package:untitled3/data/repositories/dod_repository.dart';

// Methods:
// - updateUserStory() → UserStoryRepository()
// - getProjectTasksByStory() → TaskRepository()
// - addProjectTask() → TaskRepository()
// - updateProjectTaskStatus() → TaskRepository()
// - getProjectMembers() → UserRepository()
// - getDefinitionOfDone() → DefinitionOfDoneRepository()
// - updateTaskDoDChecklist() → TaskRepository()
```

---

### 4. `task_screen.dart` (22KB)

**Repositories cần:**
- TaskRepository

**Các thay thế:**

```dart
// Import
- import 'package:untitled3/services/database_service.dart';
+ import 'package:untitled3/data/repositories/task_repository.dart';

// Methods:
// - personalTasks → TaskRepository(uid: userId).personalTasks
// - addPersonalTask() → TaskRepository(uid: userId).addPersonalTask()
// - updatePersonalTaskStatus() → TaskRepository(uid: userId).updatePersonalTaskStatus()
// - updatePersonalTaskEvidence() → TaskRepository(uid: userId).updatePersonalTaskEvidence()
// - deletePersonalTask() → TaskRepository(uid: userId).deletePersonalTask()
```

---

### 5. `dashboard_view.dart` (10KB)

**Repositories cần:**
- TaskRepository

**Các thay thế:**

```dart
// Import
- import 'package:untitled3/services/database_service.dart';
+ import 'package:untitled3/data/repositories/task_repository.dart';

// Methods:
// - personalTasks → TaskRepository(uid: userId).personalTasks
```

---

### 6. `retrospective_screen.dart` (27KB)

**Repositories cần:**
- RetrospectiveRepository

**Các thay thế:**

```dart
// Import
- import 'package:untitled3/services/database_service.dart';
+ import 'package:untitled3/data/repositories/retrospective_repository.dart';

// Methods:
// - addRetroItem() → RetrospectiveRepository().addRetroItem()
// - getRetroItems() → RetrospectiveRepository().getRetroItems()
// - voteRetroItem() → RetrospectiveRepository().voteRetroItem()
// - addActionItem() → RetrospectiveRepository().addActionItem()
// - getActionItems() → RetrospectiveRepository().getActionItems()
// - toggleActionItem() → RetrospectiveRepository().toggleActionItem()
```

---

### 7. `daily_standup_screen.dart` (27KB)

**Repositories cần:**
- DailyStandupRepository

**Các thay thế:**

```dart
// Import
- import 'package:untitled3/services/database_service.dart';
+ import 'package:untitled3/data/repositories/daily_standup_repository.dart';

// Methods:
// - addDailyStandup() → DailyStandupRepository().addDailyStandup()
// - getDailyStandups() → DailyStandupRepository().getDailyStandups()
// - getTodayStandup() → DailyStandupRepository().getTodayStandup()
// - getSprintBlockers() → DailyStandupRepository().getSprintBlockers()
```

---

### 8. `definition_of_done_screen.dart` (17KB)

**Repositories cần:**
- DefinitionOfDoneRepository

**Các thay thế:**

```dart
// Import
- import 'package:untitled3/services/database_service.dart';
+ import 'package:untitled3/data/repositories/dod_repository.dart';

// Methods:
// - createDefinitionOfDone() → DefinitionOfDoneRepository().createDefinitionOfDone()
// - getDefinitionOfDone() → DefinitionOfDoneRepository().getDefinitionOfDone()
```

---

### 9. `member_management_screen.dart` (7KB)

**Repositories cần:**
- ProjectRepository
- UserRepository

**Các thay thế:**

```dart
// Import
- import 'package:untitled3/services/database_service.dart';
+ import 'package:untitled3/data/repositories/project_repository.dart';
+ import 'package:untitled3/data/repositories/user_repository.dart';

// Methods:
// - getProjectMembers() → UserRepository().getProjectMembers()
// - removeMember() → ProjectRepository().removeMember()
// - updateMemberRole() → ProjectRepository().updateMemberRole()
```

---

## 🚀 QUY TRÌNH THỰC HIỆN

### Cho mỗi screen:

1. **Mở file**
2. **Tìm DatabaseService:**
   ```
   Ctrl+F: "DatabaseService"
   ```
3. **Xác định repositories cần dùng** (xem bảng trên)
4. **Thay import:**
   ```dart
   - import 'package:untitled3/services/database_service.dart';
   + import 'package:untitled3/data/repositories/xxx_repository.dart';
   ```
5. **Thay từng DatabaseService() call:**
   - Tìm method được gọi
   - Xem repository nào có method đó
   - Thay thế
6. **Save file**
7. **Test:**
   ```bash
   flutter run
   # Test screen vừa update
   ```
8. **Commit nếu OK:**
   ```bash
   git add lib/screens/xxx_screen.dart
   git commit -m "Update xxx_screen to use repositories"
   ```

---

## ⚠️ LƯU Ý QUAN TRỌNG

### 1. Constructor parameters

**DatabaseService:**
```dart
DatabaseService(uid: userId)
```

**Repositories:**
```dart
// Có uid parameter
UserRepository(uid: userId)
ProjectRepository(uid: userId)
TaskRepository(uid: userId)

// Không có uid parameter
SprintRepository()
UserStoryRepository()
RetrospectiveRepository()
DailyStandupRepository()
DefinitionOfDoneRepository()
```

### 2. Files lớn (>1000 dòng)

Với `project_details_screen.dart`, `sprint_details_screen.dart`, `user_story_detail_screen.dart`:

- Làm từng phần nhỏ
- Test thường xuyên
- Commit sau mỗi phần hoàn thành
- Có thể mất 30-60 phút mỗi file

### 3. Nếu gặp lỗi

**Lỗi import:**
```
Error: Not found: 'package:untitled3/data/repositories/xxx_repository.dart'
```
→ Check đường dẫn import

**Lỗi method:**
```
Error: The method 'xxx' isn't defined for the class 'XxxRepository'
```
→ Check xem method có trong repository chưa

**Lỗi constructor:**
```
Error: The parameter 'uid' isn't defined
```
→ Repository này không cần uid parameter

---

## 📊 TIẾN ĐỘ

### Đã update: 2/17 screens (12%)
- [x] profile_screen.dart
- [x] project_list_screen.dart

### Còn lại: 15 screens (88%)
- [ ] project_details_screen.dart (PHỨC TẠP)
- [ ] sprint_details_screen.dart (PHỨC TẠP)
- [ ] user_story_detail_screen.dart (PHỨC TẠP)
- [ ] task_screen.dart
- [ ] dashboard_view.dart
- [ ] retrospective_screen.dart
- [ ] daily_standup_screen.dart
- [ ] definition_of_done_screen.dart
- [ ] member_management_screen.dart
- [ ] home_screen.dart (nếu có)
- [ ] wrapper.dart (nếu có)
- [ ] login_screen.dart (nếu có)
- [ ] public_profile_view.dart (nếu có)
- [ ] error_screen.dart (không cần)

**Thời gian ước tính:** 3-4 giờ

---

## 🎯 ƯU TIÊN

### Làm theo thứ tự:

1. **Dễ** (30 phút):
   - task_screen.dart
   - dashboard_view.dart
   - definition_of_done_screen.dart
   - member_management_screen.dart

2. **Trung bình** (1 giờ):
   - retrospective_screen.dart
   - daily_standup_screen.dart

3. **Khó** (2-3 giờ):
   - project_details_screen.dart
   - sprint_details_screen.dart
   - user_story_detail_screen.dart

---

**Cập nhật:** 2026-01-10 21:20  
**Trạng thái:** 2/17 screens updated
