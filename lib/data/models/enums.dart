// Các kiểu liệt kê dùng chung cho models.

// Buổi ăn (mục 7 SPEC). Khung giờ cụ thể sẽ xử lý ở phần logic lọc bàn.
enum MealTime { morning, noon, afternoon, evening, lateNight }

// Khẩu vị: 8 chip ở mục "Gợi ý cho bạn" (tab Hợp vị).
enum Taste {
  spicy, // Cay tê
  grilled, // Thịt nướng
  vegetarian, // Chay thanh đạm
  noodleSoup, // Sợi / Nước dùng
  rice, // Cơm dẻo
  seafood, // Hải sản
  sweet, // Chè ngọt
  coffee, // Cà phê đậm
}

// Tâm trạng: chip của tab Tâm trạng ở mục "Gợi ý cho bạn".
enum Mood {
  cozy, // Ấm bụng
  light, // Nhẹ nhàng
  social, // Tụ tập
  energetic, // Cần năng lượng
  sweetTooth, // Thèm ngọt
  refreshing, // Giải nhiệt
}

// Trạng thái bàn ăn.
enum TableStatus { open, full, ended, cancelled }

// Đối tượng bị báo cáo.
enum ReportTargetType { table, user, message }

// Lý do báo cáo (danh sách cố định). Lưu trong Report.reason dưới dạng tên enum.
enum ReportReason { spam, harassment, inappropriate, misinformation, other }

// Ngôn ngữ giao diện.
enum AppLanguage { vi, en }
