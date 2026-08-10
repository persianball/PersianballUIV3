// lib/views/screens/payment_webview_page.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:marketky/views/widgets/checkout_timeline.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String paymentUrl;
  const PaymentWebViewPage({super.key, required this.paymentUrl});

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  bool loading = true;
  late final WebViewController _controller;

  late final PlatformWebViewControllerCreationParams params;


  @override
  void initState() {
    super.initState();



    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => loading = true),
          onPageFinished: (_) => setState(() => loading = false),
          onNavigationRequest: (req) {
            // در اینجا می‌توانید آدرس بازگشت (callback) را بررسی کنید
            // و وضعیت پرداخت را از سرور بگیرید
            return NavigationDecision.navigate;
          },
          onHttpError: (er) {
            // Handle HTTP errors here
            setState(() {
              loading = false;
            });

            print(er);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت آنلاین', style: TextStyle(color: Colors.black))),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: CheckoutTimeline(currentStep: 2),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                    child: WebViewWidget(controller: _controller),
                  color: Colors.red,
                ),
                if (loading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}