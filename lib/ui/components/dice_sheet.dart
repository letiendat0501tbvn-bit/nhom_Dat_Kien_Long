import 'package:flutter/material.dart';

import '../../data/logic/dice_rules.dart';
import '../../data/models/dish.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../screens/dish_detail_screen.dart';
import '../theme/app_theme.dart';
import 'dish_image.dart';

// Bảng "Lắc món" (mục 4.10 SPEC), mở từ nút xúc xắc vàng ở thanh trên.
// Bấm "Quay món liền!" thì các món chạy qua rồi dừng ở một món ngẫu nhiên (AnimationController
// có sẵn của Flutter). Tôn trọng buổi ăn trong bộ lọc; nguồn ngẫu nhiên lấy từ AppState.random
// nên test truyền được Random cố định. Khi hệ thống bật "giảm hoạt ảnh" thì hiện kết quả ngay.
Future<void> showDiceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const DiceSheet(),
  );
}

class DiceSheet extends StatefulWidget {
  const DiceSheet({super.key});

  @override
  State<DiceSheet> createState() => _DiceSheetState();
}

class _DiceSheetState extends State<DiceSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  var _spinning = false; // đang tải món hoặc đang quay: chặn bấm đúp
  var _failed = false;
  var _fallback = false; // không có món hợp buổi ăn nên quay trong tất cả món
  var _spins = 0; // số lần quay xong, để chạy lại hiệu ứng "bật" khi ra kết quả
  var _reel = <Dish>[];
  Dish? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;
    final app = AppScope.of(context, listen: false);
    final instant = MediaQuery.disableAnimationsOf(context);
    setState(() {
      _spinning = true;
      _failed = false;
      _result = null;
    });
    try {
      final all = await app.dishRepository.getDishes();
      if (!mounted) return;
      final choice = dicePool(all, app.mealTime);
      if (choice.pool.isEmpty) throw StateError('no dishes to spin');
      final result = pickDish(choice.pool, app.random);
      _fallback = choice.fallback;
      _reel = diceReel(choice.pool, result, app.random);
      if (!instant) {
        await _controller.forward(from: 0);
        if (!mounted) return;
      }
      setState(() {
        _result = result;
        _spins++;
        _spinning = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _spinning = false;
      });
    }
  }

  // "Tìm bàn ăn": đóng bảng rồi mở Chi tiết món, cuộn tới phần bàn ăn.
  void _findTable(Dish dish) {
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => DishDetailScreen(dish: dish, scrollToTables: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final app = context.appState;
    final muted = TextStyle(
      fontSize: 16,
      color: AppColors.text.withValues(alpha: 0.75),
    );
    final meal = app.mealTime;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(StrKey.diceTitle),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(t(StrKey.diceLine1), style: muted),
          Text(t(StrKey.diceLine2), style: muted),
          if (meal != null) ...[
            const SizedBox(height: 8),
            Text(
              t.fill(
                _result != null && _fallback
                    ? StrKey.diceFallbackNote
                    : StrKey.diceMealNote,
                {'meal': t.mealTimeLabel(meal)},
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _stage(t),
          if (_failed) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Text(
                t(StrKey.dishesError),
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buttons(t),
        ],
      ),
    );
  }

  // Khu vực giữa: xúc xắc (chưa quay), dải món đang chạy, hoặc kết quả.
  Widget _stage(Strings t) {
    final result = _result;
    if (result != null) return _resultCard(t, result);
    if (_spinning && _reel.isNotEmpty) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final curved = Curves.easeOutCubic.transform(_controller.value);
          final i = (curved * (_reel.length - 1)).floor().clamp(
            0,
            _reel.length - 1,
          );
          // Tên món chạy nhanh không đọc cho trình đọc màn hình
          return ExcludeSemantics(
            child: Transform.rotate(
              angle: (1 - curved) * 0.35,
              child: DishImage(dish: _reel[i], radius: 24, emojiSize: 80),
            ),
          );
        },
      );
    }
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: const ExcludeSemantics(
          child: Icon(Icons.casino_outlined, size: 64, color: AppColors.text),
        ),
      ),
    );
  }

  Widget _resultCard(Strings t, Dish dish) {
    final instant = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      // Mỗi lần ra kết quả mới thì chạy lại hiệu ứng "bật" nhỏ
      key: ValueKey(_spins),
      tween: Tween(begin: instant ? 1 : 0.85, end: 1),
      duration: instant ? Duration.zero : const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DishImage(dish: dish, radius: 24, emojiSize: 80),
          const SizedBox(height: 12),
          // Vùng kết quả là live region: trình đọc màn hình đọc món vừa ra
          Semantics(
            liveRegion: true,
            label: t.fill(StrKey.diceResult, {'name': dish.name}),
            excludeSemantics: true,
            child: Text(
              dish.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dish.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buttons(Strings t) {
    final result = _result;
    if (result == null) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: _spinning ? null : _spin,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: const StadiumBorder(),
          ),
          child: Text(
            t(_spinning ? StrKey.diceSpinning : StrKey.diceSpin),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _spinning ? null : () => _findTable(result),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const StadiumBorder(),
              ),
              child: Text(
                t(StrKey.findTable),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: _spinning ? null : _spin,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: const StadiumBorder(),
              ),
              child: Text(
                t(StrKey.diceAgain),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
