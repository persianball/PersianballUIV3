import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:marketky/views/screens/search_page.dart';

import '../../bloc/cart/cart_bloc.dart';
import '../screens/cart_page.dart';
import 'custom_icon_button_widget.dart';
import 'dummy_search_widget_1.dart';
import '../screens/message_page.dart';
import '../../services/auth_service.dart';
import '../../services/user_message_service.dart';

Widget buildCarouselItem(BuildContext context,String imageUrl) {
  context.read<CartBloc>().add(LoadCart(context));
  return Container(
    width: MediaQuery.of(context).size.width,
    padding: EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(imageUrl),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.black.withOpacity(0.3), // فیلتر تیره برای خوانایی متن
          BlendMode.darken,
        ),
      ),
    ),
    child: Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 26),
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Text(
                  'بهترین ست‌های پوشاک\nرا برای خود پیدا کنید.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                textDirection: TextDirection.ltr,
                children: [
                  BlocBuilder<CartBloc,CartState>(
                    builder: (context,state) {
                      return CustomIconButtonWidget(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => CartPage()));
                        },
                        value: state is CartLoaded ? state.cart.results.length > 0?
                            state.cart.results[0].items.length
                            : 0 : 0,
                        icon: SvgPicture.asset(
                          'assets/icons/Bag.svg',
                          color: Colors.white,
                        ),
                      );
                    }
                  ),
                  SizedBox(width: 16),
                  const MessagesIconButton(),
                ],
              ),
            ],
          ),
        ),
        DummySearchWidget1(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SearchPage(),
              ),
            );
          },
        ),
      ],
    ),
  );
}
/// آیکنِ پیام‌ها در نوار بالای صفحه‌ی خانه، با بجِ خوانده‌نشده‌های واقعی.
///
/// بج پیش‌تر عدد ثابتِ ۲ بود. حالا از /v1/user/message/ خوانده می‌شود؛
/// چون [buildCarouselItem] با هر اسلاید دوباره اجرا می‌شود، درخواست عمداً
/// اینجا (در initState یک ویجت جدا) زده می‌شود نه در بدنه‌ی کاروسل، وگرنه
/// هر چرخشِ اسلاید یک درخواست تازه می‌فرستاد.
class MessagesIconButton extends StatefulWidget {
  const MessagesIconButton({super.key});

  @override
  State<MessagesIconButton> createState() => _MessagesIconButtonState();
}

class _MessagesIconButtonState extends State<MessagesIconButton> {
  @override
  void initState() {
    super.initState();
    UserMessageService.refreshUnread();
    // ورود/خروجِ وسطِ کار: بج باید با حساب جدید یکی شود.
    AuthService.authRevision.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService.authRevision.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() => UserMessageService.refreshUnread();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: UserMessageService.unreadNotifier,
      builder: (context, unread, _) => CustomIconButtonWidget(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MessagePage()),
          );
          UserMessageService.refreshUnread();
        },
        value: unread,
        icon: SvgPicture.asset(
          'assets/icons/Chat.svg',
          color: Colors.white,
        ),
      ),
    );
  }
}
