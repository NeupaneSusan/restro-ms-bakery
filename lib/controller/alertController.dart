import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class DayOpenPage extends StatefulWidget {
  const DayOpenPage({Key? key}) : super(key: key);

  @override
  _DayOpenPageState createState() => _DayOpenPageState();
}

class _DayOpenPageState extends State<DayOpenPage> {
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _openingbalance = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Form(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Start Your Day'),
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: TextFormField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
              controller: _openingbalance,
              onChanged: (String value) {
                var m;
                if (value.isEmpty || value.trim().length < 0) {
                  m = 'Enter Opening Balance';
                  return m;
                }
                return null;
              },
              validator: (String? value) {
                if (value!.isEmpty || value.trim().length < 0) {
                  return 'Enter Opening Balance';
                }
                return null;
              },
              decoration: const InputDecoration(
                  hintText: 'Enter Opening Balance',
                  contentPadding: EdgeInsets.only(top: 10),
                  floatingLabelBehavior: FloatingLabelBehavior.always),
            ),
          ),
        ],
      )),
      actions: <Widget>[
        ElevatedButton(
          child: !isLoading
              ? const Text("Get Started")
              : const CircularProgressIndicator(
                  color: Colors.white,
                ),
          style: ElevatedButton.styleFrom(
            primary: Colors.redAccent,
          ),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              FocusScope.of(context).requestFocus(FocusNode());
              setState(() {
                isLoading = true;
              });
              var result = await enterOpen(_openingbalance.text);

              if (result == 200) {
                Fluttertoast.showToast(
                    msg: 'Successfully Open Day',
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.orangeAccent);
                Navigator.of(context).pop();
              } else {
                Fluttertoast.showToast(
                    msg: 'Please try again',
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.redAccent);

                Navigator.of(context).pop();
              }
              setState(() {
                isLoading = true;
              });
            }
          },
        ),
      ],
    );
  }

  Future<int> enterOpen(_openingbalance) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var baseUrl = prefs.getString('baseUrl');

    var userId = prefs.getString('userid');
    var url = Uri.parse('$baseUrl/api/daySettings/startDay/$userId');
    Map<String, String> header = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    var data = {
      "opening_balance": _openingbalance,
    };
    var body = jsonEncode(data);
    var response = await http.post(url, headers: header, body: body);

    return response.statusCode;
  }
}
