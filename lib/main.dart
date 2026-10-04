import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// ENTRY POINT
// ---------------------------------------------------------------------------
void main() {
  runApp(const CampusCafeteriaApp());
}

// ---------------------------------------------------------------------------
// COLORS (blue / sky blue palette, same roles as the canteen web design)
// ---------------------------------------------------------------------------
class AppColors {
  static const ink = Color(0xFF14202B); // main text
  static const muted = Color(0xFF6B7B89); // secondary text
  static const line = Color(0xFFDDE8F0); // thin borders
  static const paper = Color(0xFFFCFEFF); // card / app bar surface
  static const background = Color(0xFFF4F9FD); // page background
  static const primary = Color(0xFF1F6FB5); // blue (buttons, brand)
  static const primaryDark = Color(0xFF16568F); // pressed / dark blue
  static const sky = Color(0xFF2E8BD0); // sky blue accent (eyebrows)
  static const skySoft = Color(0xFFE3F2FC); // soft sky tint (hero, chips)
  static const skyLight = Color(0xFFBFE0F7); // light text on blue
  static const heart = Color(0xFFBD594D);
}

// Shared decorations so every card looks the same.
class AppStyle {
  // Shape used by every Card widget (thin border, round corners).
  static ShapeBorder cardShape([double radius = 16]) => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: AppColors.line),
      );

  static BoxDecoration card({double radius = 16}) => BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(radius),
      );

  static const h2 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    height: 1.1,
  );
}

// ---------------------------------------------------------------------------
// ROOT APP (stateless: it never changes by itself)
// ---------------------------------------------------------------------------
class CampusCafeteriaApp extends StatelessWidget {
  const CampusCafeteriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Cafeteria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary)
            .copyWith(primary: AppColors.primary, surface: AppColors.paper),
        scaffoldBackgroundColor: AppColors.background,
        // FONTS: Inter, like the canteen web design
        textTheme: GoogleFonts.interTextTheme().apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.paper,
          foregroundColor: AppColors.ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 16,
          shape: const Border(bottom: BorderSide(color: AppColors.line)),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppColors.ink,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            textStyle:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.paper,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.skySoft,
          height: 68,
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? AppColors.primary
                    : AppColors.muted,
              )),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.muted,
            );
          }),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      home: const CafeteriaShell(),
    );
  }
}

// ---------------------------------------------------------------------------
// DATA MODEL (custom class)
// ---------------------------------------------------------------------------
class MenuItem {
  final String name;
  final String category;
  final double price;
  final String description;
  final String? imageAsset; // LOCAL image
  final String? imageUrl; // NETWORK image
  bool isFavorite;

  MenuItem({
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    this.imageAsset,
    this.imageUrl,
    this.isFavorite = false,
  });

