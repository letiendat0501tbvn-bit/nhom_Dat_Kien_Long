import 'dart:math';

// Hàm lấy "bây giờ": truyền vào được để test dùng giờ cố định.
typedef Clock = DateTime Function();

// Hàm cho biết độ trễ giả của mỗi thao tác.
typedef Latency = Duration Function();

final _random = Random();

DateTime systemClock() => DateTime.now();

// Độ trễ ngẫu nhiên 300–600 ms để thấy trạng thái đang tải (mục 9 SPEC).
Duration randomLatency() => Duration(milliseconds: 300 + _random.nextInt(301));

// Không trễ, dùng trong test.
Duration noLatency() => Duration.zero;
