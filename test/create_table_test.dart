import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/logic/table_rules.dart';
import 'package:giua_ki_app/data/models/dining_table.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/repositories/table_repository.dart';
import 'package:giua_ki_app/l10n/strings.dart';
import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/state/app_state.dart';
import 'package:giua_ki_app/ui/components/new_table_fields.dart';
import 'package:giua_ki_app/ui/components/table_card.dart';
import 'package:giua_ki_app/ui/screens/create_table_screen.dart';
import 'package:giua_ki_app/ui/screens/dish_detail_screen.dart';

import 'test_helpers.dart';

const tall = Size(412, 3500);

// Mở app, (đăng nhập), rồi bấm nút + giữa thanh dưới để mở màn "Mở bàn mới".
Future<AppState> pumpCreate(
  WidgetTester tester, {
  AppState? app,
  bool area = true,
  bool login = false,
}) async {
  final state = app ?? makeAppStateWithTables(standardTables());
  if (area) state.selectArea('hcm-q1');
  await tester.pumpWidget(MyApp(appState: state));
  await tester.pumpAndSettle();
  if (login) {
    await tester.runAsync(state.signIn);
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  return state;
}

Future<void> pickTime(WidgetTester tester, String text) async {
  final chip = find.widgetWithText(ChoiceChip, text);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

Future<void> pickRestaurant(WidgetTester tester, [int index = 0]) async {
  final tile = find.byType(RestaurantTile).at(index);
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

// Điền form hợp lệ: quán đầu tiên, 11:00 hôm nay (các mặc định khác: 60 phút, 4 chỗ).
Future<void> fillValid(WidgetTester tester, {String time = '11:00'}) async {
  await pickRestaurant(tester);
  await pickTime(tester, time);
}

Future<void> review(WidgetTester tester) => tapText(tester, 'Xem lại');

Finder get openButton => find.widgetWithText(FilledButton, 'Mở bàn');

Future<List<DiningTable>> myTables(
  WidgetTester tester,
  AppState app,
  String userId,
) async =>
    (await tester.runAsync(() => app.tableRepository.getMyTables(userId)))!;

// TableRepository bọc MockTableRepository nhưng createTable chờ một "cổng" mở,
// để thử trạng thái đang gửi và bấm đúp.
class GatedTableRepository implements TableRepository {
  GatedTableRepository(this.inner);

  final TableRepository inner;
  final gate = Completer<void>();
  int createCalls = 0;

  @override
  Future<DiningTable> createTable({
    required String hostId,
    String? dishId,
    required String restaurantId,
    required DateTime startAt,
    required int durationMin,
    required int capacity,
    String note = '',
  }) async {
    createCalls++;
    await gate.future;
    return inner.createTable(
      hostId: hostId,
      dishId: dishId,
      restaurantId: restaurantId,
      startAt: startAt,
      durationMin: durationMin,
      capacity: capacity,
      note: note,
    );
  }

  @override
  Future<List<DiningTable>> getTables(TableQuery query) =>
      inner.getTables(query);
  @override
  Future<DiningTable?> getTable(String id) => inner.getTable(id);
  @override
  Future<List<DiningTable>> getMyTables(String userId) =>
      inner.getMyTables(userId);
  @override
  Future<DiningTable> joinTable(String tableId, String userId) =>
      inner.joinTable(tableId, userId);
  @override
  Future<DiningTable> leaveTable(String tableId, String userId) =>
      inner.leaveTable(tableId, userId);
  @override
  Future<DiningTable> cancelTable(String tableId, String userId) =>
      inner.cancelTable(tableId, userId);
}

void main() {
  const vi = Strings(AppLanguage.vi);
  final now = DateTime(2026, 10, 5, 10, 0);

  group('validateNewTableForm (quy tắc thuần)', () {
    Map<NewTableField, NewTableIssue> check({
      String? restaurantId = 'r',
      DateTime? startAt,
      int duration = 60,
      int capacity = 4,
      String note = '',
      bool overlaps = false,
    }) => validateNewTableForm(
      now: now,
      restaurantId: restaurantId,
      startAt: startAt ?? DateTime(2026, 10, 5, 11, 0),
      durationMin: duration,
      capacity: capacity,
      note: note,
      overlaps: overlaps,
    );

    test('form hợp lệ không có lỗi', () {
      expect(check(), isEmpty);
    });

    test('thiếu quán và thiếu giờ', () {
      final issues = validateNewTableForm(
        now: now,
        restaurantId: null,
        startAt: null,
        durationMin: 60,
        capacity: 4,
      );
      expect(issues, {
        NewTableField.restaurant: NewTableIssue.restaurantRequired,
        NewTableField.time: NewTableIssue.timeRequired,
      });
    });

    test('giờ trong quá khứ hoặc đúng bằng bây giờ là không hợp lệ', () {
      expect(
        check(startAt: DateTime(2026, 10, 5, 9, 45))[NewTableField.time],
        NewTableIssue.timePast,
      );
      expect(check(startAt: now)[NewTableField.time], NewTableIssue.timePast);
      expect(check(startAt: DateTime(2026, 10, 5, 10, 15)), isEmpty);
    });

    test('giờ không đúng bước 15 phút', () {
      expect(
        check(startAt: DateTime(2026, 10, 5, 11, 7))[NewTableField.time],
        NewTableIssue.timeStep,
      );
    });

    test('thời lượng ngoài 30–120 hoặc không chia hết 15', () {
      for (final d in [0, 15, 29, 45 + 1, 121, 135, 200]) {
        expect(
          check(duration: d)[NewTableField.duration],
          NewTableIssue.durationInvalid,
          reason: '$d phút',
        );
      }
      for (final d in [30, 45, 60, 90, 120]) {
        expect(check(duration: d), isEmpty, reason: '$d phút');
      }
    });

    test('số chỗ ngoài 2–8', () {
      for (final c in [-1, 0, 1, 9, 20]) {
        expect(
          check(capacity: c)[NewTableField.capacity],
          NewTableIssue.capacityInvalid,
          reason: '$c chỗ',
        );
      }
      for (final c in [2, 3, 8]) {
        expect(check(capacity: c), isEmpty, reason: '$c chỗ');
      }
    });

    test('ghi chú tối đa 140 ký tự', () {
      expect(check(note: 'a' * 140), isEmpty);
      expect(
        check(note: 'a' * 141)[NewTableField.note],
        NewTableIssue.noteTooLong,
      );
    });

    test('trùng giờ báo ở trường giờ; lỗi giờ khác được ưu tiên hơn', () {
      expect(check(overlaps: true)[NewTableField.time], NewTableIssue.overlap);
      expect(
        check(
          startAt: DateTime(2026, 10, 5, 9, 0),
          overlaps: true,
        )[NewTableField.time],
        NewTableIssue.timePast,
      );
    });

    test('nhiều lỗi cùng lúc: mỗi trường một lỗi', () {
      final issues = check(
        restaurantId: null,
        duration: 10,
        capacity: 1,
        note: 'a' * 200,
      );
      expect(issues.keys.toSet(), {
        NewTableField.restaurant,
        NewTableField.duration,
        NewTableField.capacity,
        NewTableField.note,
      });
    });

    test('mọi NewTableIssue đều có thông báo VI và EN khác rỗng', () {
      for (final lang in AppLanguage.values) {
        final t = Strings(lang);
        for (final issue in NewTableIssue.values) {
          expect(t.newTableIssue(issue), isNotEmpty, reason: issue.name);
          expect(t.newTableIssue(issue), isNot(issue.name));
        }
      }
    });

    test('hasOverlap với bàn dự kiến: chạm đầu mút không tính là trùng', () {
      final mine = makeTable(
        'm',
        start: DateTime(2026, 10, 5, 14, 0),
        members: ['u1'],
      ); // 14:00–15:00
      DiningTable at(int h, int m) =>
          makeTable('new', start: DateTime(2026, 10, 5, h, m), members: ['u1']);
      expect(hasOverlap([mine], 'u1', at(14, 30)), isTrue);
      expect(hasOverlap([mine], 'u1', at(13, 30)), isTrue); // 13:30–14:30
      expect(hasOverlap([mine], 'u1', at(15, 0)), isFalse);
      expect(hasOverlap([mine], 'u1', at(13, 0)), isFalse); // 13:00–14:00
    });
  });

  group('Mở màn', () {
    phoneTest('nút + mở màn toàn trang "Mở bàn mới", có nút Back', (
      tester,
    ) async {
      await pumpCreate(tester);
      expect(find.byType(CreateTableScreen), findsOneWidget);
      expect(find.text('Mở bàn mới'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      // Không phải một tab: thanh dưới không còn
      expect(find.text('Khám phá'), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(CreateTableScreen), findsNothing);
      expect(find.text('Chọn món để lên kèo'), findsWidgets);
    }, size: tall);

    phoneTest('khách vào được màn và điền được (không bị chặn đăng nhập)', (
      tester,
    ) async {
      final app = await pumpCreate(tester);
      expect(app.isLoggedIn, isFalse);
      await fillValid(tester);
      expect(find.text('Vào hội thôi!'), findsNothing);
      await review(tester);
      expect(find.text('Xác nhận mở bàn'), findsOneWidget);
      expect(find.text('Vào hội thôi!'), findsNothing); // chưa hỏi đăng nhập
    }, size: tall);

    phoneTest('có đủ các trường (a)-(f) và nút Xem lại', (tester) async {
      await pumpCreate(tester);
      for (final s in [
        'Món (không bắt buộc)',
        'Quán',
        'Ngày',
        'Giờ bắt đầu',
        'Thời lượng',
        'Số chỗ',
        'Ghi chú (không bắt buộc)',
        'Xem lại',
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      // Mặc định 60 phút, 4 chỗ, hôm nay
      expect(find.text('4 chỗ'), findsOneWidget);
      expect(find.text('Hôm nay · 05/10'), findsOneWidget);
    }, size: tall);

    phoneTest('thời lượng có 7 mức 30–120 phút theo bước 15', (tester) async {
      await pumpCreate(tester);
      for (final m in [30, 45, 60, 75, 90, 105, 120]) {
        expect(find.text('$m phút'), findsOneWidget, reason: '$m');
      }
    }, size: tall);

    phoneTest(
      'chưa chọn khu vực: hiện thẻ "Chọn khu vực"; chọn xong hiện quán',
      (tester) async {
        await pumpCreate(tester, area: false);
        expect(find.byType(RestaurantTile), findsNothing);
        await tester.tap(find.widgetWithText(FilledButton, 'Chọn khu vực'));
        await tester.pumpAndSettle();
        // Có hai chỗ ghi "Chọn khu vực" (tiêu đề thẻ và nút): bấm nút
        expect(find.text('Vị trí của bạn'), findsOneWidget);
        await tester.tap(find.text('Quận 1'));
        await tester.pumpAndSettle();
        expect(find.byType(RestaurantTile), findsWidgets);
        expect(find.byType(CreateTableScreen), findsOneWidget);
      },
      size: tall,
    );

    phoneTest('quán hiện đúng của khu vực đã chọn', (tester) async {
      final app = await pumpCreate(tester);
      final data = await tester.runAsync(
        () => app.locationRepository.getRestaurants(areaId: 'hcm-q1'),
      );
      expect(find.byType(RestaurantTile), findsNWidgets(data!.length));
      expect(find.text(data.first.name), findsOneWidget);
    }, size: tall);
  });

  group('Chọn món (tuỳ chọn, tìm không dấu)', () {
    phoneTest('gõ không dấu → chọn món → hiện món đã chọn → bỏ chọn', (
      tester,
    ) async {
      await pumpCreate(tester);
      await tester.enterText(find.byType(TextField).first, 'pho');
      await tester.pumpAndSettle();
      expect(find.text('Phở'), findsOneWidget);

      await tester.tap(find.text('Phở'));
      await tester.pumpAndSettle();
      expect(find.text('Phở'), findsOneWidget); // món đã chọn
      expect(find.byType(TextField), findsOneWidget); // chỉ còn ô ghi chú

      await tester.tap(find.byTooltip('Bỏ chọn món'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2)); // ô tìm món quay lại
    }, size: tall);

    phoneTest('không tìm thấy món nào', (tester) async {
      await pumpCreate(tester);
      await tester.enterText(find.byType(TextField).first, 'zzzzzz');
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy món nào.'), findsOneWidget);
    }, size: tall);

    phoneTest('bỏ trống món vẫn mở bàn được (bàn chưa có món)', (tester) async {
      final app = await pumpCreate(tester, login: true);
      await fillValid(tester);
      await review(tester);
      expect(find.text('Chưa chọn món'), findsOneWidget);
      await tester.tap(openButton);
      await tester.pumpAndSettle();
      final mine = await myTables(tester, app, 'u1');
      final created = mine.firstWhere((t) => t.id.startsWith('t1'));
      expect(created.dishId, isNull);
    }, size: tall);
  });

  group('Số chỗ 2–8, ghi chú, thời lượng', () {
    phoneTest('bộ tăng/giảm dừng ở 2 và 8', (tester) async {
      await pumpCreate(tester);
      Future<void> tapDec() async {
        await tester.ensureVisible(find.byTooltip('Giảm số chỗ'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Giảm số chỗ'));
        await tester.pumpAndSettle();
      }

      Future<void> tapInc() async {
        await tester.ensureVisible(find.byTooltip('Tăng số chỗ'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Tăng số chỗ'));
        await tester.pumpAndSettle();
      }

      await tapDec();
      await tapDec();
      expect(find.text('2 chỗ'), findsOneWidget);
      final dec = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.remove),
      );
      expect(dec.onPressed, isNull); // không xuống dưới 2

      for (var i = 0; i < 6; i++) {
        await tapInc();
      }
      expect(find.text('8 chỗ'), findsOneWidget);
      final inc = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.add),
      );
      expect(inc.onPressed, isNull); // không vượt 8
    }, size: tall);

    phoneTest('ghi chú bị giới hạn 140 ký tự', (tester) async {
      await pumpCreate(tester);
      final note = find.byType(TextField).last;
      await tester.ensureVisible(note);
      await tester.enterText(note, 'a' * 200);
      await tester.pumpAndSettle();
      final text = tester.widget<TextField>(note).controller!.text;
      expect(text.length, 140);
      expect(find.text('140/140'), findsOneWidget);
    }, size: tall);
  });

  group('Giờ: khung 15 phút, không cho chọn quá khứ', () {
    phoneTest('hôm nay: mốc đã qua bị khoá, mốc tương lai chọn được', (
      tester,
    ) async {
      await pumpCreate(tester);
      ChoiceChip chip(String s) =>
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, s));
      expect(chip('09:45').onSelected, isNull);
      expect(
        chip('10:00').onSelected,
        isNull,
      ); // đúng bằng bây giờ cũng không được
      expect(chip('10:15').onSelected, isNotNull);
      // Đủ 96 mốc, cách nhau 15 phút
      expect(find.byType(ChoiceChip), findsWidgets);
      expect(timeSlots().length, 96);
    }, size: tall);

    phoneTest('ngày mai: mọi mốc đều chọn được', (tester) async {
      await pumpCreate(tester);
      await tapText(tester, 'Ngày mai · 06/10');
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '00:00'),
      );
      expect(chip.onSelected, isNotNull);
    }, size: tall);

    phoneTest(
      'chọn giờ ngày mai rồi chuyển về hôm nay: báo giờ đã qua tại trường giờ',
      (tester) async {
        await pumpCreate(tester);
        await pickRestaurant(tester);
        await tapText(tester, 'Ngày mai · 06/10');
        await pickTime(tester, '08:00');
        await review(tester);
        expect(find.text('Xác nhận mở bàn'), findsOneWidget);
        await tester.pageBack(); // về form, dữ liệu còn nguyên
        await tester.pumpAndSettle();

        await tapText(tester, 'Hôm nay · 05/10');
        await review(tester);
        expect(find.text('Xác nhận mở bàn'), findsNothing);
        expect(find.text('Giờ bắt đầu phải ở tương lai.'), findsOneWidget);

        // Sửa lỗi thì lỗi biến mất ngay
        await pickTime(tester, '11:00');
        expect(find.text('Giờ bắt đầu phải ở tương lai.'), findsNothing);
      },
      size: tall,
    );

    phoneTest('chưa chọn giờ và quán: báo lỗi ngay tại từng trường', (
      tester,
    ) async {
      await pumpCreate(tester);
      await review(tester);
      expect(find.text('Chọn quán để mở bàn.'), findsOneWidget);
      expect(find.text('Chọn giờ bắt đầu.'), findsOneWidget);
      expect(find.text('Xác nhận mở bàn'), findsNothing);

      await pickRestaurant(tester);
      expect(find.text('Chọn quán để mở bàn.'), findsNothing);
      expect(find.text('Chọn giờ bắt đầu.'), findsOneWidget);
      await pickTime(tester, '12:30');
      expect(find.text('Chọn giờ bắt đầu.'), findsNothing);
    }, size: tall);
  });

  group('Trùng giờ', () {
    phoneTest(
      'đã ở bàn khác trùng giờ: báo lỗi ở trường giờ, không sang xác nhận',
      (tester) async {
        // u1 (Minh Anh) đã ở bàn tc 14:00–15:00
        await pumpCreate(tester, login: true);
        await fillValid(tester, time: '14:30');
        await review(tester);
        expect(find.text('Xác nhận mở bàn'), findsNothing);
        expect(find.text(vi.tableError(TableError.overlap)), findsOneWidget);

        // Đổi sang giờ không trùng thì qua được
        await pickTime(tester, '16:00');
        expect(find.text(vi.tableError(TableError.overlap)), findsNothing);
        await review(tester);
        expect(find.text('Xác nhận mở bàn'), findsOneWidget);
      },
      size: tall,
    );

    phoneTest('đổi thời lượng làm hết trùng thì cho qua', (tester) async {
      await pumpCreate(tester, login: true);
      await fillValid(
        tester,
        time: '13:00',
      ); // 13:00–14:00 chạm tc, không trùng
      await review(tester);
      expect(find.text('Xác nhận mở bàn'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapText(tester, '75 phút'); // 13:00–14:15 trùng tc
      await review(tester);
      expect(find.text('Xác nhận mở bàn'), findsNothing);
      expect(find.text(vi.tableError(TableError.overlap)), findsOneWidget);
    }, size: tall);

    phoneTest('khách không bị kiểm tra trùng giờ khi xem lại', (tester) async {
      await pumpCreate(tester);
      await fillValid(tester, time: '14:30');
      await review(tester);
      expect(find.text('Xác nhận mở bàn'), findsOneWidget);
    }, size: tall);
  });

  group('Màn xác nhận', () {
    phoneTest('tóm tắt đủ thông tin; Back và "Sửa lại" về form giữ dữ liệu', (
      tester,
    ) async {
      final app = await pumpCreate(tester);
      final data = await tester.runAsync(
        () => app.locationRepository.getRestaurants(areaId: 'hcm-q1'),
      );
      await tester.enterText(find.byType(TextField).first, 'pho');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phở'));
      await tester.pumpAndSettle();
      await pickRestaurant(tester, 1);
      await pickTime(tester, '11:00');
      await tapText(tester, '90 phút');
      final note = find.byType(TextField).last;
      await tester.ensureVisible(note);
      await tester.enterText(note, 'Ngồi gần cửa sổ');
      await tester.pumpAndSettle();
      await review(tester);

      expect(find.text('Xác nhận mở bàn'), findsOneWidget);
      expect(find.text('Phở'), findsOneWidget);
      expect(find.textContaining(data![1].name), findsOneWidget);
      expect(find.textContaining('11:00–12:30'), findsOneWidget);
      expect(find.textContaining('Hôm nay · 05/10'), findsOneWidget);
      expect(find.text('90 phút'), findsOneWidget);
      expect(find.text('4 chỗ (gồm bạn)'), findsOneWidget);
      expect(find.text('Ngồi gần cửa sổ'), findsOneWidget);

      await tester.pageBack(); // Back về form, không đóng màn
      await tester.pumpAndSettle();
      expect(find.byType(CreateTableScreen), findsOneWidget);
      expect(find.text('Xem lại'), findsOneWidget);
      expect(find.text('Ngồi gần cửa sổ'), findsOneWidget); // ghi chú còn
      final tile = tester.widget<RestaurantTile>(
        find.byType(RestaurantTile).at(1),
      );
      expect(tile.selected, isTrue);

      await review(tester);
      await tapText(tester, 'Sửa lại');
      expect(find.text('Xem lại'), findsOneWidget);
    }, size: tall);
  });

  group('Khách → đăng nhập → quay lại', () {
    phoneTest(
      'bấm "Mở bàn" mở bảng đăng nhập, giữ dữ liệu; đăng nhập xong KHÔNG tự mở bàn',
      (tester) async {
        final app = await pumpCreate(tester);
        await fillValid(tester, time: '15:30');
        await tapText(tester, '45 phút');
        await review(tester);

        await tester.tap(openButton);
        await tester.pumpAndSettle();
        expect(find.text('Vào hội thôi!'), findsOneWidget);
        expect(app.isLoggedIn, isFalse);

        await tester.tap(find.text('Tiếp tục với Google'));
        await tester.pumpAndSettle();

        // Quay lại đúng màn xác nhận, dữ liệu còn nguyên, chưa mở bàn nào
        expect(find.text('Vào hội thôi!'), findsNothing);
        expect(app.isLoggedIn, isTrue);
        expect(find.byType(CreateTableScreen), findsOneWidget);
        expect(find.text('Xác nhận mở bàn'), findsOneWidget);
        expect(find.textContaining('15:30–16:15'), findsOneWidget);
        expect(find.text('Đã mở bàn! Bạn là chủ bàn.'), findsNothing);
        final mine = await myTables(tester, app, 'u1');
        expect(mine.length, 1); // chỉ bàn tc có sẵn

        // Tự bấm lại thì mới mở
        await tester.tap(openButton);
        await tester.pumpAndSettle();
        expect(find.byType(CreateTableScreen), findsNothing);
        expect((await myTables(tester, app, 'u1')).length, 2);
      },
      size: tall,
    );

    phoneTest('đóng bảng đăng nhập: vẫn là khách, dữ liệu còn, chưa mở bàn', (
      tester,
    ) async {
      final app = await pumpCreate(tester);
      await fillValid(tester);
      await review(tester);
      await tester.tap(openButton);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 100)); // chạm ngoài bảng để đóng
      await tester.pumpAndSettle();
      expect(find.text('Vào hội thôi!'), findsNothing);
      expect(app.isLoggedIn, isFalse);
      expect(find.text('Xác nhận mở bàn'), findsOneWidget);
    }, size: tall);
  });

  group('Mở bàn thành công', () {
    phoneTest(
      'người mở là thành viên đầu tiên và chủ bàn; quay về Bàn ăn thấy bàn mới',
      (tester) async {
        final app = makeAppStateWithTables(standardTables())
          ..selectArea('hcm-q1');
        await tester.pumpWidget(MyApp(appState: app));
        await tester.pumpAndSettle();
        await tester.runAsync(app.signIn);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bàn ăn').first);
        await tester.pumpAndSettle();
        final before = tester
            .widgetList<TableCard>(find.byType(TableCard))
            .length;

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'bun bo');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bún bò Huế'));
        await tester.pumpAndSettle();
        await pickRestaurant(tester);
        await pickTime(tester, '19:00');
        await review(tester);
        await tester.tap(openButton);
        await tester.pumpAndSettle();

        // Đóng màn, quay về tab Bàn ăn, có thông báo
        expect(find.byType(CreateTableScreen), findsNothing);
        expect(find.text('Đã mở bàn! Bạn là chủ bàn.'), findsOneWidget);
        expect(find.text('Bàn còn chỗ'), findsOneWidget);

        // Danh sách tự làm mới: thấy thêm một bàn, bàn mới "Đã tham gia", còn 3/4
        final cards = tester
            .widgetList<TableCard>(find.byType(TableCard))
            .toList();
        expect(cards.length, before + 1);
        final created = cards.firstWhere((c) => c.table.dishId == 'bun-bo-hue');
        expect(created.table.hostId, 'u1');
        expect(created.table.memberIds, ['u1']);
        expect(created.table.capacity, 4);
        expect(created.table.durationMin, 60);
        expect(created.table.startAt, DateTime(2026, 10, 5, 19, 0));
        expect(created.joinState, TableJoinState.joined);
        expect(find.text('Còn 3/4 chỗ'), findsWidgets);

        // Trong kho dữ liệu cũng đúng
        final stored = await tester.runAsync(
          () => app.tableRepository.getTable(created.table.id),
        );
        expect(stored!.hostId, 'u1');
        expect(stored.memberIds.first, 'u1');
      },
      size: tall,
    );

    phoneTest('bàn mở với ghi chú và số chỗ đã chọn', (tester) async {
      final app = await pumpCreate(tester, login: true);
      await fillValid(tester, time: '18:00');
      await tapText(tester, '120 phút');
      await tapText(
        tester,
        'Tăng số chỗ'.isEmpty ? '' : '4 chỗ',
      ); // không đổi gì
      await tester.tap(find.byTooltip('Tăng số chỗ'));
      await tester.pumpAndSettle();
      final note = find.byType(TextField).last;
      await tester.ensureVisible(note);
      await tester.enterText(note, '  Mang theo ô nhé  ');
      await tester.pumpAndSettle();
      await review(tester);
      await tester.tap(openButton);
      await tester.pumpAndSettle();

      final mine = await myTables(tester, app, 'u1');
      final t = mine.firstWhere((t) => t.id.startsWith('t1'));
      expect(t.capacity, 5);
      expect(t.durationMin, 120);
      expect(t.note, 'Mang theo ô nhé'); // đã cắt khoảng trắng hai đầu
      expect(t.hostId, 'u1');
    }, size: tall);
  });

  group('Nhận món từ nơi khác', () {
    phoneTest(
      'nút "Mở bàn mới với món này" mở màn với món đã chọn sẵn; mở xong thấy bàn ở chi tiết món',
      (tester) async {
        final app = makeAppStateWithTables(standardTables())
          ..selectArea('hcm-q1');
        await tester.runAsync(app.load);
        await tester.runAsync(app.signIn);
        final dish = (await tester.runAsync(
          () => app.dishRepository.getDish('com-tam'),
        ))!;
        await tester.pumpWidget(MyApp(appState: app));
        await tester.pumpAndSettle();
        openDishDetail(tester.element(find.byType(Scaffold).first), dish);
        await tester.pumpAndSettle();
        expect(
          find.text('Mở bàn mới với món này'),
          findsOneWidget,
        ); // đang rỗng

        await tester.tap(find.text('Mở bàn mới với món này'));
        await tester.pumpAndSettle();
        expect(find.byType(CreateTableScreen), findsOneWidget);
        expect(find.text('Cơm tấm'), findsOneWidget); // món chọn sẵn
        expect(find.byTooltip('Bỏ chọn món'), findsOneWidget);

        await fillValid(tester, time: '20:00');
        await review(tester);
        expect(find.text('Cơm tấm'), findsOneWidget);
        await tester.tap(openButton);
        await tester.pumpAndSettle();

        // Về màn chi tiết món, danh sách tự làm mới và có bàn mới của món này
        expect(find.byType(CreateTableScreen), findsNothing);
        expect(find.byType(DishDetailScreen), findsOneWidget);
        expect(find.text('Mở bàn mới với món này'), findsNothing);
        final cards = tester
            .widgetList<TableCard>(find.byType(TableCard))
            .toList();
        expect(cards.length, 1);
        expect(cards.single.table.dishId, 'com-tam');
        expect(cards.single.table.hostId, 'u1');
      },
      size: tall,
    );

    phoneTest('trạng thái rỗng của danh sách bàn có nút "Mở bàn mới" mở màn', (
      tester,
    ) async {
      final app = makeAppStateWithTables(standardTables())
        ..selectArea('hcm-q1')
        ..setRadius(100);
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bàn ăn').first);
      await tester.pumpAndSettle();
      expect(find.byType(TableCard), findsNothing);

      await tester.tap(find.text('Mở bàn mới'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateTableScreen), findsOneWidget);
      expect(
        find.byTooltip('Bỏ chọn món'),
        findsNothing,
      ); // không có món chọn sẵn
    }, size: tall);
  });

  group('Lỗi từ repository và gửi yêu cầu', () {
    for (final entry in {
      TableError.invalidTime: NewTableField.time,
      TableError.overlap: NewTableField.time,
      TableError.invalidCapacity: NewTableField.capacity,
    }.entries) {
      phoneTest(
        '${entry.key.name}: quay về form, báo đúng thông báo tại trường',
        (tester) async {
          final repo = ThrowingTableRepository(createError: entry.key);
          final app = makeAppStateWithTables(const [], tableRepository: repo);
          await pumpCreate(tester, app: app, login: true);
          await fillValid(tester);
          await review(tester);
          await tester.tap(openButton);
          await tester.pumpAndSettle();

          expect(repo.createCalls, 1);
          expect(find.byType(CreateTableScreen), findsOneWidget);
          expect(find.text('Xem lại'), findsOneWidget); // đã về form
          expect(find.text(vi.tableError(entry.key)), findsOneWidget);

          // Sửa trường thì lỗi của server biến mất
          if (entry.value == NewTableField.time) {
            await pickTime(tester, '12:00');
          } else {
            await tester.ensureVisible(find.byTooltip('Tăng số chỗ'));
            await tester.tap(find.byTooltip('Tăng số chỗ'));
            await tester.pumpAndSettle();
          }
          expect(find.text(vi.tableError(entry.key)), findsNothing);
        },
        size: tall,
      );
    }

    for (final e in [
      TableError.full,
      TableError.notFound,
      TableError.cancelled,
    ]) {
      phoneTest('${e.name}: ở lại màn xác nhận và hiện thông báo riêng', (
        tester,
      ) async {
        final repo = ThrowingTableRepository(createError: e);
        final app = makeAppStateWithTables(const [], tableRepository: repo);
        await pumpCreate(tester, app: app, login: true);
        await fillValid(tester);
        await review(tester);
        await tester.tap(openButton);
        await tester.pumpAndSettle();
        expect(find.text('Xác nhận mở bàn'), findsOneWidget);
        expect(find.text(vi.tableError(e)), findsOneWidget);
        // Nút bấm lại được
        expect(tester.widget<FilledButton>(openButton).onPressed, isNotNull);
      }, size: tall);
    }

    phoneTest('lỗi bất ngờ: báo lỗi chung, không đóng màn', (tester) async {
      final repo = ThrowingTableRepository();
      final app = makeAppStateWithTables(const [], tableRepository: repo);
      await pumpCreate(tester, app: app, login: true);
      await fillValid(tester);
      await review(tester);
      await tester.tap(openButton);
      await tester.pumpAndSettle();
      expect(find.text('Chưa mở được bàn. Thử lại nhé.'), findsOneWidget);
      expect(find.byType(CreateTableScreen), findsOneWidget);
    }, size: tall);

    phoneTest('đang gửi: nút có vòng xoay, bấm đúp chỉ gửi một lần', (
      tester,
    ) async {
      final base = makeAppStateWithTables(standardTables());
      final data = await tester.runAsync(
        () => base.tableRepository.getMyTables('u1'),
      );
      expect(data, isNotNull);
      final gated = GatedTableRepository(base.tableRepository);
      final app = makeAppStateWithTables(const [], tableRepository: gated);
      await pumpCreate(tester, app: app, login: true);
      await fillValid(tester, time: '17:00');
      await review(tester);

      await tester.tap(openButton);
      await tester.pump();
      // Đang gửi: vòng xoay, nút không bấm được
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Mở bàn'), findsNothing);
      final spinnerButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(spinnerButton.onPressed, isNull);
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(gated.createCalls, 1);

      // Nút Back/Sửa lại cũng bị khoá trong lúc gửi
      final edit = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(edit.onPressed, isNull);

      gated.gate.complete();
      await tester.pumpAndSettle();
      expect(gated.createCalls, 1);
      expect(find.byType(CreateTableScreen), findsNothing);
    }, size: tall);
  });

  group('Nhãn ngữ nghĩa', () {
    // Tên của điều khiển cho trình đọc màn hình: nhãn hoặc tooltip
    String nameOf(WidgetTester tester, Finder f) {
      final d = tester.getSemantics(f).getSemanticsData();
      return '${d.label} ${d.tooltip}';
    }

    phoneTest('mọi điều khiển chính có nhãn (VI)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCreate(tester);
      expect(find.bySemanticsLabel('Mở bàn mới'), findsWidgets);
      expect(
        nameOf(tester, find.widgetWithIcon(IconButton, Icons.add)),
        contains('Tăng số chỗ'),
      );
      expect(
        nameOf(tester, find.widgetWithIcon(IconButton, Icons.remove)),
        contains('Giảm số chỗ'),
      );
      expect(find.bySemanticsLabel(RegExp('Xem lại')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Tìm món ăn')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('^11:00')), findsWidgets);
      handle.dispose();
    }, size: tall);

    phoneTest('quán là một mục có nhãn tên + địa chỉ và trạng thái selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final app = await pumpCreate(tester);
      final data = await tester.runAsync(
        () => app.locationRepository.getRestaurants(areaId: 'hcm-q1'),
      );
      final node = find
          .descendant(
            of: find.byType(RestaurantTile).first,
            matching: find.byType(MergeSemantics),
          )
          .first;
      var d = tester.getSemantics(node).getSemanticsData();
      expect(d.label, contains(data!.first.name));
      expect(d.label, contains(data.first.address));
      expect(d.flagsCollection.isSelected, isNot(Tristate.isTrue));

      await pickRestaurant(tester);
      d = tester.getSemantics(node).getSemanticsData();
      expect(d.flagsCollection.isSelected, Tristate.isTrue);
      handle.dispose();
    }, size: tall);
  });

  group('Tiếng Anh', () {
    phoneTest('toàn bộ chữ của màn là tiếng Anh', (tester) async {
      final app = makeAppStateWithTables(standardTables())
        ..setLanguage(AppLanguage.en);
      await pumpCreate(tester, app: app);
      for (final s in [
        'Open a new table',
        'Dish (optional)',
        'Venue',
        'Date',
        'Start time',
        'Duration',
        'Seats',
        'Note (optional)',
        'Review',
        '4 seats',
        'Today · 05/10',
      ]) {
        expect(find.text(s), findsWidgets, reason: s);
      }
      expect(find.text('11:00 AM'), findsOneWidget);

      await tapText(tester, 'Review');
      expect(find.text('Pick a venue for your table.'), findsOneWidget);
      expect(find.text('Pick a start time.'), findsOneWidget);

      await pickRestaurant(tester);
      await pickTime(tester, '1:00 PM');
      await tapText(tester, 'Review');
      expect(find.text('Confirm your table'), findsOneWidget);
      expect(find.textContaining('1:00 PM–2:00 PM'), findsOneWidget);
      expect(find.text('4 seats (including you)'), findsOneWidget);
      expect(find.text('No dish chosen yet'), findsOneWidget);
    }, size: tall);
  });

  group('Không tràn dòng', () {
    for (final language in AppLanguage.values) {
      for (final scale in [1.0, 1.3]) {
        for (final width in [360.0, 412.0]) {
          phoneTest('${language.name}, chữ x$scale, rộng ${width.toInt()}', (
            tester,
          ) async {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.platformDispatcher.clearAllTestValues);
            final app = makeAppStateWithTables(standardTables())
              ..setLanguage(language);
            final t = app.strings;
            await pumpCreate(tester, app: app, login: true);

            // Form với lỗi hiện ra
            await tapText(tester, t(StrKey.ntReview));
            expect(find.text(t(StrKey.ntErrRestaurant)), findsOneWidget);

            // Có món đã chọn, ghi chú dài, số chỗ lớn
            await tester.enterText(find.byType(TextField).first, 'pho');
            await tester.pumpAndSettle();
            await tester.tap(find.text('Phở'));
            await tester.pumpAndSettle();
            final note = find.byType(TextField).last;
            await tester.ensureVisible(note);
            await tester.enterText(note, 'Ghi chú khá dài ' * 8);
            await tester.pumpAndSettle();
            await pickRestaurant(tester);
            await tester.ensureVisible(find.byTooltip(t(StrKey.ntSeatsInc)));
            await tester.tap(find.byTooltip(t(StrKey.ntSeatsInc)));
            await tester.pumpAndSettle();
            await pickTime(
              tester,
              language == AppLanguage.vi ? '11:00' : '11:00 AM',
            );

            // Báo lỗi trùng giờ rồi sang màn xác nhận
            await tapText(tester, t(StrKey.ntReview));
            expect(find.text(t(StrKey.ntConfirmTitle)), findsOneWidget);
            expect(tester.takeException(), isNull);
          }, size: Size(width, 3500));
        }
      }
    }
  });
}
