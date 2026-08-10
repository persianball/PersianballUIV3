import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';

import '../../constant/urls.dart';

class CourseCartItemCard extends StatefulWidget {
  final CartItemFromBackend cartItemFromBackend;
  final TotalPriceFromBack priceFromBack;

  const CourseCartItemCard({Key? key, required this.cartItemFromBackend, required this.priceFromBack}) : super(key: key);

  @override
  _CourseCartItemCardState createState() => _CourseCartItemCardState();
}

class _CourseCartItemCardState extends State<CourseCartItemCard> {
  int quantity = 1;
  bool isLoading = false;
  bool isDeleteLoading = false;

  @override
  Widget build(BuildContext context) {
    quantity = widget.cartItemFromBackend.quantity;
    String? courseName = widget.cartItemFromBackend.course?.courseName;
    String? location = widget.cartItemFromBackend.course?.location;
    String? image = widget.cartItemFromBackend.course?.image;
    int? originalPrice = widget.cartItemFromBackend.course != null && widget.cartItemFromBackend.course?.price != null
        ? widget.cartItemFromBackend.course!.price! * widget.cartItemFromBackend.quantity
        : 0;
    int? discountPercent = widget.cartItemFromBackend.course?.discountPercentage;
    int? discountedPrice = widget.cartItemFromBackend.course?.discountPercentage != null
        ? (originalPrice * (1 - widget.cartItemFromBackend.course!.discountPercentage! / 100.0)).toInt()
        : originalPrice;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Course Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Course Image
                  Row(
                    children: [
                      // Course Title
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  courseName ?? "",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                // Subtitle
                                Text(
                                  location ?? "",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'دوره آموزشی',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: image != null
                              ? Image.network(
                                  "${URLs.baseUrl}$image",
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Icons.school, size: 40, color: Colors.blueAccent),
                                )
                              : Icon(Icons.school, size: 40, color: Colors.blueAccent),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Features List
                  Column(
                    children: [
                      _buildFeatureRow(Icons.school, 'آموزش حرفه‌ای'),
                      SizedBox(height: 8),
                      _buildFeatureRow(Icons.group, 'کلاس گروهی'),
                      SizedBox(height: 8),
                      _buildFeatureRow(Icons.access_time, 'زمان‌بندی انعطاف‌پذیر'),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Gift Product Section
                  if (widget.cartItemFromBackend.course?.giftProduct != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          // Gift Image
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: widget.cartItemFromBackend.course!.giftProduct!.image != null
                                  ? Image.network(
                                      "${URLs.baseUrl}${widget.cartItemFromBackend.course!.giftProduct!.image}",
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(Icons.card_giftcard, size: 30, color: Colors.green),
                                    )
                                  : Icon(Icons.card_giftcard, size: 30, color: Colors.green),
                            ),
                          ),
                          SizedBox(width: 12),
                          // Gift Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'هدیه ویژه',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[800],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  widget.cartItemFromBackend.course!.giftProduct!.productName ?? 'محصول هدیه',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.cartItemFromBackend.course!.giftProduct!.color != null)
                                  Text(
                                    'رنگ: ${widget.cartItemFromBackend.course!.giftProduct!.color}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 20),
                  // Price Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'تومان',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        thousandSeparator(discountedPrice),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Original Price (crossed out)
                  if (discountPercent != null && discountPercent != 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "$discountPercent%",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      SizedBox(width: 8),
                      Text(
                        thousandSeparator(originalPrice),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Quantity and Action Buttons
                  BlocConsumer<CartBloc, CartState>(
                    listener: (context, state) {
                      if (state is CartError) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                      }
                      if (state is CartLoaded) {
                        setState(() {
                          isLoading = false;
                          isDeleteLoading = false;
                        });
                      }
                    },
                    builder: (context, state) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Delete Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Builder(
                              builder: (context) {
                                if (isDeleteLoading) {
                                  return Center(
                                    child: LoadingAnimationWidget.progressiveDots(
                                      color: const Color(0xFF1A1A3F),
                                      size: 10,
                                    ),
                                  );
                                }
                                return IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red[600]),
                                  onPressed: () {
                                    setState(() {
                                      isDeleteLoading = true;
                                    });
                                    context.read<CartBloc>().add(RemoveFromCart(context, widget.cartItemFromBackend.id));
                                  },
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          // Quantity Controls
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.add, color: Colors.green[600]),
                                  onPressed: () {
                                    setState(() {
                                      quantity++;
                                    });
                                    context.read<CartBloc>().add(UpdateQuantity(context, widget.cartItemFromBackend.id,null, widget.cartItemFromBackend.course!.id, quantity));
                                    setState(() {
                                      isLoading = true;
                                    });
                                  },
                                ),
                                Builder(
                                  builder: (context) {
                                    if (isLoading) {
                                      return Center(
                                        child: LoadingAnimationWidget.twistingDots(
                                          leftDotColor: const Color(0xFF1A1A3F),
                                          rightDotColor: const Color(0xFFEA3799),
                                          size: 10,
                                        ),
                                      );
                                    }
                                    return Container(
                                      width: 40,
                                      child: Text(
                                        '${widget.cartItemFromBackend.quantity}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove, color: Colors.grey[600]),
                                  onPressed: () {
                                    if (quantity > 1) {
                                      setState(() {
                                        quantity--;
                                      });
                                      context.read<CartBloc>().add(UpdateQuantity(context, widget.cartItemFromBackend.id,null, widget.cartItemFromBackend.course!.id, quantity));
                                      setState(() {
                                        isLoading = true;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.green[600]),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
