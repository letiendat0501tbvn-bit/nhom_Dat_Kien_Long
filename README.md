# Ăn Gì Đây Ta?

Ứng dụng di động (Flutter) giúp bạn **chọn món Việt và hẹn ăn cùng người khác ngay tại quán**: chọn món, xem các bàn theo giờ hẹn và số chỗ còn trống, rồi tham gia hoặc mở bàn mới. Đây **không** phải dịch vụ giao đồ ăn. Khẩu hiệu: "Món ngon • Bạn mới • Kết nối thật".

Dự án là đồ án môn Lập trình thiết bị di động. Ứng dụng chạy hoàn toàn với **dữ liệu mẫu** trong bộ nhớ (chưa có máy chủ thật), xem mục "Phần giả lập" bên dưới.

## Chức năng

- **Khám phá:** lưới 56 món, tìm kiếm không phân biệt dấu, bộ lọc buổi ăn, mục "Gợi ý cho bạn" (khẩu vị, tâm trạng, đang hot), dải "ba miền", xem tất cả món.
- **Lắc món:** nút xúc xắc vàng ở thanh trên, quay ngẫu nhiên một món (theo buổi ăn nếu có chọn), có hoạt ảnh và tôn trọng cài đặt giảm hoạt ảnh của hệ thống.
- **Chi tiết món:** mô tả, khẩu vị, tâm trạng và các bàn đang mở cho món đó.
- **Bàn ăn:** chọn khu vực, lọc theo bán kính, buổi ăn, khung giờ, ngày; thẻ bàn có số chỗ còn trống; tham gia bàn.
- **Mở bàn mới (nút +):** chọn món (tuỳ chọn), quán, ngày giờ theo khung 15 phút, thời lượng 30–120 phút, số chỗ 2–8, ghi chú; có màn xác nhận.
- **Chi tiết bàn:** thành viên (chỉ hiện khi đã đăng nhập), tham gia, rời bàn, huỷ bàn (chủ bàn), trò chuyện trong bàn (chỉ thành viên).
- **An toàn:** báo cáo bàn, người dùng, tin nhắn; chặn và bỏ chặn người dùng (bàn và tin nhắn của người bị chặn bị ẩn).
- **Hồ sơ:** "Bàn của tôi" (sắp tới / đã qua), phản hồi riêng tư, báo cáo đã gửi, danh sách chặn, đăng xuất, các trang thông tin.
- **Hai ngôn ngữ:** tiếng Việt và tiếng Anh, đổi bằng nút EN/VI ở thanh trên.
- Khách chưa đăng nhập vẫn xem, lọc và điền form; các thao tác cần quyền sẽ mở bảng đăng nhập (đăng nhập xong không tự tham gia hay tự mở bàn).

## Cài đặt và chạy

Yêu cầu: Flutter SDK (Dart ^3.13), và Chrome hoặc thiết bị/máy ảo Android.

```bash
flutter pub get

# Chạy trên Chrome
flutter run -d chrome

# Chạy trên thiết bị hoặc máy ảo Android (xem danh sách bằng: flutter devices)
flutter run -d <ma-thiet-bi>

# Đóng gói
flutter build web
flutter build apk --debug
```

## Chạy kiểm thử

```bash
flutter analyze
flutter test
```

Bộ test gồm test thuần cho các quy tắc nghiệp vụ, test repository mẫu và test giao diện (cả tiếng Việt và tiếng Anh, khổ 360/412 và chữ phóng 1,3 lần). Có test kiểm tra không còn chuỗi chữ viết cứng trong giao diện và không còn khoá chuỗi mồ côi. Danh sách kiểm thử thủ công nằm ở `docs/CHECKLIST.md`.

## Cấu trúc thư mục

```
lib/
  main.dart               điểm vào, MaterialApp, AppScope
  state/                  AppState (ChangeNotifier) và AppScope (InheritedNotifier)
  l10n/                   chuỗi chữ VI/EN (strings.dart) và hàm định dạng ngày giờ
  navigation/             khung chính và thanh dưới
  data/
    models/               model: món, bàn, quán, người dùng, tin nhắn, báo cáo...
    repositories/         các interface (abstract) và bản Mock tương ứng
    logic/                quy tắc nghiệp vụ thuần: lọc bàn, kiểm tra giờ/số chỗ, tìm không dấu...
    mock/                 dữ liệu mẫu và độ trễ giả
    mock_dishes.dart      56 món mẫu và MockDishRepository
  ui/
    theme/                màu và theme
    components/           thành phần dùng chung (thẻ món, thẻ bàn, bảng lọc, chat...)
    screens/              các màn hình
test/                     test thuần, repository và giao diện
design/                   ảnh thiết kế tham chiếu
```

## Dữ liệu mẫu và phần giả lập

Những phần sau là **giả lập để demo**, không phải dịch vụ thật:

- **Dữ liệu mẫu:** 56 món, các khu vực (Hà Nội, TP.HCM), quán, người dùng và bàn ăn được sinh trong bộ nhớ lúc mở app (giờ của bàn tính từ thời điểm hiện tại). Tên người dùng là tên giả. Mọi thay đổi mất khi tắt app.
- **Đăng nhập giả lập:** nút "Tiếp tục với Google" luôn đăng nhập thành người dùng mẫu "Minh Anh" (không dùng tài khoản Google thật, không có mật khẩu).
- **Phản hồi chat tự động:** sau khi bạn gửi tin trong bàn, một thành viên khác của bàn tự trả lời bằng một câu có sẵn sau 1–2 giây (chỉ để demo, nằm trong `MockChatRepository`).
- **Độ trễ:** mỗi thao tác có độ trễ ngẫu nhiên 300–600 ms để thấy trạng thái đang tải.
- **Vị trí:** chưa dùng vị trí thật; "Cho phép vị trí" chỉ báo sẽ có ở bản sau. Khu vực chọn thủ công.
- **Ảnh món và logo:** là ô màu kèm biểu tượng tạm, chưa có ảnh thật.
- **Các trang thông tin** (Giới thiệu, Liên hệ, Chính sách quyền riêng tư, Điều khoản sử dụng): nội dung mẫu ngắn, có ghi chú trên màn. Nhóm Facebook/Threads chỉ hiện chữ, không có liên kết.
- Mô tả món chỉ có tiếng Việt (chưa dịch sang tiếng Anh).

## Thay bằng API thật

Giao diện chỉ làm việc với các **interface** trong `lib/data/repositories/` (`DishRepository`, `TableRepository`, `AuthRepository`, `ChatRepository`, `SafetyRepository`, `LocationRepository`) và với `AppState`. Để nối máy chủ thật:

1. Viết lớp mới implement từng interface (ví dụ `ApiTableRepository`) gọi API hoặc Firebase, ném `TableException`/`SafetyException` với đúng mã lỗi khi vi phạm quy tắc.
2. Trong `AppState` (hàm tạo `AppState.mock` và `main.dart`), truyền các lớp mới vào thay cho bản `Mock...`.
3. Giữ các quy tắc ở `lib/data/logic/` ở phía máy chủ hoặc dùng lại; giờ của bàn được hiểu là giờ Việt Nam, bản API thật cần quy đổi trước khi trả về.
4. Việc ẩn bàn/tin nhắn của người bị chặn và quyền xem chat hiện do repository thực hiện (tham số `viewerId`), máy chủ thật cần làm tương tự.

Các bản `Mock...` vẫn dùng được cho test.
