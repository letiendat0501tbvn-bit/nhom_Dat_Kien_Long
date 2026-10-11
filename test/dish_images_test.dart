import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/dish_images.dart';
import 'package:giua_ki_app/data/mock_dishes.dart';
import 'package:giua_ki_app/data/models/dish.dart';
import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/ui/components/app_logo.dart';
import 'package:giua_ki_app/ui/components/dish_image.dart';

import 'test_helpers.dart';

Dish dishWith(String? asset, {String id = 'x'}) => Dish(
  id: id,
  name: 'Món $id',
  category: 'Bún & mì',
  description: 'mô tả',
  emoji: '🍜',
  tint: 0xFFEADFCB,
  imageAsset: asset,
);

Widget host(Widget child, {double width = 412}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

// Cho phép tải asset thật (bất đồng bộ) rồi dựng lại.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('Đường dẫn ảnh của món mẫu', () {
    test(
      'món có file thì có đường dẫn; ca-phe dùng cafe.jpg; cao-lau chưa có ảnh',
      () {
        final byId = {for (final d in kMockDishes) d.id: d};
        expect(byId['pho']!.imageAsset, 'assets/images/dishes/Pho.jpg');
        expect(
          byId['banh-beo']!.imageAsset,
          'assets/images/dishes/Banh-beo.png',
        );
        expect(byId['ca-phe']!.imageAsset, 'assets/images/dishes/cafe.jpg');
        expect(byId['cao-lau']!.imageAsset, isNull);
        expect(dishImageAsset('khong-co'), isNull);
      },
    );

    test('thông báo món nào chưa có ảnh (chỉ in danh sách, không làm hỏng test)', () {
      final dir = Directory('assets/images/dishes');
      final files = dir.existsSync()
          ? [for (final f in dir.listSync()) f.uri.pathSegments.last]
          : <String>[];
      final fileSet = files.toSet();
      final noFile = <String>[];
      final brokenMap = <String>[];
      for (final d in kMockDishes) {
        final asset = d.imageAsset;
        if (asset == null) {
          noFile.add('${d.id} (${d.name})');
        } else if (!fileSet.contains(asset.split('/').last)) {
          brokenMap.add('${d.id} -> $asset');
        }
      }
      final mapped = kDishImageFiles.values.toSet();
      final unmapped = [
        for (final f in files)
          if (!mapped.contains(f)) f,
      ];
      String list(List<String> l) => l.isEmpty ? '(không)' : l.join(', ');
      // ignore: avoid_print
      print(
        'Ảnh món: ${files.length} file trong ${dir.path}; '
        '${kMockDishes.length - noFile.length}/${kMockDishes.length} món có ảnh.\n'
        '  Món CHƯA có ảnh (dùng ô màu + emoji): ${list(noFile)}\n'
        '  Món trỏ tới file không tồn tại: ${list(brokenMap)}\n'
        '  File chưa gắn với món nào: ${list(unmapped)}',
      );
    });
  });

  group('DishImage', () {
    testWidgets(
      'món có ảnh: hiện Image đúng asset, giải mã theo kích thước hiển thị',
      (tester) async {
        await tester.pumpWidget(
          host(
            DishImage(
              dish: dishWith('assets/images/dishes/Pho.jpg', id: 'pho'),
            ),
          ),
        );
        await settle(tester);
        final image = tester.widget<Image>(find.byType(Image));
        expect(image.image, isA<ResizeImage>());
        final resize = image.image as ResizeImage;
        expect(
          (resize.imageProvider as AssetImage).assetName,
          'assets/images/dishes/Pho.jpg',
        );
        // Không giải mã cả ảnh gốc nhiều MB: chiều rộng giải mã bị chặn
        expect(resize.width, isNotNull);
        expect(resize.width!, lessThanOrEqualTo(1200));
        expect(image.fit, BoxFit.cover);
        // Ô màu + emoji vẫn nằm bên dưới làm nền
        expect(find.text('🍜'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('món chưa có ảnh: chỉ có placeholder, không có Image', (
      tester,
    ) async {
      await tester.pumpWidget(host(DishImage(dish: dishWith(null))));
      await settle(tester);
      expect(find.byType(Image), findsNothing);
      expect(find.text('🍜'), findsOneWidget);
    });

    testWidgets('file ảnh không tồn tại: không báo lỗi, vẫn thấy placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          DishImage(dish: dishWith('assets/images/dishes/khong-co-file.jpg')),
        ),
      );
      await settle(tester);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('🍜'), findsOneWidget);
    });

    testWidgets('giữ tỉ lệ 4:3 và bo góc dù có ảnh hay không', (tester) async {
      for (final asset in [null, 'assets/images/dishes/Pho.jpg']) {
        await tester.pumpWidget(host(DishImage(dish: dishWith(asset))));
        await settle(tester);
        final size = tester.getSize(find.byType(DishImage));
        expect(size.width / size.height, closeTo(4 / 3, 0.01));
        expect(find.byType(ClipRRect), findsWidgets);
      }
    });

    testWidgets(
      'nhãn ngữ nghĩa giữ như cũ: ảnh lớn có tên món, ảnh trong thẻ thì không',
      (tester) async {
        final handle = tester.ensureSemantics();
        final d = dishWith('assets/images/dishes/Pho.jpg', id: 'pho');
        await tester.pumpWidget(host(DishImage(dish: d)));
        await settle(tester);
        expect(find.bySemanticsLabel('Món pho'), findsOneWidget);

        await tester.pumpWidget(
          host(DishImage(dish: d, excludeFromSemantics: true)),
        );
        await settle(tester);
        expect(find.bySemanticsLabel('Món pho'), findsNothing);
        handle.dispose();
      },
    );

    for (final width in [360.0, 412.0]) {
      testWidgets(
        'không tràn dòng, rộng ${width.toInt()}, chữ phóng 1,3, kèm nhãn ở góc',
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 1.3;
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          await tester.pumpWidget(
            host(
              Row(
                children: [
                  Expanded(
                    child: DishImage(
                      dish: dishWith('assets/images/dishes/Pho.jpg'),
                      overlay: const Positioned(
                        top: 8,
                        left: 8,
                        child: ImageLabel('Bún & mì'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: DishImage(dish: dishWith(null))),
                ],
              ),
              width: width,
            ),
          );
          await settle(tester);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('Ảnh thật trong app', () {
    phoneTest('Khám phá: thẻ món có ảnh hiện Image, không lỗi', (tester) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();
      await settle(tester);
      expect(find.byType(Image), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Logo', () {
    final hasLogo = File(AppLogo.asset).existsSync();

    testWidgets(
      hasLogo ? 'có assets/images/logo.png: hiện ảnh logo' : 'chưa có assets/images/logo.png: hiện biểu tượng tạm, không báo lỗi',
      (tester) async {
        await tester.pumpWidget(host(const AppLogo()));
        await settle(tester);
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(
          find.byIcon(Icons.ramen_dining),
          hasLogo ? findsNothing : findsOneWidget,
        );
      },
    );

    phoneTest('thanh trên và chân trang Hồ sơ dùng AppLogo', (tester) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();
      expect(find.byType(AppLogo), findsOneWidget);
      await tester.tap(find.text('Tôi').last);
      await tester.pumpAndSettle();
      expect(find.byType(AppLogo), findsNWidgets(2)); // thanh trên + chân trang
    });
  });
}
