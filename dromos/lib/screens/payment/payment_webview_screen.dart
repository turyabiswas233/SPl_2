import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderId;

  const PaymentWebviewScreen({
    Key? key,
    required this.paymentUrl,
    required this.orderId,
  }) : super(key: key);

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  InAppWebViewController? _webViewController;
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AamarPay'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.paymentUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              verticalScrollBarEnabled: false,
              horizontalScrollBarEnabled: false,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() => isLoading = true);
              _checkRedirect(url?.toString() ?? '');
            },
            onLoadStop: (controller, url) async {
              setState(() => isLoading = false);
              await _checkRedirect(url?.toString() ?? '');
            },
            onReceivedError: (controller, request, error) {
              setState(() => isLoading = false);
              _showErrorDialog('Payment Error', 'Failed to load page: ${error.description}');
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url?.toString() ?? '';
              if (uri.contains('/payment/success') ||
                  uri.contains('/payment/cancel') ||
                  uri.contains('/payment/failed')) {
                await _handleRedirect(uri);
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00796B)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading payment gateway...',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _checkRedirect(String url) async {
    if (url.contains('/payment/success') ||
        url.contains('/payment/cancel') ||
        url.contains('/payment/failed')) {
      await _handleRedirect(url);
    }
  }

  Future<void> _handleRedirect(String url) async {
    final uri = Uri.parse(url);
    final orderId = uri.queryParameters['order_id'] ?? widget.orderId;
    final status = uri.queryParameters['status'] ?? 'success';

    if (mounted) {
      Navigator.pop(context);
      String routeName;
      switch (status.toLowerCase()) {
        case 'success':
          routeName = '/payment/success';
          break;
        case 'failed':
          routeName = '/payment/failed';
          break;
        case 'cancelled':
        case 'cancel':
          routeName = '/payment/cancel';
          break;
        default:
          routeName = '/payment/failed';
      }

      Navigator.pushReplacementNamed(
        context,
        routeName,
        arguments: {'orderId': orderId},
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
