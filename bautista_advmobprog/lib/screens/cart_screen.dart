//LAB ACTIVITY 3 ENHANCEMENT 1: Make a cart_screen in order to render the new API endpoint. The items on the cart_screen must be clickable going to the detail_screen for the utilization of the screen widget.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart_model.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';
import 'product_details_screen.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  final int userId;

  const CartScreen({super.key, this.userId = 30});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart(widget.userId);
    });
  }

  Future<void> _openProduct(CartProduct item) async {
    try {
      final product = await ProductService().getProductById(item.id);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProductDetailsScreen(product: product, fromCart: true),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open product')));
    }
  }

  Future<void> _confirmOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Order'),
          content: const Text(
            'Are you sure you want to place this order?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order confirmed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.items;

    if (cartProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (cartProvider.error != null) {
      return Center(
        child: Text(
          'Unable to load cart',
          style: TextStyle(fontSize: 16.sp),
        ),
      );
    }

    if (cartItems.isEmpty) {
      return _EmptyCart();
    }

    double subtotal = 0;
    double total = 0;
    double savings = 0;

    for (final item in cartItems) {
      final quantity = item.quantity;

      final originalPrice = item.price;
      final discountedPrice =
          item.price - (item.price * item.discountPercentage / 100);

      subtotal += originalPrice * quantity;
      total += discountedPrice * quantity;
      savings += (originalPrice - discountedPrice) * quantity;
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      children: [
        ...cartItems.map((item) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _CartItem(
              item: item,
              quantity: item.quantity,
              onTap: () => _openProduct(item),
              onIncrease: () => cartProvider.increase(item),
              onDecrease: () => cartProvider.decrease(item),
            ),
          );
        }),

        SizedBox(height: 8.h),

        _OrderSummary(
          subtotal: subtotal,
          total: total,
          savings: savings,
        ),

        SizedBox(height: 16.h),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _confirmOrder,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirm Order'),
          ),
        ),
      ],
    );
  }
}

class _CartItem extends StatelessWidget {
  final CartProduct item;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _CartItem({
    required this.item,
    required this.quantity,
    required this.onTap,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = item.discountPercentage > 0;
    final discountedPrice =
        item.price - (item.price * (item.discountPercentage / 100));

    final savings = (item.price - discountedPrice) * quantity;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductImage(imageUrl: item.thumbnail),

                  SizedBox(width: 12.w),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: 6.h),

                        Row(
                          children: [
                            if (hasDiscount)
                              Text(
                                '₱${item.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),

                            if (hasDiscount) SizedBox(width: 6.w),

                            Text(
                              '₱${(item.price - (item.price * (item.discountPercentage / 100))).toStringAsFixed(2)} each',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        if (hasDiscount) ...[
                          SizedBox(height: 5.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6.r),
                              color: Colors.green.withValues(alpha: 0.1),
                            ),
                            child: Text(
                              '${item.discountPercentage.toStringAsFixed(0)}% OFF',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              Row(
                children: [
                  if (hasDiscount)
                    Expanded(
                      child: Text(
                        'You save ₱${savings.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    const Spacer(),

                  _QuantitySelector(
                    quantity: quantity,
                    onIncrease: onIncrease,
                    onDecrease: onDecrease,
                  ),

                  SizedBox(width: 12.w),

                  Text(
                    '₱${((item.price - (item.price * (item.discountPercentage / 100))) * quantity).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _QuantitySelector({
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest,),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDecrease,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8.r),
              bottomLeft: Radius.circular(8.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(7.r),
              child: Icon(
                quantity == 1 ? Icons.delete_outline : Icons.remove,
                size: 17.sp,
              ),
            ),
          ),

          SizedBox(
            width: 30.w,
            child: Center(
              child: Text(
                '$quantity',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          InkWell(
            onTap: onIncrease,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(8.r),
              bottomRight: Radius.circular(8.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(7.r),
              child: Icon(Icons.add, size: 17.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String imageUrl;

  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90.w,
      height: 90.w,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Icon(
              Icons.image_not_supported_outlined,
              size: 30.sp,
              color: Colors.grey,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final double subtotal;
  final double total;
  final double savings;

  const _OrderSummary({
    required this.subtotal,
    required this.total,
    required this.savings,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: 'Order Summary',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),

            SizedBox(height: 16.h),

            _SummaryRow(
              label: 'Subtotal',
              value: '₱${subtotal.toStringAsFixed(2)}',
            ),

            SizedBox(height: 10.h),

            _SummaryRow(
              label: 'Discount',
              value: '-₱${savings.toStringAsFixed(2)}',
              valueColor: Colors.green.shade700,
            ),

            SizedBox(height: 10.h),

            const Divider(),

            SizedBox(height: 10.h),

            _SummaryRow(
              label: 'Total',
              value: '₱${total.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 19.sp : 14.sp,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80.sp,
              color: Colors.grey.shade400,
            ),

            SizedBox(height: 16.h),

            CustomText(
              text: 'Your cart is empty',
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),

            SizedBox(height: 8.h),

            Text(
              'Products you add to your cart will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }
}
