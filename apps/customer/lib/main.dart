import 'package:flutter/material.dart';

void main() => runApp(const CentralAsiaApp());

class CentralAsiaApp extends StatelessWidget {
  const CentralAsiaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Central Asia',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffb9633d)),
          scaffoldBackgroundColor: const Color(0xfffaf8f4),
          useMaterial3: true,
          fontFamily: 'sans',
        ),
        home: const HomePage(),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final dishes = [
      ('Плов классический', 'Рис, мясо, морковь и специи', '590 ₽', 'assets/plov.jpg'),
      ('Самса с бараниной', 'Слоеное тесто и сочная начинка', '220 ₽', 'assets/samsa.jpg'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Central Asia'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.person_outline))]),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
        const Text('Вкус Центральной Азии', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Доставка по Москве', style: TextStyle(color: Colors.brown.shade400)),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xffffead9), borderRadius: BorderRadius.circular(18)), child: const Row(children: [Icon(Icons.local_shipping_outlined), SizedBox(width: 12), Expanded(child: Text('Бесплатная доставка от 1 500 ₽', style: TextStyle(fontWeight: FontWeight.w600)))])),
        const SizedBox(height: 28),
        const Text('Меню', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...dishes.map((dish) => Card(margin: const EdgeInsets.only(bottom: 12), elevation: 0, child: ListTile(contentPadding: const EdgeInsets.all(12), leading: Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xffead8c5), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.restaurant, color: Color(0xffb9633d))), title: Text(dish.$1, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text('${dish.$2}\n${dish.$3}')), trailing: IconButton(onPressed: () => _showAdded(context, dish.$1), icon: const Icon(Icons.add_circle, color: Color(0xffb9633d))))),
      ]),
      bottomNavigationBar: NavigationBar(selectedIndex: 0, onDestinationSelected: (_) {}, destinations: const [NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Меню'), NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Заказы'), NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Любимое')]),
    );
  }

  static void _showAdded(BuildContext context, String name) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name добавлено в корзину')));
}
