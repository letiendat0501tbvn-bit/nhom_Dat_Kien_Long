// Hàm đọc giá trị từ Map<String, dynamic> (dữ liệu Firestore/JSON) thành kiểu Dart.
// Dùng trong các factory X.fromMap của model. Timestamp của Firestore đã được
// FirestoreRepo đổi thành DateTime trước khi tới đây.

DateTime readDate(Object? v) => v is DateTime ? v : DateTime.parse('$v');

DateTime? readDateOrNull(Object? v) => v == null ? null : readDate(v);

double readDouble(Object? v) => (v as num).toDouble();

int readInt(Object? v) => (v as num).toInt();

List<String> readStrings(Object? v) => [
  for (final x in (v as List?) ?? const []) '$x',
];

// Enum lưu bằng tên (chuỗi); tên lạ thì dùng giá trị dự phòng.
T readEnum<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

// Danh sách enum lưu bằng danh sách tên; tên lạ bị bỏ qua.
List<T> readEnums<T extends Enum>(List<T> values, Object? names) => [
  for (final n in readStrings(names))
    for (final v in values)
      if (v.name == n) v,
];
