import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';

import '../services/product_service.dart';

import '../widgets/custom_text.dart';
import 'product_details_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late final Future<List<Product>> _productsFuture;

  final int _pageSize = 10;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override

  void initState() {
    super.initState();
    _productsFuture = _loadFirstPage();
  }

  Future<List<Product>> _loadFirstPage() async {
    final products = await ProductService().getProducts(
      limit: _pageSize,
      skip: 0,
    );

    _allProducts = products;
    _filteredProducts = products;
    return products;
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = await ProductService().getProducts(
        limit: _pageSize,
        skip: (_currentPage + 1) * _pageSize,
        query: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        _currentPage++;

        if (nextPage.length < _pageSize) {
          _hasMore = false;
        }

        _allProducts.addAll(nextPage);
        _filteredProducts = _allProducts;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _filterProducts(String query) async {
    setState(() {
      _searchQuery = query.trim();
      _isLoadingMore = true;
    });

    try {
      final products = await ProductService().getProducts(
        limit: _pageSize,
        skip: 0,
        query: _searchQuery,
      );

      if (!mounted) return;

      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _currentPage = 0;
        _hasMore = products.length == _pageSize;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //LAB ACTIVITY 2 ENHANCEMENT 1: ADD SEARCH BAR ABOVE THE ARTICLE LIST.
            TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: "Search",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.r),
                      child: const CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: CustomText(
                      text: 'Error: ${snapshot.error}',
                      fontSize: 14.sp,
                    ),
                  );
                }

                if (_allProducts.isEmpty && snapshot.hasData) {
                  _allProducts = snapshot.data!;
                  _filteredProducts = _allProducts;
                }
                if (_filteredProducts.isEmpty) {
                  return Center(
                    child: CustomText(
                      text: 'No products found',
                      fontSize: 14.sp,
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredProducts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12.r),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailsScreen(product: product),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.r),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Image.network(
                                  product.thumbnail,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(Icons.image, size: 24.sp),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: product.title,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    text: '₱${product.price.toStringAsFixed(2)}',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    );
                  },
                );
              },
            ),
            if (_hasMore)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Center(
                child: FilledButton(
                  onPressed: _isLoadingMore ? null : _loadNextPage,
                  child: _isLoadingMore
                      ? const CircularProgressIndicator()
                      : const Text('Load more'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
