# 🔍 DANH SÁCH CỤ THỂ CÁC FILE CẦN REFACTOR

## 📊 BẢNG TỔNG HỢP

| # | File | Kích thước | Dòng | Vấn đề chính | Độ ưu tiên |
|---|------|-----------|------|--------------|------------|
| 1 | `lib/services/database_service.dart` | 26KB | 850 | God Object - Chứa tất cả DB operations | 🔴 Cao nhất |
| 2 | `lib/screens/project_details_screen.dart` | 51KB | 1,407 | UI + Business logic lẫn lộn | 🔴 Cao |
| 3 | `lib/screens/sprint_details_screen.dart` | 41KB | 1,046 | UI + Business logic lẫn lộn | 🔴 Cao |
| 4 | `lib/screens/user_story_detail_screen.dart` | 41KB | 993 | UI + File upload + Validation | 🔴 Cao |
| 5 | `lib/screens/retrospective_screen.dart` | 27KB | ~700 | UI + Database operations | 🟡 Trung bình |
| 6 | `lib/screens/daily_standup_screen.dart` | 27KB | ~700 | UI + Database operations | 🟡 Trung bình |
| 7 | `lib/screens/task_screen.dart` | 22KB | ~600 | UI + Validation + Database | 🟡 Trung bình |
| 8 | `lib/screens/project_list_screen.dart` | 20KB | ~550 | UI + Filtering logic | 🟡 Trung bình |
| 9 | `lib/screens/definition_of_done_screen.dart` | 17KB | ~450 | UI + Database operations | 🟢 Thấp |
| 10 | `lib/screens/dashboard_view.dart` | 10KB | 330 | UI + Data processing | 🟢 Thấp |
| 11 | `lib/screens/profile_screen.dart` | 9KB | ~300 | UI + File upload | 🟢 Thấp |

---

## 🔴 ƯU TIÊN CAO NHẤT

### 1. `lib/services/database_service.dart` (850 dòng)

**Vấn đề:**
- Chứa operations cho 8+ entities
- God Object anti-pattern
- Không thể test riêng từng phần

**Cần tách thành:**
```
lib/data/repositories/
├── user_repository.dart           (Lines 33-102)
├── project_repository.dart        (Lines 106-239)
├── sprint_repository.dart         (Lines 317-386, 620-651)
├── task_repository.dart           (Lines 243-313, 483-568, 611-616)
├── user_story_repository.dart     (Lines 388-479)
├── retrospective_repository.dart  (Lines 658-761)
├── daily_standup_repository.dart  (Lines 767-850)
└── dod_repository.dart            (Lines 574-609)
```

**Hành động:**
1. Tạo 8 repository files
2. Copy methods tương ứng vào mỗi repository
3. Update imports trong tất cả screens
4. Test từng repository
5. Xóa database_service.dart

---

### 2. `lib/screens/project_details_screen.dart` (1,407 dòng)

**Vấn đề:**
- File quá lớn, khó đọc
- Chứa 3 tabs (Summary, Backlog, Sprints) trong 1 file
- Gọi DatabaseService trực tiếp từ UI
- Business logic lẫn UI code

**Cần tách thành:**
```
lib/presentation/screens/project/
├── project_details_screen.dart        (~150 dòng) - Main screen
├── tabs/
│   ├── project_summary_tab.dart       (~200 dòng) - Tab 1
│   ├── project_backlog_tab.dart       (~250 dòng) - Tab 2
│   └── project_sprints_tab.dart       (~200 dòng) - Tab 3
└── widgets/
    ├── project_stat_card.dart         (~50 dòng)
    ├── project_chart_widget.dart      (~100 dòng)
    ├── sprint_group_widget.dart       (~100 dòng)
    └── story_item_widget.dart         (~80 dòng)

lib/presentation/controllers/
└── project_controller.dart            (~200 dòng) - Business logic
```

**Hành động:**
1. Tạo ProjectController
2. Tách UI thành các tabs riêng
3. Tách widgets nhỏ
4. Di chuyển business logic vào controller
5. Update imports

---

### 3. `lib/screens/sprint_details_screen.dart` (1,046 dòng)

**Vấn đề:**
- Kanban board logic lẫn với database operations
- Drag & drop logic phức tạp trong UI
- Gọi database trực tiếp

**Cần tách thành:**
```
lib/presentation/screens/sprint/
├── sprint_details_screen.dart         (~150 dòng) - Main screen
├── widgets/
│   ├── sprint_kanban_board.dart       (~250 dòng) - Kanban board
│   ├── sprint_task_card.dart          (~100 dòng) - Task card
│   ├── sprint_goal_banner.dart        (~50 dòng)  - Goal banner
│   └── sprint_column.dart             (~80 dòng)  - Kanban column
└── dialogs/
    └── add_task_dialog.dart           (~200 dòng) - Add task dialog

lib/presentation/controllers/
└── sprint_controller.dart             (~150 dòng) - Business logic
```

**Hành động:**
1. Tạo SprintController
2. Tách Kanban board thành widget riêng
3. Tách dialog thành file riêng
4. Di chuyển drag & drop logic vào controller
5. Update imports

---

### 4. `lib/screens/user_story_detail_screen.dart` (993 dòng)

**Vấn đề:**
- File upload (Firebase Storage) trong UI
- Validation logic trong UI
- Database operations trong UI
- Dialog code quá dài

