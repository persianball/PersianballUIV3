import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';

import '../../constant/urls.dart';

class ProCartItemCard extends StatefulWidget {
  final CartItemFromBackend cartItemFromBackend;
  final TotalPriceFromBack priceFromBack;

  const ProCartItemCard({Key? key, required this.cartItemFromBackend, required this.priceFromBack}) : super(key: key);

  @override
  _ProCartItemCardState createState() => _ProCartItemCardState();
}

class _ProCartItemCardState extends State<ProCartItemCard> {
  int quantity = 1;
  bool isLoading = false;
  bool isDeleteLoading = false;

  @override
  Widget build(BuildContext context) {
    quantity = widget.cartItemFromBackend.quantity;
    String? farsiName = widget.cartItemFromBackend.product?.productVariant?.productName;
    String? colorName = widget.cartItemFromBackend.product?.productVariant?.color;
    int? originalPrice =widget.cartItemFromBackend.product !=null && widget.cartItemFromBackend.product?.price != null? widget.cartItemFromBackend.product!.price! * widget.cartItemFromBackend.quantity:0;
    int? discountPercent = widget.cartItemFromBackend.product?.disountPercentage;
    int? discountedPrice = originalPrice!=null ? widget.cartItemFromBackend.product?.disountPercentage != null ?  (originalPrice *(1-widget.cartItemFromBackend.product!.disountPercentage! / 100.0)).toInt() : originalPrice : 0;
    return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end, // Right-to-left alignment for Persian text
            children: [

              // Product Card
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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // Product Image
                    Row(
                      children: [

                        // Product Title
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    farsiName??"",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      height: 1.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  SizedBox(height: 8),

                                  // Subtitle
                                  Text(
                                    colorName??"",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        Container(
                          height: 64,
                          width: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              "${URLs.baseUrl}${widget.cartItemFromBackend.product!.productVariant!.image}",
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Image.asset('assets/images/placeholder.jpg'),
                            ),
                          ),

                        ),



                      ],
                    ),

                    SizedBox(height: 16),

                    // Features List
                    Column(
                      children: [
                        _buildFeatureRow(Icons.check_circle_outline, 'بسته بندی حرفه‌ای'),
                        SizedBox(height: 8),
                        _buildFeatureRow(Icons.check_circle_outline, 'ضمانت یک ساله'),
                        SizedBox(height: 8),
                        widget.priceFromBack.isFreeShipping!=null&&
                        widget.priceFromBack.isFreeShipping! ?_buildFeatureRow(Icons.check_circle_outline, 'ارسال رایگان ') :
                        _buildFeatureRow(Icons.motorcycle, '${widget.priceFromBack.postShippingPrice}:هزینه ارسال '),
                      ],
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    // Original Price (crossed out)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        discountPercent != null
                            || discountPercent != 0 ?
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 4.0,
                            horizontal: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text("${
                            discountPercent
                            }%",
                            style: TextStyle(color: Colors.white),),
                          ),
                        ):Container(),
                        SizedBox(width: 8,),
                        Text(
                          thousandSeparator(originalPrice??0),
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
                    BlocConsumer<CartBloc,CartState>(
                      listener: (context,state){
                        if(state is CartError){
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                        }
                        if(state is CartLoaded){
                          setState(() {
                            isLoading = false;
                            isDeleteLoading = false;
                          });
                        }

                      },
                      builder: (context,state) {

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

                                  if(isDeleteLoading){
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
                                      context.read<CartBloc>().add(RemoveFromCart(widget.cartItemFromBackend.id));

                                    },
                                  );
                                }
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
                                      context.read<CartBloc>().add(UpdateQuantity(widget.cartItemFromBackend.id,widget.cartItemFromBackend.product!.id,quantity));
                                      setState(() {
                                        isLoading = true;
                                      });
                                    },
                                  ),
                                  Builder(
                                    builder: (context) {
                                      if(isLoading){
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
                                    }
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.remove, color: Colors.grey[600]),
                                    onPressed: () {
                                      if (quantity > 1) {
                                        setState(() {
                                          quantity--;
                                        });

                                        context.read<CartBloc>().add(UpdateQuantity(widget.cartItemFromBackend.id,widget.cartItemFromBackend.product!.id,quantity));

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



                        throw Exception("مشکلی در دریافت سبد ایجاد شده است.");

                      }
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  }

  // Helper method to build feature rows
  Widget _buildFeatureRow(IconData icon, String text, {bool isSpecial = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isSpecial ? Colors.red[600] : Colors.grey[700],
              height: 1.3,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        SizedBox(width: 8),
        Icon(
          icon,
          size: 16,
          color: isSpecial ? Colors.red[600] : Colors.green[600],
        ),
      ],
    );
  }
}