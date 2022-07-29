import 'dart:convert';

import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';


import 'package:restro_ms_bakery/controller/initPrinter.dart';
import 'package:restro_ms_bakery/controller/urlController.dart';
import 'package:restro_ms_bakery/screens/orderscreen.dart';
import 'package:restro_ms_bakery/screens/paidorders.dart';
import 'package:restro_ms_bakery/screens/pos.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var userData;
// get userdata from localstorage
  getUserFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userData = json.decode(prefs.getString('user')!);
    });
  }

  int _selectedIndex = 0;
  PageController? _pageController;
  // ignore: unused_element
  Future<bool?> _alert() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Do you really want to exit app ?'),
          actions: <Widget>[
            // ignore: deprecated_member_use
            FlatButton(
              child: Text('No'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            // ignore: deprecated_member_use
            FlatButton(
              child: Text('Yes'),
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
  void initState() {
    getCompanyInfo();
    super.initState();
    _pageController = PageController();
    getUserFromLocalStorage();
  }

  getCompanyInfo() async {
    try {
     SharedPreferences prefs = await SharedPreferences.getInstance();
      var baseUrl = prefs.getString('baseUrl');
      final companyInfo =
          Provider.of<PrinterIpAddressController>(context, listen: false);
      var infoUrl = Uri.parse("$baseUrl/api/company/info");
     
      var response = await http.get(infoUrl);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['data'];
        companyInfo.setCompanyProfile(data);
      } else {
        Fluttertoast.showToast(msg: 'Unable TO FIND Printer');
      }
    } catch (erro) {
      Fluttertoast.showToast(
          msg: 'No internet', toastLength: Toast.LENGTH_LONG);
    }
  }

  @override
  void dispose() {
    _pageController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urlController = Provider.of<UrlController>(context, listen: false);
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SizedBox.expand(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _selectedIndex = index);
              },
              children: <Widget>[
                PosPage(data: userData),
                OrderScreen(data: userData),
                PaidOrders(data: userData),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavyBar(
            selectedIndex: _selectedIndex,
            showElevation: true, // use this to remove appBar's elevation
            onItemSelected: (index) => setState(() {
              _selectedIndex = index;
              _pageController!.animateToPage(index,
                  duration: Duration(milliseconds: 300), curve: Curves.ease);
            }),
            items: [
              BottomNavyBarItem(
                icon: Icon(Icons.apps),
                title: Text('POS'),
                activeColor: Colors.red,
              ),
              BottomNavyBarItem(
                  icon: Icon(Icons.table_chart),
                  title: Text(
                    urlController.getUrlValue == 0
                        ? 'Running Tables' 
                        : urlController.getUrlValue==1 ? 'Running Take Aways' : 'Running HD',
                    style: TextStyle(fontSize: 11),
                  ),
                  activeColor: Colors.red),
              BottomNavyBarItem(
                  icon: Icon(Icons.attach_money),
                  title: Text('Paid'),
                  activeColor: Colors.green),
            ],
          )),
    );
  }
}