**Cần tách thành:**
```
lib/presentation/screens/task/
├── user_story_detail_screen.dart      (~150 dòng) - Main screen
├── widgets/
│   ├── story_header.dart              (~80 dòng)  - Header
│   ├── story_description.dart         (~60 dòng)  - Description
│   ├── task_list_widget.dart          (~100 dòng) - Task list
│   └── task_card_widget.dart          (~150 dòng) - Task card
└── dialogs/
    └── add_task_dialog.dart           (~200 dòng) - Add task dialog

lib/presentation/controllers/
└── user_story_controller.dart         (~150 dòng) - Business logic

lib/services/
└── storage_service.dart               (~100 dòng) - File upload
```

**Hành động:**
1. Tạo UserStoryController
2. Tạo StorageService cho file upload
3. Tách widgets nhỏ
4. Tách dialog riêng
5. Di chuyển validation vào Validators
6. Update imports

---

## 🟡 ƯU TIÊN TRUNG BÌNH

### 5. `lib/screens/retrospective_screen.dart` (27KB)

**Cần tách thành:**
```
lib/presentation/screens/sprint/
├── retrospective_screen.dart          (~150 dòng)
├── widgets/
│   ├── retro_category_section.dart    (~100 dòng)
│   ├── retro_item_card.dart           (~80 dòng)
│   └── action_items_section.dart      (~100 dòng)
└── dialogs/
    ├── add_retro_item_dialog.dart     (~80 dòng)
    └── add_action_item_dialog.dart    (~80 dòng)

lib/presentation/controllers/
└── retrospective_controller.dart      (~100 dòng)
```

---

### 6. `lib/screens/daily_standup_screen.dart` (27KB)

**Cần tách thành:**
```
lib/presentation/screens/sprint/
├── daily_standup_screen.dart          (~150 dòng)
├── widgets/
│   ├── standup_form.dart              (~150 dòng)
│   ├── standup_list.dart              (~100 dòng)
│   └── standup_card.dart              (~80 dòng)
└── dialogs/
    └── submit_standup_dialog.dart     (~100 dòng)

lib/presentation/controllers/
└── daily_standup_controller.dart      (~80 dòng)
```

---

### 7. `lib/screens/task_screen.dart` (22KB)

**Cần tách thành:**
```
lib/presentation/screens/task/
├── task_screen.dart                   (~150 dòng)
├── widgets/
│   ├── task_list_widget.dart          (~100 dòng)
│   ├── task_card_widget.dart          (~100 dòng)
│   └── task_filter_widget.dart        (~80 dòng)
└── dialogs/
    └── add_task_dialog.dart           (~100 dòng)

lib/presentation/controllers/
└── task_controller.dart               (~100 dòng)
```

---

### 8. `lib/screens/project_list_screen.dart` (20KB)

**Cần tách thành:**
```
lib/presentation/screens/project/
├── project_list_screen.dart           (~150 dòng)
├── widgets/
│   ├── project_card.dart              (~100 dòng)
│   ├── project_filter.dart            (~80 dòng)
│   └── empty_project_state.dart       (~50 dòng)
└── dialogs/
    ├── create_project_dialog.dart     (~150 dòng)
    └── join_project_dialog.dart       (~100 dòng)

lib/presentation/controllers/
└── project_list_controller.dart       (~100 dòng)
```

---

## 🟢 ƯU TIÊN THẤP

### 9-11. Các screens còn lại

Các screens này có thể refactor sau:
- `definition_of_done_screen.dart` (17KB)
- `dashboard_view.dart` (10KB)
- `profile_screen.dart` (9KB)

---

## 📋 CHECKLIST REFACTORING

### Phase 1: Database Service
- [ ] Tạo UserRepository
- [ ] Tạo ProjectRepository
- [ ] Tạo SprintRepository
- [ ] Tạo TaskRepository
- [ ] Tạo UserStoryRepository
- [ ] Tạo RetrospectiveRepository
- [ ] Tạo DailyStandupRepository
- [ ] Tạo DoDRepository
- [ ] Update imports
- [ ] Test

### Phase 2: Screens lớn nhất
- [ ] Refactor project_details_screen.dart
- [ ] Refactor sprint_details_screen.dart
- [ ] Refactor user_story_detail_screen.dart
- [ ] Test

### Phase 3: Screens trung bình
- [ ] Refactor retrospective_screen.dart
- [ ] Refactor daily_standup_screen.dart
- [ ] Refactor task_screen.dart
- [ ] Refactor project_list_screen.dart
- [ ] Test

### Phase 4: Screens nhỏ
- [ ] Refactor các screens còn lại
- [ ] Test tổng thể

---

## 📊 METRICS

### Trước refactoring:
- **Tổng số files:** 35
- **Files > 20KB:** 8
- **Files > 300 dòng:** 10+
- **Largest file:** 51KB (1,407 dòng)
- **God Object:** 1 (database_service.dart)

### Mục tiêu sau refactoring:
- **Tổng số files:** ~80-100 (tăng do tách nhỏ)
- **Files > 20KB:** 0
- **Files > 300 dòng:** 0
- **Largest file:** < 10KB (< 300 dòng)
- **God Object:** 0

---

## ⏱️ THỜI GIAN ƯỚC TÍNH

| Task | Thời gian | Người |
|------|-----------|-------|
| Tách database_service.dart | 2-3 ngày | 1 dev |
| Refactor 3 screens lớn | 3-4 ngày | 1-2 devs |
| Refactor 4 screens trung bình | 2-3 ngày | 1-2 devs |
| Refactor screens nhỏ | 1 ngày | 1 dev |
| Testing tổng thể | 1 ngày | Team |
| **Tổng** | **9-12 ngày** | |

---

**Ngày tạo:** 2026-01-10  
**Người tạo:** AI Assistant  
**Trạng thái:** Danh sách chi tiết - Sẵn sàng thực hiện
