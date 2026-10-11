# Danh sách kiểm thử thủ công

Chạy app bằng `flutter run -d chrome` (hoặc trên thiết bị Android). Mỗi lần mở lại app, dữ liệu mẫu được tạo mới. Đăng nhập giả lập luôn vào tài khoản "Minh Anh". Đánh dấu [x] khi đạt.

## 1. Khách xem và lọc (chưa đăng nhập)
- [ ] Mở app: tab **Khám phá** hiện tiêu đề "Chọn món để lên kèo", ô tìm kiếm, nút lọc, lưới món 2 cột. *Mong đợi:* giống ảnh thiết kế, có đủ thanh trên và thanh dưới 5 mục.
- [ ] Gõ "pho" vào ô tìm kiếm. *Mong đợi:* ra "Phở" (tìm không phân biệt dấu); gõ chữ không có món thì hiện câu rỗng.
- [ ] Bấm nút lọc, chọn buổi "Sáng", "Áp dụng". *Mong đợi:* bảng đóng, nút lọc được tô sáng, lưới chỉ còn món hợp buổi sáng. Mở lại, bấm "Đặt lại" rồi "Áp dụng" để bỏ lọc.
- [ ] Cuộn xuống: mục "Gợi ý cho bạn" (bấm chip khẩu vị/tâm trạng đổi danh sách), dải "ba miền", nút "Xem tất cả N món ngon". *Mong đợi:* mở màn "Tất cả món ngon" có đủ 56 món; Back quay lại.
- [ ] Tab **Bàn ăn** chưa chọn khu vực. *Mong đợi:* thẻ "Chọn khu vực" như ảnh, bên dưới là khối chọn món.

## 2. Lắc món
- [ ] Bấm nút xúc xắc vàng ở thanh trên. *Mong đợi:* bảng hiện 3 câu "Không biết ăn gì? Bấm quay là có kèo!"… và nút "Quay món liền!".
- [ ] Bấm "Quay món liền!". *Mong đợi:* các món chạy rồi dừng ở một món; nút đổi thành "Đang quay…" và không bấm được trong lúc quay; ra kết quả có tên, ảnh, mô tả.
- [ ] Bấm "Quay lại". *Mong đợi:* quay lần nữa ra món (có thể khác).
- [ ] Chọn buổi "Tối" trong bộ lọc rồi quay vài lần. *Mong đợi:* có ghi chú "Đang quay theo buổi Tối." và món ra hợp buổi tối.
- [ ] Bấm "Tìm bàn ăn" ở kết quả. *Mong đợi:* mở Chi tiết món đúng món vừa ra và cuộn tới phần "Bàn ăn cho món này".
- [ ] Bật "Giảm hoạt ảnh/Remove animations" trong cài đặt thiết bị rồi quay. *Mong đợi:* kết quả hiện ngay, không chạy dải món.

## 3. Chọn khu vực và tìm bàn
- [ ] Bấm "Chọn khu vực" (hoặc "Chọn vị trí" ở thanh trên). *Mong đợi:* bảng "Vị trí của bạn"; "Cho phép vị trí" chỉ báo "sẽ có ở bản sau"; "Để sau" đóng bảng.
- [ ] Chọn "Quận 1". *Mong đợi:* tab Bàn ăn hiện thẻ tóm tắt khu vực, hai tab Hôm nay/Ngày mai và danh sách bàn; thanh trên hiện "Quận 1".
- [ ] Đổi bán kính trong bảng lọc xuống 100 m. *Mong đợi:* danh sách rỗng với câu gợi ý, nút "Xem ngày mai", "Nới bán kính lên …", "Mở bàn mới".
- [ ] Từ một thẻ món bấm "Tìm bàn ăn". *Mong đợi:* mở Chi tiết món, cuộn tới bàn ăn; nếu chưa chọn khu vực thì có thẻ "Chọn khu vực" ngay tại màn.

## 4. Đăng nhập
- [ ] Ở Bàn ăn, bấm "Tham gia" khi chưa đăng nhập. *Mong đợi:* hiện bảng "Vào hội thôi!"; đóng bảng thì vẫn là khách, chưa tham gia gì.
- [ ] Trong bảng đăng nhập bấm "Chính sách quyền riêng tư" và "Điều khoản sử dụng". *Mong đợi:* mở đúng trang (có ghi chú nội dung mẫu); Back về bảng đăng nhập còn mở.
- [ ] Bấm "Tiếp tục với Google". *Mong đợi:* bảng đóng, ở lại đúng màn, **không tự tham gia** bàn nào.

