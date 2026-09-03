// lib/utils/json_parse.dart
//
// کمک‌تابع‌های کوچک برای خواندن اعداد از پاسخ API.
//
// انگیزه: بک‌اند برای فیلدهای ارجاعی (مثل `coach`، `support_coach`، `classes`)
// گاهی فقط شناسه و گاهی کل آبجکت را برمی‌گرداند، و بعضی اعداد به‌صورت رشته
// می‌آیند. نسبت‌دادن مستقیمِ این مقادیر به `int?` باعث می‌شد کل پارس با
// «_JsonMap is not a subtype of type int?» بشکند و یک صفحه‌ی کامل (مثل سبد
// خرید) از کار بیفتد.

/// عدد را از مقداری که ممکن است عدد، رشته یا آبجکتِ دارای `id` باشد بیرون
/// می‌کشد. اگر قابل تبدیل نبود `null` برمی‌گرداند.
int? asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  if (value is Map) return asInt(value['id']);
  return null;
}

/// نسخه‌ی اجباری [asInt] برای فیلدهایی مثل `id` که بدون آن‌ها رکورد بی‌معناست.
///
/// [field] نام فیلد است و در متن خطا می‌آید تا در لاگ معلوم شود کدام بخش از
/// پاسخ سرور عوض شده است.
int requireInt(dynamic value, String field) {
  final parsed = asInt(value);
  if (parsed == null) {
    throw FormatException('فیلد «$field» عدد نیست: $value');
  }
  return parsed;
}
