// ignore_for_file: use_key_in_widget_constructors

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro_ms_bakery/controller/billController.dart';
import 'package:restro_ms_bakery/controller/dayCloseAmount.dart';
import 'package:restro_ms_bakery/controller/initPrinter.dart';
import 'package:restro_ms_bakery/controller/urlController.dart';
import 'package:restro_ms_bakery/screens/firstScreen.dart';

import 'package:restro_ms_bakery/screens/loginscreen.dart';
import 'package:flutter/services.dart';
import 'package:restro_ms_bakery/screens/setUrl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controller/CartController.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  runApp(RestartWidget(child: MyApp()));
}

class RestartWidget extends StatefulWidget {
  const RestartWidget({this.child});
  final Widget? child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()!.restartApp();
  }

  @override
  _RestartWidgetState createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: widget.child!,
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var check = 0;
  bool isFirst = false;
  @override
  void initState() {
    getCheck();
    super.initState();
  }

  getCheck() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var isFirsts = prefs.getBool('isFirstTime') ?? true;
    setState(() {
      isFirst = isFirsts;
    });
  }

  // getPrinterIpAddress() async {
  //   var reponseUrl =  "/api/counters/printer/36"
  // }
  @override
  Widget build(BuildContext context) {
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AmountFlow()),
        ChangeNotifierProvider(create: (context) => UrlController()),
        ChangeNotifierProvider(create: (context) => CartController()),
        ChangeNotifierProvider(create: (context) => BillController()),
        ChangeNotifierProvider(
            create: (context) => PrinterIpAddressController()),
      ],
      child: MaterialApp(
          title: "RestroMS",
          debugShowCheckedModeBanner: false,
          home: !isFirst ? const NextPage() : const SetUrlPage()),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class NextPage extends StatefulWidget {
  const NextPage({Key? key}) : super(key: key);

  @override
  State<NextPage> createState() => _NextPageState();
}

class _NextPageState extends State<NextPage> {
  var check = 0;
  var name;
  @override
  void initState() {
    getCheck();
    super.initState();
  }

  getCheck() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var data = prefs.getBool('isLogin') ?? false;
     var nameR = prefs.getString('restaurentName');
    setState(() {
      check = !data ? 1 : 2;
      name = nameR;
    });
  }

  @override
  Widget build(BuildContext context) {
    return check == 2
        ? const FirstScreen()
        : check == 1
            ? LoginScreen(title: name,)
            : const Scaffold(
                body: null,
              );
  }
}