## 5. Tham gia và rời bàn
- [ ] Bấm "Tham gia" một bàn còn chỗ. *Mong đợi:* thông báo thành công, thẻ đổi thành "Đã tham gia", số chỗ giảm 1.
- [ ] Bấm vào thẻ (không phải nút) để mở Chi tiết bàn. *Mong đợi:* thấy món, quán, giờ, thời lượng, chỗ còn, danh sách thành viên với huy hiệu "Chủ bàn", khối trò chuyện.
- [ ] Bấm "Rời bàn". *Mong đợi:* hộp xác nhận nói rõ hậu quả; xác nhận xong có thông báo, nút về "Tham gia", chat biến mất. Back về danh sách: thẻ đã cập nhật.
- [ ] Vừa đăng nhập, vào tab Lịch hẹn. *Mong đợi:* Minh Anh chỉ có đúng 2 bàn mẫu: 1 bàn "Sắp tới" (cô ấy là chủ bàn, bắt đầu sau khoảng 1–3 giờ, còn 1 chỗ) và 1 bàn "Đã qua" (nhãn "Đã kết thúc", bắt đầu cách đây khoảng 3 giờ).
- [ ] **Thử Tham gia bàn trùng giờ để thấy lỗi:** ở Bàn ăn, khu vực Quận 1, tìm bàn "Bánh xèo" còn 2 chỗ có giờ trùng bàn "Sắp tới" của Minh Anh (cách bây giờ khoảng 2 giờ) và bấm "Tham gia". *Mong đợi:* thông báo lỗi trùng giờ, số chỗ không đổi, không vào bàn.
- [ ] **Thử Tham gia một bàn khác để thấy thành công:** bấm "Tham gia" một bàn Quận 1 còn chỗ khác (ví dụ "Bánh mì chảo" sắp đến giờ, hoặc "Lẩu"). *Mong đợi:* thông báo thành công, thẻ đổi thành "Đã tham gia", bàn xuất hiện ở tab Lịch hẹn.
- [ ] Bàn đã đầy. *Mong đợi:* nút "Đã đầy" không bấm được.

## 6. Mở bàn mới
- [ ] Bấm nút + đỏ giữa thanh dưới (khi chưa đăng nhập vẫn mở được). *Mong đợi:* màn "Mở bàn mới" toàn trang, có nút Back.
- [ ] Bấm "Xem lại" khi chưa điền. *Mong đợi:* báo lỗi đỏ ngay tại trường quán và giờ.
- [ ] Chọn món (gõ "bun bo"), quán, giờ (các mốc đã qua bị khoá), thời lượng, số chỗ (2–8, nút +/−), ghi chú (tối đa 140 ký tự). *Mong đợi:* "Xem lại" mở màn xác nhận tóm tắt đúng thông tin.
- [ ] Bấm "Mở bàn" khi là khách. *Mong đợi:* hiện bảng đăng nhập, dữ liệu đã điền được giữ; đăng nhập xong **không** tự mở bàn, bấm "Mở bàn" lần nữa.
- [ ] Mở bàn thành công. *Mong đợi:* thông báo, chuyển sang Chi tiết bàn vừa tạo (bạn là chủ bàn); Back về nơi đã mở; bàn mới có trong danh sách và tab Lịch hẹn.
- [ ] Mở bàn trùng giờ với bàn đang tham gia. *Mong đợi:* lỗi trùng giờ ngay ở trường giờ.
- [ ] Từ Chi tiết món (rỗng) bấm "Mở bàn mới với món này". *Mong đợi:* màn mở bàn đã chọn sẵn món.

## 7. Chat trong bàn
- [ ] Mở Chi tiết bàn của bàn bạn đã tham gia, gõ tin và bấm gửi (hoặc Enter). *Mong đợi:* tin hiện bên phải; sau 1–2 giây một thành viên khác tự trả lời (giả lập).
- [ ] Gửi tin rỗng/toàn khoảng trắng. *Mong đợi:* nút gửi bị khoá. Gõ trên 450 ký tự: hiện bộ đếm, tối đa 500.
- [ ] Người chưa tham gia và khách. *Mong đợi:* chỉ thấy "Tham gia bàn để trò chuyện." (khách kèm nút Đăng nhập).
- [ ] Bàn đã bắt đầu. *Mong đợi:* chat chỉ đọc, ô nhập thay bằng dòng thông báo.

