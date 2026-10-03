import '../data/models/enums.dart';

// Hàm định dạng số/ngày/giờ hiển thị (không chứa chữ cần dịch).

// Giờ hiển thị theo ngôn ngữ: tiếng Việt 24 giờ ("14:30"), tiếng Anh 12 giờ ("2:30 PM").
// `time` là giờ Việt Nam (xem DiningTable.startAt), hiển thị nguyên giá trị, không quy đổi.
String formatClockTime(DateTime time, AppLanguage language) {
  final mm = time.minute.toString().padLeft(2, '0');
  if (language == AppLanguage.vi) {
    return '${time.hour.toString().padLeft(2, '0')}:$mm';
  }
  final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$hour12:$mm ${time.hour < 12 ? 'AM' : 'PM'}';
}

// Phút trong ngày -> "HH:mm". Ví dụ 615 -> "10:15".
String formatMinuteOfDay(int minute) {
  final h = (minute ~/ 60).toString().padLeft(2, '0');
  final m = (minute % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

// Ngày -> "dd/MM". Ví dụ 5/10 -> "05/10".
String formatDayMonth(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m';
}

// Bán kính (mét) -> "100 m", "1 km", "10 km".
String formatRadius(int meters) =>
    meters >= 1000 ? '${meters ~/ 1000} km' : '$meters m';

// Hai ngày có cùng năm/tháng/ngày không (bỏ qua giờ).
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
