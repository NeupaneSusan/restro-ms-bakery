import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;


import 'package:restro_ms_bakery/screens/loginscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetUrlPage extends StatefulWidget {
  const SetUrlPage({Key? key}) : super(key: key);

  @override
  _SetUrlPageState createState() => _SetUrlPageState();
}

class _SetUrlPageState extends State<SetUrlPage> {
  final TextEditingController _fieldOne = TextEditingController();
  final TextEditingController _fieldTwo = TextEditingController();
  final TextEditingController _fieldThree = TextEditingController();
  final TextEditingController _fieldFour = TextEditingController();
  final TextEditingController _fieldFive = TextEditingController();
  final TextEditingController _fieldSix = TextEditingController();
  final TextEditingController _fieldSeven = TextEditingController();
  final TextEditingController _fieldEight = TextEditingController();
  final TextEditingController _fieldNine = TextEditingController();

  bool isLoading = false;

  getUrl() async {
    var url = Uri.parse(
        'https://server-restroms.nctbutwal.com/api/v1/restaurant/verify/pan-vat-no');
    var panVatNo = _fieldOne.text +
        _fieldTwo.text +
        _fieldThree.text +
        _fieldFour.text +
        _fieldFive.text +
        _fieldSix.text +
        _fieldSeven.text +
        _fieldEight.text +
        _fieldNine.text;
    var body = {"pan_vat_no": panVatNo};
    Map<String, String> header = {
      'Accept': 'application/json',
    };
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var response = await http.post(url, body: body, headers: header);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['data'];
        prefs.setString('baseUrl', data[0]['base_url']);
        prefs.setString('restaurentName', data[0]['restaurant_name']);
        prefs.setBool('isFirstTime', false);
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (BuildContext context) {
          return LoginScreen(
            title: data[0]['restaurant_name'],
          );
        }));
      } else if (response.statusCode == 204) {
        Fluttertoast.showToast(
            msg: 'Please register your System',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            textColor: Colors.white,
            backgroundColor: Colors.red);
      } else {
        var msg = jsonDecode(response.body)['message'];
        Fluttertoast.showToast(
            msg: msg,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            textColor: Colors.white,
            backgroundColor: Colors.red);
      }
      print(response.statusCode);
      print(response.body);
      setState(() {
        isLoading = false;
      });
    } catch (error) {
      print(error);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Enter Your Pin Number',
                style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xffCC471B))),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 25.0, horizontal: 80),
              child: Row(
                children: [
                  OtpInput(_fieldOne, false, 1, isLoading),
                  OtpInput(_fieldTwo, false, 2, isLoading),
                  OtpInput(_fieldThree, false, 3, isLoading),
                  OtpInput(_fieldFour, false, 4, isLoading),
                  OtpInput(_fieldFive, false, 5, isLoading),
                  OtpInput(_fieldSix, false, 6, isLoading),
                  OtpInput(_fieldSeven, false, 7, isLoading),
                  OtpInput(_fieldEight, false, 8, isLoading),
                  OtpInput(_fieldNine, false, 9, isLoading)
                ],
              ),
            ),
            const SizedBox(
              height: 50.0,
            ),
            SizedBox(
              width: 180.0,
              height: 45.0,
              child: ElevatedButton(
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [Text('Submit')]),
                style: ElevatedButton.styleFrom(
                  primary: const Color(0xffCC471B),
                ),
                onPressed: () {
                  if (_fieldOne.text.isNotEmpty &&
                      _fieldTwo.text.isNotEmpty &&
                      _fieldThree.text.isNotEmpty &&
                      _fieldFour.text.isNotEmpty &&
                      _fieldFive.text.isNotEmpty &&
                      _fieldSix.text.isNotEmpty &&
                      _fieldSeven.text.isNotEmpty &&
                      _fieldEight.text.isNotEmpty &&
                      _fieldNine.text.isNotEmpty) {
                    if (!isLoading) {
                      setState(() {
                        isLoading = true;
                      });
                      getUrl();
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final bool autoFocus;
  final int index;
  final bool isLoading;
  const OtpInput(this.controller, this.autoFocus, this.index, this.isLoading,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 15.0, top: 30.0, left: 15),
        child: SizedBox(
          height: 60,
          width: 55,
          child: TextField(
            autofocus: autoFocus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            controller: controller,
            maxLength: 1,
            readOnly: isLoading,
            cursorColor: Theme.of(context).primaryColor,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                counterText: '',
                hintStyle: TextStyle(color: Colors.black, fontSize: 20.0)),
            onChanged: (value) {
              if (value.length == 1) {
                if (index != 9) {
                  FocusScope.of(context).nextFocus();
                } else if (index == 9) {
                  FocusScope.of(context).unfocus();
                }
              }
              if (value.isEmpty) {
                if (index != 1) {
                  FocusScope.of(context).previousFocus();
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
