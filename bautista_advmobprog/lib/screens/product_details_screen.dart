//ENHANCEMENT 2: ADD DETAILS PAGE WHEN CLICKED THE CARD.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product_model.dart';
import '../widgets/custom_text.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // IMAGE CAROUSEL
            // --------------------------------------------------

            _buildImageCarousel(),

            SizedBox(height: 20.h),

            // --------------------------------------------------
            // PRODUCT TITLE
            // --------------------------------------------------

            CustomText(
              text: product.title,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),

            SizedBox(height: 8.h),

            // --------------------------------------------------
            // CATEGORY + BRAND
            // --------------------------------------------------

            Row(
              children: [
                _buildChip(
                  product.category,
                  Icons.category_outlined,
                  context,
                ),
                SizedBox(width: 8.w),
                if (product.brand.isNotEmpty)
                  _buildChip(
                    product.brand,
                    Icons.business_outlined,
                    context,
                  ),
              ],
            ),

            SizedBox(height: 14.h),

            // --------------------------------------------------
            // RATING
            // --------------------------------------------------

            Row(
              children: [
                ...List.generate(
                  5,
                  (index) {
                    if (index < product.rating.floor()) {
                      return Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20.sp,
                      );
                    }

                    return Icon(
                      Icons.star_border,
                      color: Colors.amber,
                      size: 20.sp,
                    );
                  },
                ),

                SizedBox(width: 8.w),

                CustomText(
                  text: product.rating.toStringAsFixed(1),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),

                SizedBox(width: 6.w),

                CustomText(
                  text: '(${product.reviews.length} reviews)',
                  fontSize: 13.sp,
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // --------------------------------------------------
            // PRICE
            // --------------------------------------------------

            _buildPriceSection(context),

            SizedBox(height: 16.h),

            // --------------------------------------------------
            // AVAILABILITY
            // --------------------------------------------------

            _buildAvailability(),

            SizedBox(height: 20.h),

            // --------------------------------------------------
            // DESCRIPTION
            // --------------------------------------------------

            _buildSectionCard(
              title: 'Description',
              icon: Icons.description_outlined,
              child: CustomText(
                text: product.description,
                fontSize: 14.sp,
              ),
            ),

            SizedBox(height: 14.h),

            // --------------------------------------------------
            // PRODUCT INFORMATION
            // --------------------------------------------------

            _buildSectionCard(
              title: 'Product Information',
              icon: Icons.info_outline,
              child: Column(
                children: [
                  _infoRow(
                    'Brand',
                    product.brand.isEmpty
                        ? 'N/A'
                        : product.brand,
                  ),
                  _infoRow(
                    'Category',
                    product.category,
                  ),
                  _infoRow(
                    'SKU',
                    product.sku,
                  ),
                  _infoRow(
                    'Stock',
                    '${product.stock} units',
                  ),
                  _infoRow(
                    'Minimum Order',
                    '${product.minimumOrderQuantity} units',
                  ),
                  _infoRow(
                    'Weight',
                    '${product.weight} g',
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // --------------------------------------------------
            // DIMENSIONS
            // --------------------------------------------------

            _buildSectionCard(
              title: 'Dimensions',
              icon: Icons.straighten,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                children: [
                  _dimensionItem(
                    'Width',
                    product.dimensions.width,
                  ),
                  _dimensionItem(
                    'Height',
                    product.dimensions.height,
                  ),
                  _dimensionItem(
                    'Depth',
                    product.dimensions.depth,
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // --------------------------------------------------
            // TAGS
            // --------------------------------------------------

            if (product.tags.isNotEmpty)
              _buildSectionCard(
                title: 'Tags',
                icon: Icons.sell_outlined,
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: product.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                    );
                  }).toList(),
                ),
              ),

            SizedBox(height: 14.h),

            // --------------------------------------------------
            // SHIPPING
            // --------------------------------------------------

            _buildInformationTile(
              icon: Icons.local_shipping_outlined,
              title: 'Shipping',
              description:
                  product.shippingInformation,
            ),

            SizedBox(height: 10.h),

            // --------------------------------------------------
            // WARRANTY
            // --------------------------------------------------

            _buildInformationTile(
              icon: Icons.verified_outlined,
              title: 'Warranty',
              description:
                  product.warrantyInformation,
            ),

            SizedBox(height: 10.h),

            // --------------------------------------------------
            // RETURN POLICY
            // --------------------------------------------------

            _buildInformationTile(
              icon: Icons.assignment_return_outlined,
              title: 'Return Policy',
              description: product.returnPolicy,
            ),

            SizedBox(height: 20.h),

            // --------------------------------------------------
            // IMAGE GALLERY
            // --------------------------------------------------

            if (product.images.isNotEmpty)
              _buildGallery(),

            SizedBox(height: 20.h),

            // --------------------------------------------------
            // REVIEWS
            // --------------------------------------------------

            _buildReviews(context),

            SizedBox(height: 20.h),

            // --------------------------------------------------
            // META INFORMATION
            // --------------------------------------------------
            
            /*
            _buildSectionCard(
              title: 'Additional Information',
              icon: Icons.qr_code_2,
              child: Column(
                children: [
                  _infoRow(
                    'Barcode',
                    product.meta.barcode,
                  ),
                  _infoRow(
                    'Created',
                    _formatDate(product.meta.createdAt),
                  ),
                  _infoRow(
                    'Updated',
                    _formatDate(product.meta.updatedAt),
                  ),
                ],
              ),
            ),
            */
            
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE CAROUSEL
  // ============================================================

  Widget _buildImageCarousel() {
    return SizedBox(
      height: 280.h,
      child: PageView.builder(
        itemCount: product.images.isEmpty
            ? 1
            : product.images.length,
        itemBuilder: (context, index) {
          final image = product.images.isEmpty
              ? product.thumbnail
              : product.images[index];

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: Image.network(
                image,
                fit: BoxFit.contain,
                width: double.infinity,
                errorBuilder: (_, __, ___) {
                  return Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 50.sp,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // PRICE SECTION
  // ============================================================

  Widget _buildPriceSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomText(
            text: '\$${product.price.toStringAsFixed(2)}',
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
          ),

          SizedBox(width: 12.w),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8.w,
              vertical: 5.h,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: CustomText(
              text:
                  '${product.discountPercentage.toStringAsFixed(0)}% OFF',
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AVAILABILITY
  // ============================================================

  Widget _buildAvailability() {
    final isAvailable = product.stock > 0;

    return Row(
      children: [
        Icon(
          isAvailable
              ? Icons.check_circle
              : Icons.cancel,
          color: isAvailable
              ? Colors.green
              : Colors.red,
          size: 20.sp,
        ),

        SizedBox(width: 8.w),

        CustomText(
          text: product.availabilityStatus.isNotEmpty
              ? product.availabilityStatus
              : isAvailable
                  ? 'In Stock'
                  : 'Out of Stock',
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),

        if (isAvailable) ...[
          SizedBox(width: 6.w),
          CustomText(
            text: '(${product.stock} available)',
            fontSize: 13.sp,
          ),
        ],
      ],
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20.sp),

                SizedBox(width: 8.w),

                CustomText(
                  text: title,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),

            SizedBox(height: 14.h),

            child,
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: CustomText(
              text: label,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),

          Expanded(
            child: CustomText(
              text: value.isEmpty ? 'N/A' : value,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIMENSION ITEM
  // ============================================================

  Widget _dimensionItem(
    String label,
    double value,
  ) {
    return Column(
      children: [
        Icon(
          Icons.straighten,
          size: 22.sp,
        ),

        SizedBox(height: 6.h),

        CustomText(
          text: label,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),

        SizedBox(height: 3.h),

        CustomText(
          text: '${value.toStringAsFixed(1)} cm',
          fontSize: 12.sp,
        ),
      ],
    );
  }

  // ============================================================
  // INFORMATION TILE
  // ============================================================

  Widget _buildInformationTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 6.h,
        ),
        leading: Icon(icon),

        title: CustomText(
          text: title,
          fontSize: 15.sp,
          fontWeight: FontWeight.bold,
        ),

        subtitle: Padding(
          padding: EdgeInsets.only(top: 5.h),
          child: CustomText(
            text: description.isEmpty
                ? 'N/A'
                : description,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GALLERY
  // ============================================================

  Widget _buildGallery() {
    return _buildSectionCard(
      title: 'Product Gallery',
      icon: Icons.photo_library_outlined,
      child: GridView.builder(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),
        itemCount: product.images.length,
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 10.h,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius:
                BorderRadius.circular(12.r),
            child: Image.network(
              product.images[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 30.sp,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // REVIEWS
  // ============================================================

  Widget _buildReviews(BuildContext context,) {
    return _buildSectionCard(
      title: 'Customer Reviews',
      icon: Icons.rate_review_outlined,
      child: product.reviews.isEmpty
          ? CustomText(
              text: 'No reviews available.',
              fontSize: 14.sp,
            )
          : Column(
              children: product.reviews.map((review) {
                return _buildReview(review, context);
              }).toList(),
            ),
    );
  }

  Widget _buildReview(ProductReview review, BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                child: Icon(
                  Icons.person,
                  size: 20.sp,
                ),
              ),

              SizedBox(width: 10.w),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: review.reviewerName,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),

                    SizedBox(height: 3.h),

                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < review.rating
                              ? Icons.star
                              : Icons.star_border,
                          size: 15.sp,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          CustomText(
            text: review.comment,
            fontSize: 13.sp,
          ),

          SizedBox(height: 6.h),

          CustomText(
            text: _formatDate(review.date),
            fontSize: 11.sp,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHIP
  // ============================================================

  Widget _buildChip(
    String text,
    IconData icon,
    BuildContext context
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
          ),

          SizedBox(width: 5.w),

          CustomText(
            text: text,
            fontSize: 11.sp,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE FORMATTER
  // ============================================================

  String _formatDate(String date) {
    if (date.isEmpty) {
      return 'N/A';
    }

    try {
      final parsedDate = DateTime.parse(date);

      return '${parsedDate.month}/'
          '${parsedDate.day}/'
          '${parsedDate.year}';
    } catch (_) {
      return date;
    }
  }
}