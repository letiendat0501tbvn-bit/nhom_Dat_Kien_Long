// Ảnh món thật nằm ở assets/images/dishes/. Tên file không khớp hoàn toàn với id món
// (viết hoa chữ đầu, có file .png, "cafe.jpg" cho món "ca-phe"), mà Flutter phân biệt hoa
// thường khi đọc asset trên web và Android, nên ghi rõ tên file thật cho từng món ở đây.
// Món không có trong bảng thì dùng ô màu + emoji như trước.
// Thêm ảnh mới: bỏ file vào thư mục rồi thêm một dòng "id món": "tên file".
const kDishImageDir = 'assets/images/dishes/';

const kDishImageFiles = <String, String>{
  'pho': 'Pho.jpg',
  'bun-bo-hue': 'Bun-bo-hue.jpg',
  'mi-quang': 'Mi-Quang.jpg',
  'bun-cha': 'Bun-cha.jpg',
  'hu-tieu': 'Hu-tieu.jpg',
  'bun-rieu': 'Bun-rieu.jpg',
  'bun-dau-mam-tom': 'Bun-dau-mam-tom.jpg',
  'cao-lau': 'Cao-lau.jpg',
  'banh-canh': 'Banh-canh.jpg',
  'hu-tieu-go': 'Hu-tieu-go.jpg',
  'pho-chay': 'Pho-chay.jpg',
  'bun-hue-chay': 'Bun-hue-chay.jpg',
  'mi-vit-tiem': 'Mi-vit-tiem.jpg',
  'bun-thit-nuong': 'Bun-thit-nuong.jpg',
  'banh-mi-chao': 'Banh-mi-chao.jpg',
  'banh-mi': 'Banh-mi.jpg',
  'bot-chien': 'Bot-chien.jpg',
  'banh-beo': 'Banh-beo.png',
  'banh-khot': 'Banh-khot.jpg',
  'banh-bao': 'Banh-bao.jpg',
  'banh-gio': 'Banh-gio.jpg',
  'banh-xeo': 'Banh-xeo.jpg',
  'goi-cuon': 'Goi-cuon.jpg',
  'banh-cuon': 'Banh-cuon.jpg',
  'nem-lui': 'Nem-lui.jpg',
  'nem-ran': 'Nem-ran.jpg',
  'bo-bia': 'Bo-bia.jpg',
  'com-tam': 'Com-tam.jpg',
  'com-ga': 'Com-ga.jpg',
  'xoi-man': 'Xoi-man.jpg',
  'com-nieu': 'Com-nieu.jpg',
  'com-chien': 'Com-chien.jpg',
  'chao': 'Chao.jpg',
  'xoi-xeo': 'xoi-xeo.jpg',
  'lau': 'Lau.jpg',
  'lau-thai': 'Lau-thai.jpg',
  'lau-bo': 'Lau-bo.jpg',
  'lau-nam': 'Lau-nam.jpg',
  'lau-ga-la-e': 'Lau-ga-la-e.jpg',
  'oc': 'Oc.jpg',
  'banh-trang-nuong': 'Banh-trang-nuong.jpg',
  'banh-trang-tron': 'Banh-trang-tron.jpg',
  'cha-ca': 'cha-ca.jpg',
  'nem-chua-ran': 'Nem-chua-ran.jpg',
  'ca-vien-chien': 'Ca-vien-chien.jpg',
  'hot-vit-lon': 'Hot-vit-lon.jpg',
  'che-buoi': 'Che-buoi.jpg',
  'che-ba-mau': 'Che-ba-mau.jpg',
  'che-thai': 'che-thai.jpg',
  'sua-chua-nep-cam': 'Sua-chua-nep-cam.jpg',
  'bap-xao': 'Bap-xao.jpg',
  'tra-sua': 'tra-sua.jpg',
  'ca-phe': 'cafe.jpg',
  'sinh-to-bo': 'sinh-to-bo.jpg',
  'nuoc-mia': 'nuoc-mia.jpg',
  'tra-dao': 'tra-dao.jpg',
};

// Đường dẫn asset của ảnh món, hoặc null nếu món chưa có ảnh.
String? dishImageAsset(String id) {
  final file = kDishImageFiles[id];
  return file == null ? null : '$kDishImageDir$file';
}
