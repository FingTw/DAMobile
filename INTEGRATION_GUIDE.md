# 🔗 INTEGRATION GUIDE - Kết Nối UI Mới

**Ngày:** 10/01/2026  
**Mục đích:** Hướng dẫn tích hợp các screens mới vào app

---

## ✅ SCREENS ĐÃ TẠO

1. ✅ `lib/screens/definition_of_done_screen.dart`
2. ✅ `lib/screens/retrospective_screen.dart`
3. ✅ `lib/screens/daily_standup_screen.dart`

---

## 🔧 CÁCH TÍCH HỢP

### 1. Definition of Done Screen

#### Thêm vào Project Details Screen

**File:** `lib/screens/project_details_screen.dart`

**Vị trí:** Trong AppBar actions hoặc Settings menu

```dart
// Import
import 'package:untitled3/screens/definition_of_done_screen.dart';

// Trong AppBar actions
actions: [
  IconButton(
    icon: const Icon(Icons.verified, color: Color(0xFF2563EB)),
    tooltip: 'Definition of Done',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DefinitionOfDoneScreen(project: widget.project),
        ),
      );
    },
  ),
  // ... other actions
],
```

**Hoặc thêm vào Settings Menu:**

```dart
ListTile(
  leading: const Icon(Icons.verified, color: Color(0xFF2563EB)),
  title: Text('Definition of Done', style: GoogleFonts.inter()),
  subtitle: Text('Manage quality criteria', style: GoogleFonts.inter(fontSize: 12)),
  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DefinitionOfDoneScreen(project: widget.project),
      ),
    );
  },
),
```

---

### 2. Retrospective Screen

#### Thêm vào Sprint Details Screen

**File:** `lib/screens/sprint_details_screen.dart`

**Vị trí:** Floating Action Button hoặc AppBar actions

```dart
// Import
import 'package:untitled3/screens/retrospective_screen.dart';

// Trong AppBar actions (cho completed sprints)
if (widget.sprint.status == SprintStatus.completed)
  IconButton(
    icon: const Icon(Icons.feedback, color: Color(0xFF8B5CF6)),
    tooltip: 'Retrospective',
    onPressed: () async {
      final members = await _projectMembers; // Từ FutureBuilder
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RetrospectiveScreen(
            sprint: widget.sprint,
            projectId: widget.project.id,
            members: members,
          ),
        ),
      );
    },
  ),
```

**Hoặc thêm FAB riêng:**

```dart
// Thêm vào Scaffold
floatingActionButton: widget.sprint.status == SprintStatus.completed
    ? FloatingActionButton.extended(
        onPressed: () async {
          final members = await _projectMembers;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RetrospectiveScreen(
                sprint: widget.sprint,
                projectId: widget.project.id,
                members: members,
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.feedback, color: Colors.white),
        label: Text(
          'Retrospective',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      )
    : FloatingActionButton.extended(
        // ... existing FAB for adding tasks
      ),
```

---

### 3. Daily Standup Screen

#### Option A: Thêm vào Sprint Details Screen

**File:** `lib/screens/sprint_details_screen.dart`

```dart
// Import
import 'package:untitled3/screens/daily_standup_screen.dart';

// Trong AppBar actions (cho active sprints)
if (widget.sprint.status == SprintStatus.inProgress)
  IconButton(
    icon: const Icon(Icons.today, color: Color(0xFF10B981)),
    tooltip: 'Daily Standup',
    onPressed: () async {
      final members = await _projectMembers;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DailyStandupScreen(
            sprint: widget.sprint,
            projectId: widget.project.id,
            members: members,
          ),
        ),
      );
    },
  ),
```

#### Option B: Thêm vào Home Screen (Quick Access)

**File:** `lib/screens/home_screen.dart`

```dart
// Import
import 'package:untitled3/screens/daily_standup_screen.dart';

// Thêm Quick Action Card trong Dashboard
Card(
  child: ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.today, color: Color(0xFF10B981)),
    ),
    title: Text('Daily Standup', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
    subtitle: Text('Submit your daily update', style: GoogleFonts.inter(fontSize: 12)),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () async {
      // Get active sprint
      final activeSprint = await _getActiveSprint();
      if (activeSprint != null) {
        final members = await _getProjectMembers(activeSprint.projectId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DailyStandupScreen(
              sprint: activeSprint,
              projectId: activeSprint.projectId,
              members: members,
            ),
          ),
        );
      } else {
        ToastService.show(
          title: 'No Active Sprint',
          message: 'Start a sprint to submit daily updates',
          type: NotificationType.warning,
        );
      }
    },
  ),
),
```

---

### 4. Sprint Goal Integration

#### A. Thêm Goal Input vào Create Sprint Dialog

**File:** `lib/screens/project_details_screen.dart` (hoặc nơi tạo sprint)

**Trong Sprint Creation Dialog:**

```dart
// Thêm controllers
final _goalController = TextEditingController();
final _goalDescriptionController = TextEditingController();

// Trong dialog form
TextField(
  controller: _goalController,
  decoration: InputDecoration(
    labelText: 'Sprint Goal *',
    hintText: 'e.g., Complete user authentication',
    prefixIcon: const Icon(Icons.flag),
  ),
),
const SizedBox(height: 16),
TextField(
  controller: _goalDescriptionController,
  maxLines: 2,
  decoration: InputDecoration(
    labelText: 'Goal Description',
    hintText: 'Detailed description of what we aim to achieve',
    prefixIcon: const Icon(Icons.description),
  ),
),

// Khi save
await DatabaseService().addSprintWithGoal(
  projectId,
  nameController.text,
  startDate,
  endDate,
  _goalController.text.trim(),
  _goalDescriptionController.text.trim(),
);
```

