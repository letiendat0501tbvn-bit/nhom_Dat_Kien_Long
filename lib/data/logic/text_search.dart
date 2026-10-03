// Tìm kiếm không phân biệt dấu tiếng Việt và hoa thường (hàm thuần, dễ test).

// Mỗi chữ cái gốc kèm các dạng có dấu của nó.
const _accentGroups = <String, String>{
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

// Bảng tra ngược: chữ có dấu -> chữ gốc.
final Map<String, String> _baseLetter = {
  for (final entry in _accentGroups.entries)
    for (final ch in entry.value.split('')) ch: entry.key,
};

// Chuẩn hoá: chữ thường, bỏ dấu, "đ" thành "d", gộp khoảng trắng thừa.
// Vẫn xử lý được chữ gõ kiểu dấu rời (chữ gốc + dấu thanh ở ký tự riêng).
String normalizeVietnamese(String input) {
  final out = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    if (rune >= 0x0300 && rune <= 0x036F) continue; // dấu rời: bỏ
    final ch = String.fromCharCode(rune);
    out.write(_baseLetter[ch] ?? ch);
  }
  return out.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

// `text` khớp `query` khi MỌI từ của query đều xuất hiện trong text (sau chuẩn hoá),
// không cần đúng thứ tự. Query rỗng thì khớp tất cả.
bool matchesQuery(String text, String query) {
  final tokens =
      normalizeVietnamese(query).split(' ').where((t) => t.isNotEmpty);
  if (tokens.isEmpty) return true;
  final haystack = normalizeVietnamese(text);
  return tokens.every(haystack.contains);
}
