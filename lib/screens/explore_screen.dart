import 'package:flutter/material.dart';

/// Màn hình "Khám phá" (Stateless Widget).
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  static const _dishes = [
    DishCard(
      name: 'Phở',
      description: 'Nước dùng thơm, bánh phở mềm',
      tag: 'Bún & mì',
      icon: Icons.ramen_dining,
    ),
    DishCard(
      name: 'Bánh mì chảo',
      description: 'Bánh mì nóng, trứng ốp la',
      tag: 'Bánh mặn',
      icon: Icons.bakery_dining,
    ),
    DishCard(
      name: 'Bún bò Huế',
      description: 'Sả thơm, vị cay nồng',
      tag: 'Bún & mì',
      icon: Icons.ramen_dining,
    ),
    DishCard(
      name: 'Bánh xèo',
      description: 'Vỏ bánh giòn rụm, cuốn rau',
      tag: 'Cuốn & bánh',
      icon: Icons.lunch_dining,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Chọn món để lên kèo',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Chọn món → Xem quán và giờ hẹn → Xác nhận tham gia.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Tìm món ăn...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: _dishes,
        ),
      ],
    );
  }
}

/// Thẻ món ăn (Stateless Widget).
class DishCard extends StatelessWidget {
  final String name;
  final String description;
  final String tag;
  final IconData icon;

  const DishCard({
    super.key,
    required this.name,
    required this.description,
    required this.tag,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Center(child: Icon(icon, size: 56, color: Colors.orange)),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tìm bàn ăn →',
          style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