  /// Builds a MenuItem from one JSON object returned by TheMealDB.
  /// The API has no prices, so we derive one from the meal id.
  factory MenuItem.fromJson(Map<String, dynamic> json, String category) {
    final id = int.tryParse(json['idMeal'].toString()) ?? 0;
    return MenuItem(
      name: json['strMeal'] as String,
      category: category,
      price: 45.0 + (id % 10) * 5, // PHP 45 - 90
      description: 'Freshly prepared ${category.toLowerCase()} for students.',
      imageUrl: json['strMealThumb'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// CART ITEM (wraps a MenuItem with a quantity)
// ---------------------------------------------------------------------------
class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  double get totalPrice => menuItem.price * quantity;
}

// ---------------------------------------------------------------------------
// LOCAL DATA (list managed in a custom class)
// ---------------------------------------------------------------------------
class MenuRepository {
  static const categories = ['All', 'Meals', 'Snacks', 'Drinks', 'Desserts'];

  static List<MenuItem> localItems() {
    return [
      MenuItem(
        name: 'Iced Tea',
        category: 'Drinks',
        price: 30,
        imageAsset: 'assets/images/icedtea.jpg',
        description: 'Cold, refreshing black tea with lemon.',
      ),
      MenuItem(
        name: 'Milk Tea',
        category: 'Drinks',
        price: 55,
        imageAsset: 'assets/images/milktea.jpg',
        description: 'Creamy milk tea with chewy pearls.',
      ),
      MenuItem(
        name: 'Ham Sandwich',
        category: 'Snacks',
        price: 50,
        imageAsset: 'assets/images/hamsandwich.jpg',
        description: 'Ham, cheese, and lettuce on soft bread.',
      ),
      MenuItem(
        name: 'Banana Cake',
        category: 'Desserts',
        price: 45,
        imageAsset: 'assets/images/bananacake.jpg',
        description: 'Moist banana cake baked every morning.',
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// API SERVICE (fetching data from an API)
//
// Steps:  1) http.get(Uri)  2) check statusCode == 200
//         3) jsonDecode(body)  4) map each JSON object with fromJson
// ---------------------------------------------------------------------------
class MenuApi {
  static const _baseUrl =
      'https://www.themealdb.com/api/json/v1/1/filter.php?c=';

  // API category -> our cafeteria category
  static const Map<String, String> _categoryMap = {
    'Chicken': 'Meals',
    'Pasta': 'Meals',
    'Starter': 'Snacks',
    'Dessert': 'Desserts',
  };

  static Future<List<MenuItem>> fetchItems() async {
    // Run all requests at the same time instead of one after another.
    final results = await Future.wait(
      _categoryMap.entries.map((e) => _fetchCategory(e.key, e.value)),
    );
    return results.expand((list) => list).toList();
  }

  static Future<List<MenuItem>> _fetchCategory(
      String apiCategory, String cafeCategory) async {
    final response = await http
        .get(Uri.parse('$_baseUrl$apiCategory'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final meals = (data['meals'] as List?) ?? [];

    return meals
        .take(4)
        .map((j) => MenuItem.fromJson(j as Map<String, dynamic>, cafeCategory))
        .toList();
  }
}

// ---------------------------------------------------------------------------
// SHELL (stateful: holds data, loading state, selected tab, and cart)
// ---------------------------------------------------------------------------
class CafeteriaShell extends StatefulWidget {
  const CafeteriaShell({super.key});

  @override
  State<CafeteriaShell> createState() => _CafeteriaShellState();
}

class _CafeteriaShellState extends State<CafeteriaShell> {
  static const _titles = [
    'Campus Cafeteria',
    'Menu',
    'Favorites',
    'Categories',
    'About'
  ];

  int _tab = 0;
  bool _loading = true;
  String? _error;
  String _selectedCategory = 'All';
  List<MenuItem> _items = MenuRepository.localItems();

  // Cart state: keyed by item name so it survives menu reloads.
  final Map<String, int> _cartQuantities = {};

  List<CartItem> get _cartItems => _items
      .where((i) => _cartQuantities.containsKey(i.name))
      .map((i) => CartItem(menuItem: i, quantity: _cartQuantities[i.name]!))
      .toList();

  int get _cartItemCount => _cartQuantities.values.fold(0, (s, q) => s + q);

  double get _cartTotal => _cartItems.fold(0.0, (s, ci) => s + ci.totalPrice);

  void _addToCart(MenuItem item) {
    setState(() {
      _cartQuantities.update(item.name, (v) => v + 1, ifAbsent: () => 1);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => _removeFromCart(item)),
      ),
    );
  }

  void _removeFromCart(MenuItem item) {
    setState(() {
      _cartQuantities.remove(item.name);
    });
  }

  void _incrementCart(MenuItem item) {
    setState(() {
      _cartQuantities.update(item.name, (v) => v + 1, ifAbsent: () => 1);
    });
  }

  void _decrementCart(MenuItem item) {
    setState(() {
      final current = _cartQuantities[item.name] ?? 0;
      if (current <= 1) {
        _cartQuantities.remove(item.name);
      } else {
        _cartQuantities[item.name] = current - 1;
      }
    });
  }

  void _clearCart() {
    setState(() => _cartQuantities.clear());
  }

  Future<void> _checkout() async {
    final count = _cartItemCount;
    final total = _cartTotal;
    _clearCart();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Order Received!',
            style: TextStyle(color: AppColors.primary, fontSize: 20)),
        content: Text(
            '$count item${count == 1 ? '' : 's'} ordered. Total: ₱${total.toStringAsFixed(0)}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Remember favorites so a reload does not erase them.
    final favoriteNames =
        _items.where((i) => i.isFavorite).map((i) => i.name).toSet();

    try {
      final remote = await MenuApi.fetchItems();
      final all = [...MenuRepository.localItems(), ...remote];
      for (final item in all) {
        item.isFavorite = favoriteNames.contains(item.name);
      }
      if (!mounted) return;
      setState(() {
        _items = all;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the online menu. Showing offline items.';
        _loading = false;
      });
    }
  }

  void _toggleFavorite(MenuItem item) {
    setState(() => item.isFavorite = !item.isFavorite);
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final items = _cartItems;
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: items.isEmpty
                ? const _EmptyCart()
                : Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.line,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(height: 16),
                      const Text('Your Cart',
                          style: AppStyle.h2),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final ci = items[index];
                            return _CartItemRow(
                              cartItem: ci,
                              onIncrement: () {
                                _incrementCart(ci.menuItem);
                                setModalState(() {});
                              },
                              onDecrement: () {
                                _decrementCart(ci.menuItem);
                                setModalState(() {});
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child:
                            Text('Total: ₱${_cartTotal.toStringAsFixed(0)}',
    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    color: AppColors.primary)),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: _clearCart,
                                icon: const Icon(Icons.clear_all,
                                    color: AppColors.muted),
                                label: const Text('Clear'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _checkout,
                                child: const Text('Checkout'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _items.where((i) => i.isFavorite).toList();

    final pages = <Widget>[
      HomeScreen(
        items: _items,
        favoriteCount: favorites.length,
        cartCount: _cartItemCount,
        onViewMenu: () => setState(() => _tab = 1),
        onFavorite: _toggleFavorite,
        onAddToCart: _addToCart,
      ),
      MenuScreen(
        items: _items,
        loading: _loading,
        error: _error,
        onRetry: _loadMenu,
        onFavorite: _toggleFavorite,
        onAddToCart: _addToCart,
      ),
      FavoritesScreen(items: favorites, onRemove: _toggleFavorite),
      CategoriesScreen(
        items: _items,
        selected: _selectedCategory,
        onSelect: (c) => setState(() => _selectedCategory = c),
        onFavorite: _toggleFavorite,
        onAddToCart: _addToCart,
      ),
      const AboutScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandMark(),
            const SizedBox(width: 10),
            // Home shows the two-tone brand name, other tabs show their title.
            if (_tab == 0)
              const Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'Campus'),
                  TextSpan(
                    text: 'Cafeteria',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ]),
              )
            else
              Text(_titles[_tab]),
          ],
        ),
        actions: [
          // --- Shopping Cart button with badge ---
          IconButton(
            tooltip: 'Shopping cart',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_outlined),
                if (_cartItemCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                    decoration: const BoxDecoration(
                          color: AppColors.heart,
                          shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_cartItemCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showCart,
          ),
          // --- Reload button ---
          IconButton(
            tooltip: 'Reload menu',
            icon: const Icon(Icons.refresh),
            onPressed: _loadMenu,
          ),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.restaurant_menu), label: 'Menu'),
            NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: 'Fav'),
            NavigationDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: 'Cats'),
            NavigationDestination(
                icon: Icon(Icons.info_outline),
                selectedIcon: Icon(Icons.info),
                label: 'About'),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// SCREENS (all stateless: they only display what the shell gives them)
// ===========================================================================

// ---------------------------- 1. HOME --------------------------------------
class HomeScreen extends StatelessWidget {
  final List<MenuItem> items;
  final int favoriteCount;
  final int cartCount;
  final VoidCallback onViewMenu;
  final void Function(MenuItem) onFavorite;
  final void Function(MenuItem) onAddToCart;

  const HomeScreen({
    super.key,
    required this.items,
    required this.favoriteCount,
    required this.cartCount,
    required this.onViewMenu,
    required this.onFavorite,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final special = items.firstWhere(
      (i) => i.category == 'Meals',
      orElse: () => items.first,
    );

    const archRadius = BorderRadius.only(
      topLeft: Radius.circular(160),
      topRight: Radius.circular(160),
      bottomLeft: Radius.circular(22),
      bottomRight: Radius.circular(22),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section on a soft sky background
          Container(
            width: double.infinity,
            color: AppColors.skySoft,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Fresh food for every student'),
                const SizedBox(height: 14),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                      height: 1,
                    ),
                    children: [
                      const TextSpan(text: 'Welcome to\n'),
                      TextSpan(
                        text: 'Campus Cafeteria',
                        style: GoogleFonts.playfairDisplay(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -1,
                          fontSize: 34,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'View meals, snacks and drinks.',
                  style: TextStyle(
                      color: AppColors.muted, fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: onViewMenu,
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: const Text('VIEW MENU'),
                ),
                const SizedBox(height: 28),
                // LOCAL image in an arch shape, with a soft blue shadow
                DecoratedBox(
                  decoration: const BoxDecoration(
                    borderRadius: archRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x331F6FB5),
                        blurRadius: 40,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: archRadius,
                    child: Image.asset(
                      'assets/images/cafe_banner.jpg',
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 240,
                        width: double.infinity,
                        color: AppColors.skyLight,
                        child: const Icon(Icons.local_cafe,
                            color: AppColors.primary, size: 64),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Today's special
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 28, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('Popular today', color: AppColors.sky),
                SizedBox(height: 8),
                Text("Today's Special", style: AppStyle.h2),
              ],
            ),
          ),
          MenuCard(
            item: special,
            onFavorite: () => onFavorite(special),
            onAddToCart: () => onAddToCart(special),
          ),

          // Stats on a solid blue band
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 28),
            padding: const EdgeInsets.all(24),
            color: AppColors.primary,
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.restaurant,
                    label: 'Available food',
                    value: '${items.length}',
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: StatCard(
                    icon: Icons.favorite,
                    label: 'Favorites',
                    value: '$favoriteCount',
                  ),
                ),
              ],
            ),
          ),

          // Cart summary on the blue band
          if (cartCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              color: AppColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Items in cart: $cartCount',
                      style: const TextStyle(
                          color: AppColors.skyLight, fontSize: 13)),
                  Text('View or checkout from the cart icon.',
                      style: TextStyle(
                          color: AppColors.skyLight.withValues(alpha: 0.8),
                          fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------- 2. MENU --------------------------------------
class MenuScreen extends StatelessWidget {
  final List<MenuItem> items;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final void Function(MenuItem) onFavorite;
  final void Function(MenuItem) onAddToCart;

  const MenuScreen({
    super.key,
    required this.items,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onFavorite,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('Cafeteria Menu'),
                SizedBox(height: 8),
                Text('Choose your food', style: AppStyle.h2),
              ],
            ),
          ),
        ),
        if (loading)
          const LinearProgressIndicator(
            color: AppColors.sky,
            backgroundColor: AppColors.skySoft,
          ),
        if (error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            decoration: BoxDecoration(
              color: AppColors.skySoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.skyLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(error!,
                        style: const TextStyle(fontSize: 12))),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        Expanded(
          child: MenuList(
            items: items,
            onFavorite: onFavorite,
            onAddToCart: onAddToCart,
          ),
        ),
      ],
    );
  }
}

// ---------------------------- 3. FAVORITES ---------------------------------
class FavoritesScreen extends StatelessWidget {
  final List<MenuItem> items;
  final void Function(MenuItem) onRemove;

  const FavoritesScreen(
      {super.key, required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.skySoft,
                child: Icon(Icons.favorite_border,
                    size: 30, color: AppColors.primary),
              ),
              SizedBox(height: 16),
              Text(
                'No favorites yet.\nTap the heart on any menu item to save it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.6),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('My Favorites'),
                SizedBox(height: 8),
                Text('Foods you saved', style: AppStyle.h2),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 0,
                color: AppColors.paper,
                surfaceTintColor: Colors.transparent,
                shape: AppStyle.cardShape(),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  leading: FoodImage(item: item, size: 52),
                  title: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '₱${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: AppColors.heart),
                    onPressed: () => onRemove(item),
                  ),
                ),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Tap the heart to remove a favorite.',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ),
      ],
    );
  }
}

// ---------------------------- 4. CATEGORIES --------------------------------
class CategoriesScreen extends StatelessWidget {
  final List<MenuItem> items;
  final String selected;
  final void Function(String) onSelect;
  final void Function(MenuItem) onFavorite;
  final void Function(MenuItem) onAddToCart;

  const CategoriesScreen({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.onFavorite,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = selected == 'All'
        ? items
        : items.where((i) => i.category == selected).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: MenuRepository.categories.map((c) {
              final isSelected = c == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: isSelected,
                  showCheckmark: false,
                  backgroundColor: AppColors.paper,
                  selectedColor: AppColors.primary,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.line,
                    ),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.muted,
                  ),
                  onSelected: (_) => onSelect(c),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: MenuList(
            items: filtered,
            onFavorite: onFavorite,
            onAddToCart: onAddToCart,
          ),
        ),
      ],
    );
  }
}

// ---------------------------- 5. ABOUT -------------------------------------
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SizedBox(height: 12),
        Center(child: BrandMark(size: 64)),
        SizedBox(height: 16),
        Text(
          'About the App',
          textAlign: TextAlign.center,
          style: AppStyle.h2,
        ),
        SizedBox(height: 10),
        Text(
          'Campus Cafeteria helps students browse food, prices and categories.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.6),
        ),
        SizedBox(height: 20),
        InfoTile(
          icon: Icons.access_time,
          title: 'Opening Hours',
          text: 'Monday - Friday: 7:00 AM - 6:00 PM',
        ),
        InfoTile(
          icon: Icons.location_on_outlined,
          title: 'Location',
          text: 'Main Campus Cafeteria',
        ),
        InfoTile(
          icon: Icons.email_outlined,
          title: 'Contact',
          text: 'campuscafeteria@example.com',
        ),
        SizedBox(height: 16),
        Eyebrow('Simple • Fast • Student Friendly', center: true),
      ],
    );
  }
}