#### B. Hiển thị Goal trong Sprint Details

**File:** `lib/screens/sprint_details_screen.dart`

**Thêm banner sau AppBar:**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(...),
    body: Column(
      children: [
        // Sprint Goal Banner
        if (widget.sprint.goal.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2563EB),
                  const Color(0xFF3B82F6),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Sprint Goal',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.sprint.goal,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.sprint.goalDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.sprint.goalDescription,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        
        // Existing content
        Expanded(
          child: StreamBuilder(...),
        ),
      ],
    ),
  );
}
```

#### C. Hiển thị Goal trong Sprint List

**File:** `lib/screens/project_details_screen.dart` (Sprint Tab)

**Trong Sprint Card:**

```dart
// Thêm vào Sprint Card
if (sprint.goal.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Icon(Icons.flag, size: 14, color: Colors.blue[700]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            sprint.goal,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  ),
```

---

### 5. DoD Checklist trong Task Detail

#### Cập nhật User Story Detail Screen

**File:** `lib/screens/user_story_detail_screen.dart`

**Thêm DoD Checklist section:**

```dart
// Import
import 'package:untitled3/models/definition_of_done_model.dart';

// Trong task detail, thêm section
StreamBuilder<DefinitionOfDone?>(
  stream: DatabaseService().getDefinitionOfDone(widget.projectId),
  builder: (context, dodSnapshot) {
    if (!dodSnapshot.hasData || dodSnapshot.data == null) {
      return const SizedBox.shrink();
    }

    final dod = dodSnapshot.data!;
    final checklist = task.dodChecklist;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Definition of Done',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: task.isDoDComplete
                    ? Colors.green[100]
                    : Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${task.dodCompletedCount}/${task.dodTotalCount}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: task.isDoDComplete
                      ? Colors.green[700]
                      : Colors.orange[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: task.dodProgress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation(
            task.isDoDComplete ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(height: 12),
        ...dod.items.map((item) {
          final isChecked = checklist[item.description] ?? false;
          
          return CheckboxListTile(
            value: isChecked,
            onChanged: (value) async {
              final newChecklist = Map<String, bool>.from(checklist);
              newChecklist[item.description] = value ?? false;
              
              await DatabaseService().updateTaskDoDChecklist(
                task.id,
                newChecklist,
              );
            },
            title: Text(
              item.description,
              style: GoogleFonts.inter(fontSize: 14),
            ),
            activeColor: const Color(0xFF10B981),
          );
        }),
      ],
    );
  },
),
```

---

## 📱 NAVIGATION SUMMARY

### Từ Project Details:
- ✅ Definition of Done → Settings/AppBar

### Từ Sprint Details:
- ✅ Retrospective → AppBar/FAB (completed sprints)
- ✅ Daily Standup → AppBar (active sprints)
- ✅ Sprint Goal → Banner display

### Từ Home/Dashboard:
- ✅ Daily Standup → Quick Action Card

### Từ Task Detail:
- ✅ DoD Checklist → Task detail section

---

## 🎨 UI CONSISTENCY CHECKLIST

- [x] All screens use Google Fonts Inter
- [x] Consistent color scheme (Blue/Green/Orange/Purple)
- [x] 12px border radius for cards
- [x] Shadows with 0.05 opacity
- [x] Icons size 20-24px
- [x] Padding 16px standard
- [x] White backgrounds for cards
- [x] Grey[50] for input backgrounds

---

## 🧪 TESTING CHECKLIST

### Definition of Done
- [ ] Navigate to DoD screen from project
- [ ] Create DoD as PO
- [ ] View DoD as team member
- [ ] DoD appears in new tasks
- [ ] Check off DoD items
- [ ] Progress updates correctly

### Retrospective
- [ ] Navigate to retro from completed sprint
- [ ] Add "Went Well" items
- [ ] Add "Needs Improvement" items
- [ ] Vote on items
- [ ] Create action items
- [ ] Check off completed actions

### Daily Standup
- [ ] Navigate to standup screen
- [ ] Submit daily update
- [ ] View team updates
- [ ] Add blockers
- [ ] Change date to view history
- [ ] See "already submitted" state

### Sprint Goal
- [ ] Create sprint with goal
- [ ] Goal appears in sprint details
- [ ] Goal shows in sprint list
- [ ] Goal visible in retrospective

---

## 🚀 DEPLOYMENT STEPS

1. **Integrate Navigation**
   - Add imports to relevant screens
   - Add navigation buttons/icons
   - Test navigation flow

2. **Test All Features**
   - Follow testing checklist
   - Test with multiple users
   - Test real-time updates

3. **Polish UI**
   - Ensure consistent styling
   - Add loading states
   - Handle empty states

4. **Hot Reload**
   - Save all files
   - Hot reload app
   - Test on device

---

**Status:** 🟢 Ready for Integration
**Estimated Time:** 2-3 hours for full integration
