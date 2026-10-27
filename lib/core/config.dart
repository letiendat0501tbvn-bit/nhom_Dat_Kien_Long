// Chọn nguồn dữ liệu: false (mặc định) dùng dữ liệu mẫu trong bộ nhớ (Mock), true dùng Firebase.
// Bật bằng: flutter run --dart-define=USE_FIREBASE=true
// Test luôn dùng Mock vì không truyền cờ này.
const kUseFirebase = bool.fromEnvironment('USE_FIREBASE');
