import 'package:flutter/widgets.dart';

/// بیرون از وب، سیستم خودش فاصله‌ها را در MediaQuery می‌گذارد.
final ValueNotifier<EdgeInsets> webSafeArea =
    ValueNotifier<EdgeInsets>(EdgeInsets.zero);

void initWebSafeArea() {}
