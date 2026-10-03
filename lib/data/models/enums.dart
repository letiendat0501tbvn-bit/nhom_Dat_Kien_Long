// Các kiểu liệt kê dùng chung cho models.

// Buổi ăn (mục 7 SPEC). Khung giờ cụ thể sẽ xử lý ở phần logic lọc bàn.
enum MealTime { morning, noon, afternoon, evening, lateNight }

// Trạng thái bàn ăn.
enum TableStatus { open, full, ended, cancelled }

// Đối tượng bị báo cáo.
enum ReportTargetType { table, user, message }

// Ngôn ngữ giao diện.
enum AppLanguage { vi, en }
