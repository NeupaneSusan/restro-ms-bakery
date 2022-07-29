// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class FonepayPage extends StatefulWidget {
//   final String? orderID;
//   final String? userID;
//   FonepayPage({
//     this.orderID,
//     this.userID,
//   });
//   @override
//   _FonepayPageState createState() => _FonepayPageState();
// }

// class _FonepayPageState extends State<FonepayPage> {
//   final _key = UniqueKey();
//   final Completer<WebViewController> _controller =
//       Completer<WebViewController>();
//   @override
//   Widget build(BuildContext context) {
//     print(widget.orderID);
//     return Scaffold(
//         appBar: AppBar(
//           title: Text('Fone Pay'),
//           backgroundColor: Color(0xFFcc471b),
//         ),
//         body: Column(
//           children: [
//             Expanded(
//               child: WebView(
//                   key: _key,
//                   javascriptMode: JavascriptMode.unrestricted,
//                   onWebViewCreated: (WebViewController webViewController) {
//                     _controller.complete(webViewController);
//                   },
//                   initialUrl:
//                       'http://192.168.1.1/restroms/appfonepay/payment/' +
//                           widget.userID! +
//                           '/' +
//                           widget.orderID!,
//                   onProgress: (int progress) {
//                     print("WebView is loading (progress : $progress%)");
//                   },
//                   onPageStarted: (String url) {
//                     print('Page started loading: $url');
//                   },
//                   onPageFinished: (String url) {
//                     print('Page finished loading: $url');
//                     print(widget.orderID);
//                   }),
//             )
//           ],
//         ));
//   }
// }
