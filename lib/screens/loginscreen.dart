import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info/package_info.dart';

import 'package:restro_ms_bakery/screens/firstScreen.dart';
import 'package:restro_ms_bakery/screens/homescreen.dart';
import '../models/login.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:connectivity/connectivity.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key, required this.title, this.urls}) : super(key: key);

  final String title;
  final urls;
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;
  TextEditingController email = TextEditingController();
  String versionName = '';
  String? restaurentName;
  bool isbool = true;
  bool? response;
  final primaryColor = const Color(0xFFcc471b);

  var urls;
  var userData;
  var data = Login();
  checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = prefs.getBool('isLogin');
    try {
      var baseUrl = prefs.getString('baseUrl');
      final checkurl = Uri.parse("$baseUrl/api/daySettings/checkDayStatus");
      final res = await http.get(checkurl);
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            response = true;
          });
        }
      }
    } on SocketException {
      setState(() {
        response = false;
      });
    }
    if (data == true && response == true) {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (BuildContext context) {
        return HomeScreen();
      }));
    }
  }

  TextEditingController password = TextEditingController();

  internetChecker() async {
    SharedPreferences sharedPrefe = await SharedPreferences.getInstance();
    var name = sharedPrefe.getString('restaurentName');
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      LoginScreen(title: name!);
    } else {
      _showDialog(
          "No Internet Connection", "Check your internet and try again?");
    }
  }

// save userdata to localstorage
  addUserToLocalStorage(data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLogin', true);
    prefs.setString('floorId', data['floor_id']);

    prefs.setString('user', json.encode(data));
  }

  Future<bool> createUser({Map<String, dynamic>? body}) async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var baseUrl = prefs.getString('baseUrl');
    var logUrl = Uri.parse('$baseUrl/api/auth/login');
    try {
      final response = await http.post(logUrl, body: body);

      var jsonData = json.decode(response.body);
      if (response.statusCode != 401) {
        setState(() {
          isLoading = false;
          userData = jsonData['userInfo'];
          data = Login(
              id: userData['id'],
              username: userData['username'],
              email: userData['email'],
              storeId: userData['store_id'],
              displayName: userData['display_name']);
          addUserToLocalStorage(userData);
          prefs.setString('userid', userData['id']);
        });
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (BuildContext context) {
          return const FirstScreen();
        }));
        return true;
      } else {
        Fluttertoast.showToast(
            msg: "Credentials doesnot matched!",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            textColor: Colors.white,
            backgroundColor: Colors.red);
        setState(() {
          isLoading = false;
        });
        return false;
      }
    } on SocketException {
      Fluttertoast.showToast(
          msg: "System is Offline",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          textColor: Colors.white,
          backgroundColor: Colors.red);
      setState(() {
        isLoading = false;
      });
      return false;
    }
  }

  getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      versionName = packageInfo.version;
    });
  }

  @override
  void initState() {
    super.initState();
    internetChecker();
    checkLogin();
    getVersion();
  }

  TextStyle style = const TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);

  Future<bool?> _alert() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Do you really want to exit app ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
// Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return WillPopScope(
      onWillPop: (() => _alert().then((value) => value!)),
      child: GestureDetector(
        child: Scaffold(
            backgroundColor: const Color(0xFFcc471b),
            body: ListView(
              children: <Widget>[
                Container(
                  height: 577.0,
                  width: 100.0,
                  color: Colors.white,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        36.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              children: [
                                Container(
                                  height: 20.0,
                                  width: 20.0,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color: response == true
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(response == true ? 'Online' : 'Offline',
                                    style: const TextStyle(fontSize: 15)),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 45.0,
                            child: Image.asset(
                              "assets/logo.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                          Text(
                            widget.title.toString(),
                            style: const TextStyle(
                              fontSize: 35,
                              color: Color(0xFFcc471b),
                            ),
                          ),
                          const SizedBox(height: 30.0),
                          SizedBox(
                              width: 400,
                              child: TextFormField(
                                controller: email,
                                obscureText: false,
                                style: style,
                                decoration: InputDecoration(
                                    labelText: "Email",
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        20.0, 15.0, 20.0, 15.0),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(32.0))),
                              )),
                          const SizedBox(height: 25.0),
                          SizedBox(
                            width: 400,
                            child: TextFormField(
                              controller: password,
                              obscureText: true,
                              style: style,
                              decoration: InputDecoration(
                                  labelText: "Password",
                                  contentPadding: const EdgeInsets.fromLTRB(
                                      20.0, 15.0, 20.0, 15.0),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(32.0))),
                            ),
                          ),
                          const SizedBox(
                            height: 35.0,
                          ),
                          response == true
                              ? Material(
                                  elevation: 5.0,
                                  borderRadius: BorderRadius.circular(30.0),
                                  color: const Color(0xFFcc471b),
                                  child: SizedBox(
                                    width: 200,
                                    child: MaterialButton(
                                      padding: const EdgeInsets.fromLTRB(
                                          20.0, 15.0, 20.0, 15.0),
                                      onPressed: () async {
                                        FocusScope.of(context)
                                            .requestFocus(FocusNode());
                                        if (email.text.isEmpty ||
                                            password.text.isEmpty) {
                                          Fluttertoast.showToast(
                                              msg: "Credentials must required",
                                              toastLength: Toast.LENGTH_LONG,
                                              gravity: ToastGravity.CENTER,
                                              textColor: Colors.white,
                                              backgroundColor: Colors.red);
                                        } else {
                                          Login newUser = Login(
                                              email: email.text,
                                              password: password.text);

                                          await createUser(
                                              body: newUser.toMap()
                                                  as Map<String, dynamic>?);
                                        }
                                      },
                                      child: !isLoading? Text("Login",
                                          textAlign: TextAlign.center,
                                          style: style.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)) : const CircularProgressIndicator(color: Colors.white,),
                                    ),
                                  ),
                                )
                              : const Text(''),
                          const SizedBox(
                            height: 30.0,
                          ),
                          const SizedBox(
                            height: 25.0,
                            child: Text(
                              "Powered By: NCT Pvt. Ltd",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFcc471b),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(
                            child: Text(
                              "नेपालमा बनेकाे",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFcc471b),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          SizedBox(
                            child: Text(
                              "v" + versionName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFcc471b),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }

  _showDialog(title, text) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Text(text),
            actions: <Widget>[
              TextButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }
}
