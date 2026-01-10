# Hướng Dẫn Chạy Test trong Flutter Project

## Các cách chạy test:

### 1. Chạy tất cả test
```bash
flutter test
```

### 2. Chạy test cụ thể theo tên
```bash
# Chạy test có tên chứa "Task"
flutter test --name="Task"

# Chạy test có tên chứa "Sprint"
flutter test --name="Sprint"
```

### 3. Chạy test với coverage (báo cáo độ bao phủ)
```bash
flutter test --coverage
```

Sau đó xem coverage report:
```bash
# Cài đặt lcov (nếu chưa có)
# Windows: choco install lcov
# Mac: brew install lcov
# Linux: sudo apt-get install lcov

# Xem coverage report
genhtml coverage/lcov.info -o coverage/html
# Mở file coverage/html/index.html trong browser
```

### 4. Chạy test với verbose output (chi tiết)
```bash
flutter test -v
```

### 5. Chạy test và dừng khi có lỗi đầu tiên
```bash
flutter test --fail-fast
```

### 6. Chạy test với reporter tùy chỉnh
```bash
# Compact (mặc định)
flutter test --reporter=compact

# Expanded (chi tiết hơn)
flutter test --reporter=expanded

# Chỉ hiển thị test fail
flutter test --reporter=failures-only

# JSON format (cho CI/CD)
flutter test --reporter=json --file-reporter=json:reports/tests.json
```

### 7. Chạy test với timeout tùy chỉnh
```bash
flutter test --timeout=60s
```

## Cấu trúc Test hiện tại:

### Test Models (`test/widget_test.dart`)
- ✅ Task Model Tests
  - Test tạo Task với giá trị đúng
  - Test parse Task từ Map
  
- ✅ ProjectTask Model Tests
  - Test tạo ProjectTask với giá trị đúng
  - Test parse ProjectTask từ Map
  
- ✅ Sprint Model Tests
  - Test tạo Sprint với giá trị đúng
  - Test tính toán Sprint.isActive
  
- ✅ UserStory Model Tests
  - Test tạo UserStory với giá trị đúng
  - Test parse UserStory từ Map

## Thêm Test mới:

### Tạo file test mới:
```bash
# Tạo file test mới trong thư mục test/
touch test/database_service_test.dart
```

### Ví dụ test cho DatabaseService:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled3/services/database_service.dart';

void main() {
  group('DatabaseService Tests', () {
    test('should create instance without uid', () {
      final service = DatabaseService();
      expect(service.uid, isNull);
    });

    test('should create instance with uid', () {
      final service = DatabaseService(uid: 'test-uid');
      expect(service.uid, 'test-uid');
    });
  });
}
```

## Chạy test trong IDE:

### VS Code / Cursor:
1. Mở file test
2. Click vào icon ▶️ bên cạnh test function
3. Hoặc dùng Command Palette: `Ctrl+Shift+P` → "Flutter: Run Tests"

### Android Studio / IntelliJ:
1. Mở file test
2. Click vào icon ▶️ bên cạnh test function
3. Hoặc click chuột phải → "Run 'test_name'"

## CI/CD Integration:

### GitHub Actions example:
```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.1'
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter test --reporter=json --file-reporter=json:reports/tests.json
```

## Best Practices:

1. **Đặt tên test rõ ràng**: Mô tả chính xác những gì test đang kiểm tra
2. **Nhóm test liên quan**: Sử dụng `group()` để nhóm các test liên quan
3. **Test độc lập**: Mỗi test không nên phụ thuộc vào test khác
4. **Test cả success và failure cases**: Test cả trường hợp thành công và thất bại
5. **Sử dụng setUp và tearDown**: Cho các test cần setup/cleanup

## Ví dụ Test với setUp/tearDown:

```dart
void main() {
  group('DatabaseService Tests', () {
    late DatabaseService service;

    setUp(() {
      // Chạy trước mỗi test
      service = DatabaseService(uid: 'test-uid');
    });

    tearDown(() {
      // Chạy sau mỗi test
      // Cleanup nếu cần
    });

    test('test 1', () {
      // Test code
    });

    test('test 2', () {
      // Test code
    });
  });
}
```

## Troubleshooting:

### Test không chạy:
```bash
# Xóa build cache
flutter clean
flutter pub get
flutter test
```

### Test timeout:
```bash
# Tăng timeout
flutter test --timeout=120s
```

### Test cần Firebase:
- Cần mock Firebase services hoặc dùng Firebase emulator
- Xem thêm: https://firebase.google.com/docs/emulator-suite
