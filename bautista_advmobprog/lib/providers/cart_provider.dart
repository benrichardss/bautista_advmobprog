import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();

  final List<CartProduct> _items = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  List<CartProduct> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int? _loadedUserId;

  Future<void> loadCart(int userId) async {
    if (_hasLoaded && _loadedUserId == userId) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cart = await _cartService.getCartByUserId(userId);

      _items
        ..clear()
        ..addAll(cart?.products ?? []);

      _loadedUserId = userId;
      _hasLoaded = true;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addProduct(Product product) {
    final index = _items.indexWhere((item) => item.id == product.id);

    if (index >= 0) {
      final item = _items[index];
      _items[index] = _copyItem(item, item.quantity + 1);
    } else {
      _items.add(
        CartProduct(
          id: product.id,
          title: product.title,
          price: product.price,
          quantity: 1,
          total: product.price,
          discountPercentage: product.discountPercentage,
          discountedTotal:
              product.price - product.price * product.discountPercentage / 100,
          thumbnail: product.thumbnail,
        ),
      );
    }

    notifyListeners();
  }

  void increase(CartProduct item) {
    final index = _items.indexWhere((cartItem) => cartItem.id == item.id);
    if (index < 0) return;

    _items[index] = _copyItem(item, item.quantity + 1);
    notifyListeners();
  }

  void decrease(CartProduct item) {
    final index = _items.indexWhere((cartItem) => cartItem.id == item.id);
    if (index < 0) return;

    if (item.quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index] = _copyItem(item, item.quantity - 1);
    }

    notifyListeners();
  }

  void remove(CartProduct item) {
    _items.removeWhere((cartItem) => cartItem.id == item.id);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _hasLoaded = false;
    _error = null;
    notifyListeners();
  }

  CartProduct _copyItem(CartProduct item, int quantity) {
    return CartProduct(
      id: item.id,
      title: item.title,
      price: item.price,
      quantity: quantity,
      total: item.price * quantity,
      discountPercentage: item.discountPercentage,
      discountedTotal:
          (item.price - item.price * item.discountPercentage / 100) * quantity,
      thumbnail: item.thumbnail,
    );
  }
}
