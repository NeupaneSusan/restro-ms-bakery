import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:restro_ms_bakery/controller/dayCloseAmount.dart';
import 'package:restro_ms_bakery/controller/printController.dart';
import 'package:restro_ms_bakery/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class DayClosePage extends StatefulWidget {
  const DayClosePage({Key? key}) : super(key: key);

  @override
  _DayClosePageState createState() => _DayClosePageState();
}

class _DayClosePageState extends State<DayClosePage> {
  dayClose() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cashFlow = Provider.of<AmountFlow>(context, listen: false);

    var baseUrl = prefs.getString('baseUrl');
    var userId = prefs.getString('userid');
print(baseUrl);
    Fluttertoast.showToast(msg: 'Requesting DayClose');
    Map<String, String> header = {
      'Content-type': 'application/json',
    };
    var bodys = {'user_id': userId};
    var dayCloseReportUrl =
        Uri.parse("$baseUrl/api/daySettings/closeDay/$userId");
    var dayCloseUrl = Uri.parse("$baseUrl/api/daySettings/finalCloseDay");
    var response = await http.post(dayCloseReportUrl, headers: header);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['data'];
      Fluttertoast.showToast(
          msg: 'Requesting the Printer', toastLength: Toast.LENGTH_LONG);
      var check = await printDayClosing(data, context);
      if (check) {
        Fluttertoast.showToast(
            msg: 'Printing the bill', toastLength: Toast.LENGTH_LONG);
        var responses = await http.post(dayCloseUrl,
            headers: header, body: jsonEncode(bodys));
        if (responses.statusCode == 200) {
          Fluttertoast.showToast(
              msg: 'Successfully Day Close', toastLength: Toast.LENGTH_LONG);
          prefs.remove('isLogin');
          prefs.remove('userid');
          prefs.remove('user');
      
          cashFlow.clearAll();
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => MyApp()),
              (Route<dynamic> route) => false);
        } else {
          Fluttertoast.showToast(
              msg: 'Unable to Close Day', toastLength: Toast.LENGTH_LONG);
        }
      } else {
        Fluttertoast.showToast(
            msg: 'Unable to Connected Printer', toastLength: Toast.LENGTH_LONG);
      }
    } else if (response.statusCode == 503) {
      var message = jsonDecode(response.body)['message'];
      Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_LONG);
    } else {
      Fluttertoast.showToast(
          msg: 'Unable to Connected', toastLength: Toast.LENGTH_LONG);
    }
  }

  confirmDayCloseDay() async {
    try {
      final cashFlow = Provider.of<AmountFlow>(context, listen: false);
      cashFlow.isLoading = true;
      SharedPreferences prefs = await SharedPreferences.getInstance();

      var baseUrl = prefs.getString('baseUrl');
      var userId = prefs.getString('userid');

      var cashCountUrl = Uri.parse('$baseUrl/api/cashCount/$userId');

      Map<String, String> header = {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      };
      var body = {
        "thousand": cashFlow.thousandsAmount / 1000,
        "five_hundred": cashFlow.fiveHundredAmount / 500,
        "hundred": cashFlow.hundredAmount / 100,
        "fifty": cashFlow.fiftyAmount / 50,
        "twenty": cashFlow.twentyAmount / 20,
        "ten": cashFlow.tenAmount / 10,
        "five": cashFlow.fiveAmount / 5,
        "two": cashFlow.twoAmount / 2,
        "one": cashFlow.oneAmount,
        "ic_amount": cashFlow.icAmount,
        "fonepay_amount": cashFlow.fonepayAmount,
        "card_amount": cashFlow.cardAmount,
        "total_cash_amount": cashFlow.totalCashAmount,
        "total_amount": cashFlow.totalAmount
      };
      bool isAvailablePrint = await checkPrint(context);
      if (isAvailablePrint) {
        var response = await http.post(cashCountUrl,
            body: jsonEncode(body), headers: header);
        if (response.statusCode == 200) {
          dayClose();
        } else {
          var message = jsonDecode(response.body)['message'];
          showMessage(message);
        }
        // print(response.statusCode);
      } else {
        showMessage('Printer isNot Available');
      }
      cashFlow.isLoading = false;
    } catch (error) {
      showMessage('No');
    }
  }

  void showMessage(msg) {
    Fluttertoast.showToast(msg: msg, toastLength: Toast.LENGTH_LONG);
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Consumer<AmountFlow>(builder: (context, amountFlow, child) {
      return WillPopScope(
        onWillPop: !amountFlow.isLoading
            ? () async {
                amountFlow.clearAll();
                return true;
              }
            : () async {
                return false;
              },
        child: Dialog(
          child: SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Are You Sure,you want to close the Day?',
                    style: TextStyle(fontSize: 18.0, color: Colors.redAccent),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: const Center(
                                            child: Text(
                                              '1000',
                                              style: TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                                color: Colors
                                                    .blueGrey, // set border color
                                                width: 1.0), // set border width
                                            borderRadius: const BorderRadius
                                                    .all(
                                                Radius.circular(
                                                    1.0)), // set rounded corner radius
                                          ),
                                          child: TextFormField(
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                if (value.isNotEmpty) {
                                                  var a = double.parse(value);
                                                  amountFlow.setAmount(
                                                      1000, a * 1000);
                                                } else {
                                                  amountFlow.setAmount(1000, 0);
                                                }
                                              },
                                              decoration: const InputDecoration(
                                                  hintText: '0',
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          left: 15.0,
                                                          bottom: 10.0),
                                                  border: InputBorder.none)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: Center(
                                            child: Text(
                                              'Rs.${amountFlow.thousandsAmount}',
                                              style: const TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                Flexible(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: const Center(
                                            child: Text(
                                              '500',
                                              style: TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                                color: Colors
                                                    .blueGrey, // set border color
                                                width: 1.0), // set border width
                                            borderRadius: const BorderRadius
                                                    .all(
                                                Radius.circular(
                                                    1.0)), // set rounded corner radius
                                          ),
                                          child: TextFormField(
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                if (value.isNotEmpty) {
                                                  var a = double.parse(value);
                                                  amountFlow.setAmount(
                                                      500, a * 500);
                                                } else {
                                                  amountFlow.setAmount(500, 0);
                                                }
                                              },
                                              decoration: const InputDecoration(
                                                  hintText: '0',
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          left: 15.0,
                                                          bottom: 10.0),
                                                  border: InputBorder.none)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: Center(
                                            child: Text(
                                              'Rs.${amountFlow.fiveHundredAmount}',
                                              style: const TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: const Center(
                                            child: Text(
                                              '100',
                                              style: TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                                color: Colors
                                                    .blueGrey, // set border color
                                                width: 1.0), // set border width
                                            borderRadius: const BorderRadius
                                                    .all(
                                                Radius.circular(
                                                    1.0)), // set rounded corner radius
                                          ),
                                          child: TextFormField(
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                if (value.isNotEmpty) {
                                                  var a = double.parse(value);
                                                  amountFlow.setAmount(
                                                      100, a * 100);
                                                } else {
                                                  amountFlow.setAmount(100, 0);
                                                }
                                              },
                                              decoration: const InputDecoration(
                                                  hintText: '0',
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          left: 15.0,
                                                          bottom: 10.0),
                                                  border: InputBorder.none)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: Center(
                                            child: Text(
                                              'Rs.${amountFlow.hundredAmount}',
                                              style: const TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Flexible(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: const Center(
                                            child: Text(
                                              '50',
                                              style: TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                                color: Colors
                                                    .blueGrey, // set border color
                                                width: 1.0), // set border width
                                            borderRadius: const BorderRadius
                                                    .all(
                                                Radius.circular(
                                                    1.0)), // set rounded corner radius
                                          ),
                                          child: TextFormField(
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                if (value.isNotEmpty) {
                                                  var a = double.parse(value);
                                                  amountFlow.setAmount(
                                                      50, a * 50);
                                                } else {
                                                  amountFlow.setAmount(50, 0);
                                                }
                                              },
                                              decoration: const InputDecoration(
                                                  hintText: '0',
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          left: 15.0,
                                                          bottom: 10.0),
                                                  border: InputBorder.none)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: Center(
                                            child: Text(
                                              'Rs.${amountFlow.fiftyAmount}',
                                              style: const TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 7.0),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: const Center(
                                            child: Text(
                                              '20',
                                              style: TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                                color: Colors
                                                    .blueGrey, // set border color
                                                width: 1.0), // set border width
                                            borderRadius: const BorderRadius
                                                    .all(
                                                Radius.circular(
                                                    1.0)), // set rounded corner radius
                                          ),
                                          child: TextFormField(
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                if (value.isNotEmpty) {
                                                  var a = double.parse(value);
                                                  amountFlow.setAmount(
                                                      20, a * 20);
                                                } else {
                                                  amountFlow.setAmount(20, 0);
                                                }
                                              },
                                              decoration: const InputDecoration(
                                                  hintText: '0',
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          left: 15.0,
                                                          bottom: 10.0),
                                                  border: InputBorder.none)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: Center(
                                            child: Text(
                                              'Rs.${amountFlow.twentyAmount}',
                                              style: const TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Flexible(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: const Center(
                                            child: Text(
                                              '10',
                                              style: TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                                color: Colors
                                                    .blueGrey, // set border color
                                                width: 1.0), // set border width
                                            borderRadius: const BorderRadius
                                                    .all(
                                                Radius.circular(
                                                    1.0)), // set rounded corner radius
                                          ),
                                          child: TextFormField(
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                if (value.isNotEmpty) {
                                                  var a = double.parse(value);
                                                  amountFlow.setAmount(
                                                      10, a * 10);
                                                } else {
                                                  amountFlow.setAmount(10, 0);
                                                }
                                              },
                                              decoration: const InputDecoration(
                                                  hintText: '0',
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          left: 15.0,
                                                          bottom: 10.0),
                                                  border: InputBorder.none)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: Center(
                                            child: Text(
                                              'Rs.${amountFlow.tenAmount}',
                                              style: const TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 7.0),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: const Center(
                                            child: Text(
                                              '5',
                                              style: TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                                color: Colors
                                                    .blueGrey, // set border color
                                                width: 1.0), // set border width
                                            borderRadius: const BorderRadius
                                                    .all(
                                                Radius.circular(
                                                    1.0)), // set rounded corner radius
                                          ),
                                          child: TextFormField(
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                if (value.isNotEmpty) {
                                                  var a = double.parse(value);
                                                  amountFlow.setAmount(
                                                      5, a * 5);
                                                } else {
                                                  amountFlow.setAmount(5, 0);
                                                }
                                              },
                                              decoration: const InputDecoration(
                                                  hintText: '0',
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          left: 15.0,
                                                          bottom: 10.0),
                                                  border: InputBorder.none)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: Center(
                                            child: Text(
                                              'Rs.${amountFlow.fiveAmount}',
                                              style: const TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Flexible(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: const Center(
                                            child: Text(
                                              '2',
                                              style: TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                                color: Colors
                                                    .blueGrey, // set border color
                                                width: 1.0), // set border width
                                            borderRadius: const BorderRadius
                                                    .all(
                                                Radius.circular(
                                                    1.0)), // set rounded corner radius
                                          ),
                                          child: TextFormField(
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                if (value.isNotEmpty) {
                                                  var a = double.parse(value);
                                                  amountFlow.setAmount(
                                                      2, a * 2);
                                                } else {
                                                  amountFlow.setAmount(500, 0);
                                                }
                                              },
                                              decoration: const InputDecoration(
                                                  hintText: '0',
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          left: 15.0,
                                                          bottom: 10.0),
                                                  border: InputBorder.none)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: Center(
                                            child: Text(
                                              'Rs.${amountFlow.twoAmount}',
                                              style: const TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 7.0),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: const Center(
                                            child: Text(
                                              '1',
                                              style: TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                                color: Colors
                                                    .blueGrey, // set border color
                                                width: 1.0), // set border width
                                            borderRadius: const BorderRadius
                                                    .all(
                                                Radius.circular(
                                                    1.0)), // set rounded corner radius
                                          ),
                                          child: TextFormField(
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                if (value.isNotEmpty) {
                                                  var a = double.parse(value);
                                                  amountFlow.setAmount(
                                                      1, a * 1);
                                                } else {
                                                  amountFlow.setAmount(1, 0);
                                                }
                                              },
                                              decoration: const InputDecoration(
                                                  hintText: '0',
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          left: 15.0,
                                                          bottom: 10.0),
                                                  border: InputBorder.none)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: Center(
                                            child: Text(
                                              'Rs.${amountFlow.oneAmount}',
                                              style: const TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Flexible(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          color: const Color(0xff008d4c),
                                          child: const Center(
                                            child: Text(
                                              'IC Amount',
                                              style: TextStyle(
                                                  fontSize: 15.0,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                                color: Colors
                                                    .blueGrey, // set border color
                                                width: 1.0), // set border width
                                            borderRadius: const BorderRadius
                                                    .all(
                                                Radius.circular(
                                                    1.0)), // set rounded corner radius
                                          ),
                                          child: TextFormField(
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                if (value.isNotEmpty) {
                                                  var a = double.parse(value);
                                                  amountFlow.setAmount(0, a);
                                                } else {
                                                  amountFlow.setAmount(0, 0);
                                                }
                                              },
                                              decoration: const InputDecoration(
                                                  hintText: '0',
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          left: 15.0,
                                                          bottom: 10.0),
                                                  border: InputBorder.none)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 40.0,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            thickness: 1,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: Row(
                              children: [
                                Flexible(
                                    child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 40.0,
                                        color: const Color(0xffC90A0F),
                                        child: const Center(
                                          child: Text(
                                            'FonePay Amount',
                                            style: TextStyle(
                                                fontSize: 15.0,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 40.0,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                              color: Colors
                                                  .blueGrey, // set border color
                                              width: 1.0), // set border width
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(
                                                  1.0)), // set rounded corner radius
                                        ),
                                        child: TextFormField(
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              if (value.isNotEmpty) {
                                                var a = double.parse(value);
                                                amountFlow.setAmount(3, a);
                                              } else {
                                                amountFlow.setAmount(3, 0);
                                              }
                                            },
                                            decoration: const InputDecoration(
                                                hintText: '0',
                                                contentPadding: EdgeInsets.only(
                                                    left: 15.0, bottom: 10.0),
                                                border: InputBorder.none)),
                                      ),
                                    ),
                                  ],
                                )),
                                const SizedBox(
                                  width: 10,
                                ),
                                Flexible(
                                    child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 40.0,
                                        color: const Color(0xff010101),
                                        child: const Center(
                                          child: Text(
                                            'Card Amount',
                                            style: TextStyle(
                                                fontSize: 15.0,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 40.0,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                              color: Colors
                                                  .blueGrey, // set border color
                                              width: 1.0), // set border width
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(
                                                  1.0)), // set rounded corner radius
                                        ),
                                        child: TextFormField(
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              if (value.isNotEmpty) {
                                                var a = double.parse(value);
                                                amountFlow.setAmount(4, a);
                                              } else {
                                                amountFlow.setAmount(4, 0);
                                              }
                                            },
                                            decoration: const InputDecoration(
                                                hintText: '0',
                                                contentPadding: EdgeInsets.only(
                                                    left: 15.0, bottom: 10.0),
                                                border: InputBorder.none)),
                                      ),
                                    ),
                                  ],
                                ))
                              ],
                            ),
                          ),
                          const Divider(
                            thickness: 1,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: Row(
                              children: [
                                Flexible(
                                    child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 40.0,
                                        color: const Color(0xffCC471B),
                                        child: const Center(
                                          child: Text(
                                            'Total Cash Amount',
                                            style: TextStyle(
                                                fontSize: 15.0,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 40.0,
                                        color: const Color(0xff008d4c),
                                        child: Center(
                                          child: Text(
                                            'Rs.${amountFlow.totalCashAmount}',
                                            style: const TextStyle(
                                                fontSize: 15.0,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                                const SizedBox(
                                  width: 10,
                                ),
                                Flexible(
                                    child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 40.0,
                                        color: const Color(0xffCC471B),
                                        child: const Center(
                                          child: Text(
                                            'Total Amount',
                                            style: TextStyle(
                                                fontSize: 15.0,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 40.0,
                                        color: const Color(0xff008d4c),
                                        child: Center(
                                          child: Text(
                                            'Rs.${amountFlow.totalAmount}',
                                            style: const TextStyle(
                                                fontSize: 15.0,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ))
                              ],
                            ),
                          ),
                          const Divider(
                            thickness: 1,
                          ),
                        
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              const  Flexible(child:Padding(
                                padding: EdgeInsets.only(left:8.0, right: 8.0),
                                child: Text("This will close your today's all transactions. You can cancel it now but after confirm you can't undo it.",style: TextStyle(fontSize: 15.0 ,color: Colors.grey),),
                              )),
                              Container(
                                height: 45.0,
                                width: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  color: const Color(0xff008d4c),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    confirmDayCloseDay();
                                  },
                                  child: !amountFlow.isLoading
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.lock,
                                              color: Colors.white,
                                            ),
                                            Text(
                                              'Confirm Close Day',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        )
                                      : const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
