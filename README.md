# DAMobile - Scrum Project Management App

**Ứng dụng quản lý dự án Scrum chuyên nghiệp cho Mobile**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Realtime%20Database-orange.svg)](https://firebase.google.com/)
[![Scrum](https://img.shields.io/badge/Scrum-Compliant-green.svg)](https://scrumguides.org/)

## 🎯 Giới Thiệu

DAMobile là ứng dụng quản lý dự án theo phương pháp Scrum, được xây dựng với Flutter và Firebase. Ứng dụng hỗ trợ đầy đủ quy trình Scrum với **21/23 yếu tố cốt lõi** (9.5/10 điểm tuân thủ).

### ✨ Tính Năng Chính

#### 📋 Product & Sprint Backlog
- ✅ Quản lý User Stories với Story Points
- ✅ Product Backlog với prioritization
- ✅ Sprint Planning và Sprint Backlog
- ✅ Drag & Drop Kanban Board (TO DO, IN PROGRESS, DONE, VERIFIED)

#### 🎯 Sprint Management
- ✅ **Sprint Goal** - Mục tiêu rõ ràng cho mỗi sprint
- ✅ Time-boxed Sprints với auto-status updates
- ✅ Sprint Timeline và Countdown Timer
- ✅ Real-time collaboration

#### ✅ Definition of Done (DoD)
- ✅ Định nghĩa tiêu chí "Done" cho project
- ✅ DoD Checklist cho từng task
- ✅ Track DoD completion progress
- ✅ Quality assurance mechanism

#### 🔄 Sprint Retrospective
- ✅ Thu thập feedback sau mỗi sprint
- ✅ What went well / Needs improvement
- ✅ Team voting mechanism
- ✅ Action Items tracking
- ✅ Continuous improvement

#### 📊 Daily Scrum
- ✅ Daily Standup tracking
- ✅ Yesterday / Today / Blockers
- ✅ Team visibility
- ✅ Impediment tracking

#### 👥 Team Collaboration
- ✅ Role-based system (PO, SM, Dev)
- ✅ Task assignment và tracking
- ✅ Evidence upload cho completed tasks
- ✅ Real-time updates với Firebase
- ✅ Member management

#### 📈 Reporting & Analytics
- ✅ Dashboard với charts
- ✅ Sprint progress tracking
- ✅ Task status visualization
- ✅ Personal task management

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Firebase account
- Dart 2.17+

### Installation

1. Clone repository:
```bash
git clone https://github.com/yourusername/DAMobile.git
cd DAMobile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
- Tạo project trên Firebase Console
- Download `google-services.json` (Android) và `GoogleService-Info.plist` (iOS)
- Đặt vào thư mục tương ứng

4. Run app:
```bash
flutter run
```

## 📚 Documentation

- **[SCRUM_AUDIT_REPORT.md](SCRUM_AUDIT_REPORT.md)** - Báo cáo kiểm tra quy trình Scrum chi tiết
- **[SCRUM_IMPROVEMENT_GUIDE.md](SCRUM_IMPROVEMENT_GUIDE.md)** - Hướng dẫn cải thiện từng bước
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Tổng kết triển khai và hướng dẫn sử dụng
- **[TEST_GUIDE.md](TEST_GUIDE.md)** - Hướng dẫn chạy tests

## 🏗️ Architecture

### Models
- `Project` - Container cho dự án
- `Sprint` - Sprint với goal và timeline
- `UserStory` - Backlog items với story points
- `ProjectTask` - Tasks với DoD checklist
- `DefinitionOfDone` - DoD cho project
- `Retrospective` - Sprint retrospective data
- `DailyStandup` - Daily scrum updates

### Services
- `DatabaseService` - Firebase Realtime Database operations
- `AuthService` - Firebase Authentication
- `NotificationService` - Push notifications
- `ToastService` - In-app notifications

### Screens
- Dashboard - Personal overview
- Project List - All projects
- Project Details - Summary, Sprints, Backlog
- Sprint Details - Kanban board
- User Story Detail - Task management
- Retrospective - Sprint feedback
- Daily Standup - Daily updates
- Member Management - Team management

## 🎨 UI/UX Features

- ✨ Modern, clean design
- 🎯 Intuitive navigation
- 🖱️ Drag & Drop Kanban
- ⏱️ Countdown timers
- 📊 Charts và visualizations
- 🔔 Toast notifications
- 🔒 Lock/unlock states
- 📱 Responsive layout

## 🧪 Testing

Run all tests:
```bash
flutter test
```

Run with coverage:
```bash
flutter test --coverage
```

Xem chi tiết trong [TEST_GUIDE.md](TEST_GUIDE.md)

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^latest
  firebase_auth: ^latest
  firebase_database: ^latest
  google_fonts: ^latest
  fl_chart: ^latest
  drag_and_drop_lists: ^latest
  intl: ^latest
```

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines first.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Authors

- Your Name - Initial work

## 🙏 Acknowledgments

- Scrum.org for Scrum guidelines
- Flutter team for amazing framework
- Firebase for backend services

## 📞 Support

For support, email your-email@example.com or open an issue.

---

**Made with ❤️ using Flutter & Firebase**

**Scrum Compliance: 9.5/10** ⭐⭐⭐⭐⭐
