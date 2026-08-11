// lib/views/screens/static_pages.dart
//
// صفحات ثابت فروشگاه: قوانین، حریم خصوصی، درباره ما و تماس با پشتیبانی.
//
// وضعیت بک‌اند: محتوایی برای این صفحات ارائه نمی‌شود.
// پیشنهاد: GET /v1/content/pages/<slug>/ → {title, body_html, updated_at}
// تا متن‌ها بدون آپدیت اپ قابل تغییر باشند. فعلاً متن نمونه داخل اپ است.
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:url_launcher/url_launcher.dart';

class StaticContent {
  final String title;
  final List<String> paragraphs;

  const StaticContent({required this.title, required this.paragraphs});

  static const terms = StaticContent(
    title: 'قوانین و مقررات',
    paragraphs: [
      'با ثبت سفارش در این فروشگاه، شما می‌پذیرید که اطلاعات واردشده صحیح است و مسئولیت خطای اطلاعات تماس یا آدرس بر عهده خریدار است.',
      'قیمت‌ها و موجودی کالاها ممکن است تغییر کند. مبنای فروش، قیمت لحظه ثبت سفارش است.',
      'در صورت ناموجود شدن کالا پس از ثبت سفارش، مبلغ پرداختی حداکثر ظرف ۷۲ ساعت کاری به حساب خریدار بازگردانده می‌شود.',
      'مهلت درخواست مرجوعی برای کالاهای سالم و استفاده‌نشده، ۷ روز پس از تحویل است.',
      'این متن نمونه است و باید با متن حقوقی نهایی فروشگاه جایگزین شود.',
    ],
  );

  static const privacy = StaticContent(
    title: 'حریم خصوصی',
    paragraphs: [
      'اطلاعات شخصی شما شامل نام، شماره تماس و آدرس، تنها برای پردازش سفارش و ارسال کالا استفاده می‌شود.',
      'اطلاعات پرداخت شما نزد فروشگاه ذخیره نمی‌شود و پرداخت از طریق درگاه بانکی معتبر انجام می‌گیرد.',
      'اطلاعات شما بدون رضایت شما در اختیار اشخاص ثالث قرار نمی‌گیرد، مگر بر اساس الزام قانونی.',
      'شما می‌توانید هر زمان از طریق بخش «امنیت حساب» درخواست حذف حساب و داده‌های خود را ثبت کنید.',
      'این متن نمونه است و باید با سیاست حریم خصوصی نهایی جایگزین شود.',
    ],
  );

  static const about = StaticContent(
    title: 'درباره ما',
    paragraphs: [
      'پرشین‌بال فروشگاهی تخصصی در حوزه لوازم ورزشی و دوره‌های آموزشی فوتبال و فریستایل است.',
      'هدف ما فراهم کردن کالای اصل با قیمت منصفانه و آموزش‌های کاربردی برای ورزشکاران در همه سطوح است.',
      'این متن نمونه است و باید با معرفی نهایی فروشگاه جایگزین شود.',
    ],
  );
}

class StaticContentPage extends StatelessWidget {
  final StaticContent content;

  const StaticContentPage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: Text(content.title,
              style: const TextStyle(fontFamily: 'Estedad', fontSize: 16)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: content.paragraphs
                .map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        p,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                            fontFamily: 'Estedad', fontSize: 13, height: 2),
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// تماس با پشتیبانی: تماس تلفنی، ایمیل و پیام‌رسان
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const String phone = '02100000000';
  static const String email = 'support@persianball.ir';

  Future<void> _open(BuildContext context, Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('امکان باز کردن این برنامه وجود ندارد',
              style: TextStyle(fontFamily: 'Estedad')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: const Text('پشتیبانی',
              style: TextStyle(fontFamily: 'Estedad', fontSize: 16)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'ساعات پاسخگویی: شنبه تا چهارشنبه، ۹ تا ۱۷',
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12,
                    color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              _tile(
                icon: Icons.call_outlined,
                title: 'تماس تلفنی',
                subtitle: phone,
                onTap: () => _open(context, Uri.parse('tel:$phone')),
              ),
              _tile(
                icon: Icons.mail_outline,
                title: 'ایمیل',
                subtitle: email,
                onTap: () => _open(context, Uri.parse('mailto:$email')),
              ),
              _tile(
                icon: Icons.chat_bubble_outline,
                title: 'پیام در واتس‌اپ',
                subtitle: 'پاسخ در کمتر از ۲۴ ساعت',
                onTap: () => _open(
                    context, Uri.parse('https://wa.me/98$phone')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColor.primary),
        title: Text(title,
            style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Estedad', fontSize: 12)),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }
}
