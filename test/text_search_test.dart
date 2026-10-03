import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/logic/text_search.dart';
import 'package:giua_ki_app/data/mock_dishes.dart';
import 'package:giua_ki_app/data/mock/mock_support.dart';

void main() {
  group('normalizeVietnamese', () {
    test('bỏ dấu và chuyển chữ thường', () {
      expect(normalizeVietnamese('Phở'), 'pho');
      expect(normalizeVietnamese('Bánh xèo'), 'banh xeo');
      expect(normalizeVietnamese('Bún bò Huế'), 'bun bo hue');
      expect(normalizeVietnamese('Cơm tấm'), 'com tam');
      expect(normalizeVietnamese('Mì Quảng'), 'mi quang');
      expect(normalizeVietnamese('Sữa chua nếp cẩm'), 'sua chua nep cam');
    });

    test('đ và Đ thành d', () {
      expect(normalizeVietnamese('đ'), 'd');
      expect(normalizeVietnamese('Đ'), 'd');
      expect(normalizeVietnamese('Bún đậu mắm tôm'), 'bun dau mam tom');
      expect(normalizeVietnamese('ĐÂY TA'), 'day ta');
    });

    test('giữ nguyên chữ không dấu, số và ký tự khác', () {
      expect(normalizeVietnamese('abc 123 & xyz'), 'abc 123 & xyz');
    });

    test('gộp khoảng trắng thừa và cắt hai đầu', () {
      expect(normalizeVietnamese('  banh   xeo  '), 'banh xeo');
    });

    test('xử lý chữ gõ kiểu dấu rời (chữ gốc + dấu ở ký tự riêng)', () {
      // "Phở" = P h o + dấu móc (U+031B) + dấu hỏi (U+0309)
      expect(normalizeVietnamese('Phở'), 'pho');
      // "è" = e + dấu huyền (U+0300)
      expect(normalizeVietnamese('xèo'), 'xeo');
    });

    test('chuỗi rỗng', () {
      expect(normalizeVietnamese(''), '');
      expect(normalizeVietnamese('   '), '');
    });

    test('bao phủ mọi nguyên âm có dấu của tiếng Việt', () {
      const accented =
          'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹ';
      final result = normalizeVietnamese(accented);
      expect(RegExp(r'^[aeiouy]+$').hasMatch(result), isTrue, reason: result);
      expect(result.length, accented.length);
    });
  });

  group('matchesQuery', () {
    test('không dấu khớp có dấu', () {
      expect(matchesQuery('Phở', 'pho'), isTrue);
      expect(matchesQuery('Bánh xèo', 'banh xeo'), isTrue);
      expect(matchesQuery('Bún bò Huế', 'bun bo hue'), isTrue);
    });

    test('"d" khớp "đ"', () {
      expect(matchesQuery('Bún đậu mắm tôm', 'd'), isTrue);
      expect(matchesQuery('Bún đậu mắm tôm', 'dau'), isTrue);
      expect(matchesQuery('Bún đậu mắm tôm', 'đau'), isTrue);
    });

    test('gõ có dấu vẫn khớp, kể cả khi dữ liệu không dấu', () {
      expect(matchesQuery('Phở', 'phở'), isTrue);
      expect(matchesQuery('Pho', 'phở'), isTrue);
    });

    test('dấu thanh bị bỏ qua hoàn toàn: "phố" cũng ra "Phở"', () {
      expect(matchesQuery('Phở', 'phố'), isTrue);
    });

    test('không phân biệt hoa thường', () {
      expect(matchesQuery('Phở', 'PHO'), isTrue);
      expect(matchesQuery('Lẩu Thái', 'lau THAI'), isTrue);
    });

    test('khớp một phần của chữ', () {
      expect(matchesQuery('Bánh xèo', 'xe'), isTrue);
      expect(matchesQuery('Bánh xèo', 'ban'), isTrue);
    });

    test('nhiều từ: mọi từ đều phải có, không cần đúng thứ tự', () {
      expect(matchesQuery('Bánh xèo', 'xeo banh'), isTrue);
      expect(matchesQuery('Bánh xèo', 'banh mi'), isFalse);
    });

    test('query rỗng hoặc chỉ có khoảng trắng khớp tất cả', () {
      expect(matchesQuery('Phở', ''), isTrue);
      expect(matchesQuery('Phở', '   '), isTrue);
    });

    test('không khớp', () {
      expect(matchesQuery('Phở', 'lau'), isFalse);
      expect(matchesQuery('', 'pho'), isFalse);
    });
  });

  group('tìm món trong MockDishRepository', () {
    final repo = MockDishRepository(latency: noLatency);

    Future<List<String>> ids(String query) async =>
        (await repo.getDishes(query: query)).map((d) => d.id).toList();

    test('"pho" ra Phở và Phở chay', () async {
      expect(await ids('pho'), containsAll(['pho', 'pho-chay']));
    });

    test('"banh xeo" chỉ ra Bánh xèo', () async {
      expect(await ids('banh xeo'), ['banh-xeo']);
    });

    test('"bun cha" ra Bún chả', () async {
      expect(await ids('bun cha'), contains('bun-cha'));
    });

    test('"d" ra các món có chữ đ hoặc d trong tên', () async {
      final result = await ids('d');
      expect(result, contains('bun-dau-mam-tom')); // Bún đậu mắm tôm
      expect(result, contains('tra-dao')); // Trà đào
    });

    test('"HU TIEU" (hoa, không dấu) ra Hủ tiếu và Hủ tiếu gõ', () async {
      expect(await ids('HU TIEU'), containsAll(['hu-tieu', 'hu-tieu-go']));
    });

    test('query lạ trả về danh sách rỗng', () async {
      expect(await ids('xyz'), isEmpty);
    });
  });
}
