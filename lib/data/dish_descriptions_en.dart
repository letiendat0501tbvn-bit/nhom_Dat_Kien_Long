// Mô tả món bằng tiếng Anh (id món -> mô tả). Tên món giữ nguyên tiếng Việt vì là tên riêng;
// một số tên nguyên liệu/nước chấm đặc trưng được giữ tiếng Việt kèm giải thích ngắn.
// Món thiếu trong bảng thì giao diện dùng mô tả tiếng Việt (Dish.descriptionFor).
const kDishDescriptionsEn = <String, String>{
  // ---------- Bún & mì (14) ----------
  'pho':
      'Fragrant broth and soft rice noodles: a bowl that warms you right up.',
  'bun-bo-hue':
      'Lemongrass aroma, bold chili heat and a rich broth, true to Huế.',
  'mi-quang': 'Turmeric noodles in a small pool of rich broth, topped with crunchy sesame rice crackers (bánh tráng).',
  'bun-cha': 'Fragrant grilled pork, fresh rice vermicelli (bún) and a bowl of dipping broth, a Hanoi classic.',
  'hu-tieu': 'Lightly chewy hủ tiếu noodles in a naturally sweet bone broth, good for breakfast or a late-night bite.',
  'bun-rieu': 'A gently sour broth with the sweetness of field crab, plus tomato and tofu.',
  'bun-dau-mam-tom': 'Crispy fried tofu, bún lá (vermicelli sheets) and chả cơm patties, dipped in whipped shrimp paste (mắm tôm).',
  'cao-lau': 'The signature chewy noodles of Hội An with sliced roast pork (thịt xíu), fresh herbs and just a little sauce.',
  'banh-canh': 'Thick, chewy noodles in a velvety broth, served with pork knuckle or crab.',
  'hu-tieu-go': 'A small bowl of hủ tiếu sold by evening street vendors: clear broth and fragrant minced pork.',
  'pho-chay': 'A broth made from vegetables, mushrooms and tofu: light and easy to eat.',
  'bun-hue-chay': 'The signature spicy kick of bún bò Huế, made entirely with vegetarian ingredients.',
  'mi-vit-tiem': 'Tender, fragrant duck braised with Chinese herbs, a rich broth and chewy yellow noodles.',
  'bun-thit-nuong': 'Fresh rice vermicelli (bún), charred grilled pork, fresh herbs and sweet-and-sour fish sauce (nước mắm).',

  // ---------- Bánh mặn (7) ----------
  'banh-mi-chao':
      'Warm bread, a fried egg and a hearty sauce, served sizzling in the pan.',
  'banh-mi': 'A crisp baguette (bánh mì) filled with meat, pâté, fresh herbs and pickles (đồ chua).',
  'bot-chien': 'Golden, crispy fried flour cakes with egg and scallions, dipped in chili sauce (tương ớt).',
  'banh-beo': 'Soft little bánh bèo cups topped with dried shrimp (tôm chấy) and scallion oil, drizzled with sweet fish sauce.',
  'banh-khot': 'Small pancakes with a crispy shell and a shrimp filling, wrapped in fresh herbs and dipped in fish sauce.',
  'banh-bao':
      'A fluffy, soft steamed bun filled with piping hot pork and quail egg.',
  'banh-gio': 'A banana-leaf-wrapped pyramid dumpling filled with pork and wood-ear mushrooms, best eaten hot in the morning.',

  // ---------- Cuốn & bánh (6) ----------
  'banh-xeo': 'A crispy-shelled savory pancake, wrapped in fresh greens and dipped in fish sauce.',
  'goi-cuon': 'Shrimp, pork, vermicelli and fresh herbs rolled in rice paper (bánh tráng) and dipped in sauce.',
  'banh-cuon': 'Thin sheets of rice batter steamed hot, filled with pork and mushroom, served with chả (pork roll) and fish sauce.',
  'nem-lui': 'Fragrant grilled pork on lemongrass skewers: wrap it yourself in rice paper with herbs and dip it in sauce.',
  'nem-ran': 'Golden, crispy fried rolls filled with pork, glass noodles and wood-ear mushrooms, dipped in sweet-and-sour fish sauce.',
  'bo-bia': 'Rolls of jicama, Chinese sausage (lạp xưởng), egg and herbs, dipped in sweet sauce.',

  // ---------- Cơm & xôi (7) ----------
  'com-tam': 'Broken rice with a grilled pork chop and a touch of fragrant scallion oil (mỡ hành).',
  'com-ga': 'Rice cooked in chicken broth, topped with shredded chicken and fried shallots, with a ginger dipping sauce.',
  'xoi-man': 'Sticky rice with pork floss (chà bông), quail eggs and fried shallots, a filling breakfast.',
  'com-nieu': 'Hot rice in a clay pot with a crispy bottom crust, eaten with braised dishes and soup.',
  'com-chien':
      'Fluffy fried rice with egg, Chinese sausage (lạp xưởng) and vegetables.',
  'chao': "Soft-cooked rice porridge with minced pork, fried dough sticks (quẩy) and scallions, ideal when you're tired or eating late.",
  'xoi-xeo': 'Golden sticky rice with nutty mung bean, topped with fried shallots and rich, fragrant chicken fat.',

  // ---------- Món lẩu (5) ----------
  'lau': 'A hot pot to dip into together while swapping stories.',
  'lau-thai': 'A hot-and-sour broth fragrant with lemongrass and kaffir lime leaves, for dipping seafood and vegetables.',
  'lau-bo': 'A sweet, slow-simmered beef broth for dipping rare beef, tendon and vegetables.',
  'lau-nam': 'A light, naturally sweet mushroom hot pot for dipping vegetables and tofu, great for vegetarians.',
  'lau-ga-la-e': 'Free-range chicken in a broth fragrant with lá é (a Vietnamese aromatic herb), mildly spicy, served with vermicelli (bún).',

  // ---------- Ăn vặt (12) ----------
  'oc':
      'A plate of snails, a glass of iced tea (trà đá) and hours of chatting.',
  'banh-trang-nuong': 'Crispy grilled rice paper (bánh tráng) with egg, scallions, sausage and chili sauce.',
  'banh-trang-tron': 'Shredded rice paper tossed with beef jerky, quail eggs, green mango and rau răm (Vietnamese coriander).',
  'cha-ca': 'Golden fried fish cake fragrant with dill, eaten hot with shrimp paste (mắm tôm) or fish sauce.',
  'nem-chua-ran': 'Fermented pork rolls (nem chua) fried crispy outside and mildly tangy inside, with chili sauce.',
  'ca-vien-chien': 'Crispy fried fish balls on skewers, dipped in plum sauce (tương xí muội) or chili sauce.',
  'hot-vit-lon': 'Hot boiled balut (fertilized duck egg), eaten with a salt-pepper-lime dip and rau răm (Vietnamese coriander).',
  'che-buoi': 'Crunchy pomelo pith and mung beans in lightly sweet coconut milk (nước cốt dừa).',
  'che-ba-mau': 'Red beans, mung beans and pandan jelly, topped with coconut milk and shaved ice.',
  'che-thai': 'Fruit, jelly, coconut milk and ice: cool relief on a hot day.',
  'sua-chua-nep-cam': 'Cool, lightly tangy yogurt over soft, fragrant black sticky rice (nếp cẩm).',
  'bap-xao': 'Corn stir-fried with butter, dried shrimp (tép khô) and scallions, a familiar afternoon snack.',

  // ---------- Đồ uống (5) ----------
  'tra-sua': 'Rich, sweet milk tea with tapioca pearls or jelly, as you like.',
  'ca-phe': 'A strong coffee, hot or iced, perfect for a long chat.',
  'sinh-to-bo':
      'Smooth avocado blended with condensed milk: creamy, fragrant and cool.',
  'nuoc-mia': 'Freshly pressed sugarcane juice with a touch of kumquat (quất) for aroma, best ice-cold on a sunny day.',
  'tra-dao': 'Refreshing peach tea with crisp peach pieces and lemongrass.',
};
