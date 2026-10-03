import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/repositories/table_repository.dart';
import 'package:giua_ki_app/l10n/strings.dart';

void main() {
  group('bảng chuỗi VI/EN', () {
    test('mọi khoá đều có bản VI và bản EN, không rỗng', () {
      for (final key in StrKey.values) {
        expect(viStrings[key], isNotNull, reason: 'thiếu VI: ${key.name}');
        expect(enStrings[key], isNotNull, reason: 'thiếu EN: ${key.name}');
        expect(viStrings[key]!.trim(), isNotEmpty, reason: 'VI rỗng: ${key.name}');
        expect(enStrings[key]!.trim(), isNotEmpty, reason: 'EN rỗng: ${key.name}');
      }
    });

    test('hai bản có đúng cùng tập khoá, không thừa khoá lạ', () {
      expect(viStrings.keys.toSet(), StrKey.values.toSet());
      expect(enStrings.keys.toSet(), StrKey.values.toSet());
    });

    test('bản EN thật sự đã được dịch (trừ vài khoá giữ nguyên tên riêng)', () {
      // Tên app và tiêu đề có biểu tượng giữ nguyên ở cả hai ngôn ngữ.
      const same = {StrKey.appName, StrKey.appNameWithEyes};
      for (final key in StrKey.values.where((k) => !same.contains(k))) {
        expect(enStrings[key], isNot(viStrings[key]),
            reason: 'EN giống hệt VI: ${key.name}');
      }
    });

    test('Strings chọn đúng bản theo ngôn ngữ', () {
      const vi = Strings(AppLanguage.vi);
      const en = Strings(AppLanguage.en);
      expect(vi(StrKey.signIn), 'Đăng nhập');
      expect(en(StrKey.signIn), 'Sign in');
    });
  });

  group('thông báo lỗi bàn (TableError)', () {
    test('mỗi mã lỗi có thông báo riêng, ở cả hai ngôn ngữ', () {
      for (final lang in AppLanguage.values) {
        final t = Strings(lang);
        final messages = {for (final e in TableError.values) e: t.tableError(e)};
        for (final e in TableError.values) {
          expect(messages[e], isNotEmpty, reason: '${lang.name}/${e.name}');
        }
        // Không có hai lỗi nào dùng chung một câu (để giao diện báo đúng từng trường hợp)
        expect(messages.values.toSet().length, TableError.values.length,
            reason: lang.name);
      }
    });

    test('đã bắt đầu / đã huỷ / đã kết thúc là ba thông báo khác nhau', () {
      const t = Strings(AppLanguage.vi);
      expect(t.tableError(TableError.alreadyStarted), 'Bàn này đã bắt đầu rồi.');
      expect(t.tableError(TableError.cancelled), 'Bàn này đã bị huỷ.');
      expect(t.tableError(TableError.ended), 'Bàn này đã kết thúc.');
    });
  });

  group('nhãn danh mục', () {
    test('dịch 7 danh mục, danh mục lạ giữ nguyên', () {
      const vi = Strings(AppLanguage.vi);
      const en = Strings(AppLanguage.en);
      expect(vi.categoryLabel('Bún & mì'), 'Bún & mì');
      expect(en.categoryLabel('Bún & mì'), 'Noodles');
      expect(en.categoryLabel('Đồ uống'), 'Drinks');
      expect(en.categoryLabel('Danh mục lạ'), 'Danh mục lạ');
    });
  });

  // Chốt quy tắc "không viết cứng chữ trong widget": quét code giao diện, nếu thấy
  // ký tự tiếng Việt có dấu nằm ngoài chú thích thì báo lỗi.
  group('không viết cứng chữ tiếng Việt trong giao diện', () {
    final vietnamese = RegExp(
      '[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]',
      caseSensitive: false,
    );

    // Bỏ phần chú thích // ở cuối dòng (không có dấu // trong chuỗi ở các file này).
    String stripComment(String line) {
      final i = line.indexOf('//');
      return i < 0 ? line : line.substring(0, i);
    }

    for (final dir in ['lib/ui', 'lib/navigation']) {
      test('$dir sạch chuỗi cứng', () {
        final offenders = <String>[];
        for (final file in Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
          final lines = file.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            if (vietnamese.hasMatch(stripComment(lines[i]))) {
              offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
            }
          }
        }
        expect(offenders, isEmpty, reason: offenders.join('\n'));
      });
    }
  });
}