// ===========================================================================
// CUSTOM (EXTRACTED) WIDGETS
// ===========================================================================

/// Round "CC" logo, like the canteen web navbar.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 31});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        'CC',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

/// Small spaced-out uppercase label that sits above headings.
class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  final bool center;

  const Eyebrow(
    this.text, {
    super.key,
    this.color = AppColors.primary,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
      ),
    );
  }
}

/// ListView.builder that shows one MenuCard per item.
class MenuList extends StatelessWidget {
  final List<MenuItem> items;
  final void Function(MenuItem) onFavorite;
  final void Function(MenuItem) onAddToCart;

  const MenuList(
      {super.key,
      required this.items,
      required this.onFavorite,
      required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items found.',
            style: TextStyle(color: AppColors.muted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MenuCard(
          item: item,
          onFavorite: () => onFavorite(item),
          onAddToCart: () => onAddToCart(item),
        );
      },
    );
  }
}

/// Card for a single menu item (white surface, thin border, round corners).
class MenuCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onFavorite;
  final VoidCallback onAddToCart;

  const MenuCard(
      {super.key,
      required this.item,
      required this.onFavorite,
      required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: AppStyle.cardShape(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with the heart button floating on top
            Stack(
              children: [
                FoodImage(item: item, size: 96),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkResponse(
                    onTap: onFavorite,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4)
                        ],
                      ),
                      child: Icon(
                        item.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 16,
                        color: item.isFavorite
                            ? AppColors.heart
                            : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.sky,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PriceTag(price: item.price),
                      OutlinedButton(
                        onPressed: () {
                          onAddToCart();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} added to cart'),
                              action: SnackBarAction(
                                  label: 'UNDO',
                                  onPressed: () {
                                    // UNDO in the shell's cart
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                  }),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(0, 32),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          side: const BorderSide(color: AppColors.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('+ Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a LOCAL asset image or a NETWORK image depending on the item.
class FoodImage extends StatelessWidget {
  final MenuItem item;
  final double size;

  const FoodImage({super.key, required this.item, required this.size});

  Widget _placeholder() => Container(
        width: size,
        height: size,
        color: AppColors.skySoft,
        child: const Icon(Icons.fastfood, color: AppColors.primary),
      );

  @override
  Widget build(BuildContext context) {
    final Widget image;

    if (item.imageUrl != null) {
      // NETWORK image
      image = Image.network(
        item.imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(),
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else if (item.imageAsset != null) {
      // LOCAL image
      image = Image.asset(
        item.imageAsset!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else {
      image = _placeholder();
    }

    return ClipRRect(borderRadius: BorderRadius.circular(12), child: image);
  }
}

class PriceTag extends StatelessWidget {
  final double price;

  const PriceTag({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    return Text(
      '₱${price.toStringAsFixed(0)}',
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
    );
  }
}

/// Stat shown on the blue band (top line, small label, big number).
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.skyLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.skyLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty cart placeholder in the bottom sheet.
class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: AppColors.muted),
          SizedBox(height: 16),
          Text('Your cart is empty.\nAdd items from the menu to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.6)),
        ],
      ),
    );
  }
}

/// Single row in the cart bottom sheet (image, name, qty, price).
class _CartItemRow extends StatelessWidget {
  final CartItem cartItem;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CartItemRow({
    required this.cartItem,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FoodImage(item: cartItem.menuItem, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cartItem.menuItem.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
              Text('₱${cartItem.menuItem.price.toStringAsFixed(0)} x ${cartItem.quantity}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
        Text('₱${cartItem.totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(width: 8),
        SizedBox(
          width: 88,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: onDecrement,
                ),
              ),
              Text('${cartItem.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: onIncrement,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const InfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: AppStyle.cardShape(),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          radius: 21,
          backgroundColor: AppColors.skySoft,
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          text,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ),
    );
  }
}
