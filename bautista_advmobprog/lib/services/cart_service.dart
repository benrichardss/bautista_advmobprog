import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart_model.dart';

class CartService {
  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  //LAB ACTIVITY 3 ENHANCEMENT 3: Read the Cart documentation https://dummyjson.com/docs/carts and check how to integrate cart by user id. To render only one user cart. Also try to use add to cart by passing the values of the product => cart https://dummyjson.com/carts/add  
  Future<Cart?> getCartByUserId(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final cartsJson = data['carts'] as List? ?? [];
      if (cartsJson.isEmpty) return null;
      return Cart.fromJson(cartsJson.first as Map<String, dynamic>);
    }

    throw Exception('Failed to load cart for user $userId');
  }

  Future<Cart> addToCart({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {'id': productId, 'quantity': quantity},
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Cart.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to add product to cart');
  }
}
