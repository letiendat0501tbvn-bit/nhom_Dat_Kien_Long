import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class FoodCategory {
  final String id;
  final String name;
  final IconData icon;

  const FoodCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final FoodCategory category;  

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
  });
}

class OrderItem {
  final FoodItem food;
  int quantity;

  OrderItem({required this.food, this.quantity = 1});

  double get totalPrice => food.price * quantity;
}

class Cart {
  final List<OrderItem> items = [];

  void addItem(FoodItem food) {
    final existingIndex = items.indexWhere((item) => item.food.id == food.id);
    if (existingIndex >= 0) {
      items[existingIndex].quantity += 1;
    } else {
      items.add(OrderItem(food: food));
    }
  }

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.totalPrice);
}

class Restaurant {
  final String name;
  final String address;
  final double deliveryFee;

  const Restaurant({
    required this.name,
    required this.address,
    required this.deliveryFee,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Order App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
      ),
      home: const FoodHomePage(),
    );
  }
}

class FoodHomePage extends StatefulWidget {
  const FoodHomePage({super.key});

  @override
  State<FoodHomePage> createState() => _FoodHomePageState();
}

class _FoodHomePageState extends State<FoodHomePage> {
  final restaurant = const Restaurant(
    name: 'FoodGo',
    address: 'Yên Nghĩa, Hà Đông, Hà Nội',
    deliveryFee: 15000,
  );

  final categories = const [
    FoodCategory(id: 'all', name: 'Tất cả', icon: Icons.grid_view_rounded),
    FoodCategory(id: 'bun', name: 'Bún', icon: Icons.ramen_dining),
    FoodCategory(id: 'pizza', name: 'Pizza', icon: Icons.local_pizza),
    FoodCategory(id: 'drink', name: 'Nước', icon: Icons.local_drink),
  ];

  final foods = const [
    FoodItem(
      id: 'bun-bo',
      name: 'Bún bò Huế',
      description: 'Nước dùng đậm vị, thịt bò và chả giò',
      price: 59000,
      imageUrl: '',
      category: FoodCategory(id: 'bun', name: 'Bún', icon: Icons.ramen_dining),
    ),
    FoodItem(
      id: 'pizza-margherita',
      name: 'Pizza Margherita',
      description: 'Sốt cà chua, phô mai mozzarella',
      price: 99000,
      imageUrl: '',
      category: FoodCategory(id: 'pizza', name: 'Pizza', icon: Icons.local_pizza),
    ),
    FoodItem(
      id: 'tra-da',
      name: 'Trà đá sữa',
      description: 'Giải nhiệt, thơm ngon và mát lạnh',
      price: 25000,
      imageUrl: '',
      category: FoodCategory(id: 'drink', name: 'Nước', icon: Icons.local_drink),
    ),
  ];

  final cart = Cart();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt đồ ăn'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${cart.totalQuantity} món',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                restaurant.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(restaurant.address),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Chip(
                      avatar: Icon(category.icon, size: 18),
                      label: Text(category.name),
                      backgroundColor: index == 0 ? Colors.orange.shade100 : Colors.white,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: foods.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              food.category.icon,
                              size: 30,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  food.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  food.description,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${food.price.toStringAsFixed(0)}₫',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            key: ValueKey('add-food-${food.id}'),
                            onPressed: () {
                              setState(() {
                                cart.addItem(food);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Thêm'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tổng thanh toán',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '${cart.totalPrice.toStringAsFixed(0)}₫',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: cart.items.isEmpty ? null : () {},
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('Đặt hàng'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