## 8. Báo cáo và chặn
- [ ] Ở Chi tiết bàn của bàn người khác: menu "⋯" → "Báo cáo bàn", chọn lý do, ghi chú, "Gửi báo cáo". *Mong đợi:* thông báo "Đã gửi báo cáo"; gửi lại cùng lý do hiện "Bạn đã báo cáo mục này.".
- [ ] Menu "⋯" cạnh một thành viên → "Báo cáo người dùng"; bấm giữ tin nhắn của người khác → "Báo cáo tin nhắn". Dòng/tin của chính bạn không có menu.
- [ ] Menu "⋯" cạnh một thành viên → "Chặn người dùng". *Mong đợi:* hộp xác nhận nêu hậu quả; xác nhận xong bàn do người đó mở biến khỏi Bàn ăn và Chi tiết món, tin nhắn của họ biến khỏi chat, họ có huy hiệu "Đã chặn" trong danh sách thành viên.
- [ ] Tab Tôi → Tài khoản → "Danh sách chặn" → "Bỏ chặn". *Mong đợi:* hộp xác nhận ngắn; bỏ chặn xong bàn và tin nhắn hiện lại ngay.
- [ ] "Báo cáo đã gửi". *Mong đợi:* liệt kê loại, lý do, ghi chú, giờ, mới nhất trước.

## 9. Hồ sơ, phản hồi, đăng xuất
- [ ] Tab **Lịch hẹn** (đã đăng nhập, chưa tham gia gì). *Mong đợi:* đúng 1 bàn "Sắp tới" và 1 bàn "Đã qua" (xem mục 4); bàn đã huỷ/kết thúc có nhãn trạng thái; bấm thẻ mở Chi tiết bàn. Chưa có bàn thì hiện câu gợi ý với nút "Mở bàn mới" và "Tìm bàn ăn".
- [ ] Khách vào tab Lịch hẹn. *Mong đợi:* "Đăng nhập để xem những bàn ăn của bạn." như ảnh.
- [ ] Tab **Tôi** → "Phản hồi riêng tư". *Mong đợi:* ghi chú "riêng tư"; gửi phản hồi có thông báo, ô được xoá, phản hồi hiện đầu danh sách; trên 500 ký tự bị chặn.
- [ ] Tab Tôi → "Thông tin" (cả khách) → mở 4 trang. *Mong đợi:* có dòng "Nội dung mẫu", Back về danh sách.
- [ ] "Đăng xuất". *Mong đợi:* hộp xác nhận; xác nhận xong về "Khách ghé chơi" + nút Đăng nhập như ảnh, tab Lịch hẹn cũng về trạng thái khách.

## 10. Đổi ngôn ngữ
- [ ] Bấm nút "EN" ở thanh trên. *Mong đợi:* toàn bộ chữ đổi sang tiếng Anh ngay (thanh dưới, các màn, bảng lọc, bảng đăng nhập, chat, hộp thoại); giờ hiển thị kiểu AM/PM; nút đổi thành "VI". Mô tả món vẫn tiếng Việt (chưa dịch).
- [ ] Lặp lại vài luồng ở mục 3–9 bằng tiếng Anh. *Mong đợi:* không còn chữ Việt lẫn trong giao diện, không tràn dòng.

## 11. Khổ màn hình và chữ phóng to
- [ ] Thử trên khổ **360 dp** và **412 dp** (máy ảo, hoặc kéo hẹp cửa sổ Chrome bằng DevTools). *Mong đợi:* không dòng nào bị cắt hay tràn, không có sọc vàng-đen báo tràn.
- [ ] Bật cỡ chữ lớn trong cài đặt thiết bị (khoảng 130%). Duyệt Khám phá, Bàn ăn, Chi tiết bàn (kèm chat), Mở bàn mới, Hồ sơ, bảng Lắc món. *Mong đợi:* chữ xuống dòng gọn, nút vẫn bấm được, không tràn.
- [ ] Bật trình đọc màn hình (TalkBack). *Mong đợi:* các nút biểu tượng có nhãn (Lắc món, Đổi ngôn ngữ, menu "⋯", Gửi, Tăng/Giảm số chỗ); kết quả Lắc món được đọc.

## 12. Trạng thái tải, rỗng, lỗi
- [ ] Mở các danh sách (món, bàn, quán, báo cáo, chặn, phản hồi). *Mong đợi:* có vòng xoay khi tải (độ trễ giả 300–600 ms) và câu rỗng thích hợp. Không có mạng thật để thử lỗi; các trạng thái lỗi và nút "Thử lại" được kiểm bằng test tự động.
