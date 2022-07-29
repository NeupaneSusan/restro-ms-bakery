// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';

import 'package:restro_ms_bakery/models/Category.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CashOutAddPage extends StatefulWidget {
  const CashOutAddPage({Key? key}) : super(key: key);

  @override
  _CashOutAddPageState createState() => _CashOutAddPageState();
}

class _CashOutAddPageState extends State<CashOutAddPage> {
  var _formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final amount = TextEditingController();
  List cashoutCategory = [];
  var categoryId;
  var selectedValue;
  bool error = false;

  bool isLoading = false;
  Future<List> availablefetchTables() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
      var baseUrl = prefs.getString('baseUrl');
    var cashoutCategoryUrl = Uri.parse('$baseUrl/api/cashOuts/categories');
    var res = await http.get(cashoutCategoryUrl);
    if (res.statusCode == 200) {
      var jsonData = jsonDecode(res.body);
      cashoutCategory = [];
      for (var data in jsonData['data']) {
        cashoutCategory.add(Category.fromJson(data));
      }
      return cashoutCategory;
    } else {
      throw "Can't get tables.";
    }
  }

  cashOut() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();
    
      var baseUrl = preferences.getString('baseUrl');
    var userid = preferences.get('userid');
     
    var tableSwipeUrl = Uri.parse('$baseUrl/api/cashOuts/$userid');
    Map<String, String> header = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    var body = {
      "cashout_category_id": categoryId,
      "title": title.text,
      "amount": amount.text
    };

     var response = await http.post(tableSwipeUrl,headers: header,body: jsonEncode(body));
     if(response.statusCode==200){
       Navigator.pop(context);
       Fluttertoast.showToast(msg: 'Cash Out Created Successfully');

     }
     else if( response.statusCode==500){
       Navigator.pop(context);
       Fluttertoast.showToast(msg: 'Day is already closed');
     }
     else{
       throw '${response.body}';
     }
     setState(() {
       isLoading = false;
     });
    
  }

  clearAll() {
    setState(() {
      selectedValue = null;
      categoryId = null;
    });
    title.clear();
    amount.clear();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        print(!isLoading);
        return !isLoading;
      },
      child: Dialog(
        child: SizedBox(
          height: 380,
          width: 500,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
             
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cash Out',
                      style: TextStyle(
                          fontSize: 20.0,
                          color: Color(0xfffcc471b),
                          fontWeight: FontWeight.w500),
                    ),
                    const Divider(
                      thickness: 1.5,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    FutureBuilder(
                      future: availablefetchTables(),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        return snapshot.hasData
                            ? Container(
                                height: 45,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    border: Border.all(
                                      color:
                                          !error ? Colors.blueGrey : Colors.red,
                                    )),
                                child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: DropdownButton<dynamic>(
                                      isExpanded: true,
                                      isDense: true,
                                      underline: const SizedBox(),
                                      hint: Text(selectedValue ??
                                          'Select Cashout Category'),
                                      items: snapshot.data
                                          .map<DropdownMenuItem<dynamic>>(
                                              (item) {
                                        return DropdownMenuItem<dynamic>(
                                          value: item,
                                          child: Text(item.name),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedValue = value.name.toString();
                                          categoryId = value.id;
                                        });
                                      },
                                    )),
                              )
                            : Container(
                                height: 40,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: const [
                                      Text('Select Cashout Category')
                                    ],
                                  ),
                                ));
                      },
                    ),
                    if (!error)
                      const SizedBox.shrink()
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Selected Cashout Category',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                        keyboardType: TextInputType.text,
                        controller: title,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Enter title';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Title',
                          contentPadding: const EdgeInsets.only(
                            bottom: 10.0,
                            left: 8,
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0)),
                        )),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                        controller: amount,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Enter amount';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Amount',
                          contentPadding: const EdgeInsets.only(
                            bottom: 10.0,
                            left: 8,
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0)),
                        )),
                    
                    
                    
                    const SizedBox(
                      height: 20,
                    ),
                    const Divider(
                      thickness: 1.5,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 120,
                              height: 40,
                              child: ElevatedButton(
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.restart_alt),
                                      Text('Reset')
                                    ]),
                                style: ElevatedButton.styleFrom(
                                  primary: const Color(0xffCC471B),
                                ),
                                onPressed: () {
                                  if (!isLoading) {
                                    clearAll();
                                  }
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 120,
                              height: 40,
                              child: ElevatedButton(
                                child: !isLoading
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                            Icon(Icons.confirmation_num_sharp),
                                            Text('Confirm')
                                          ])
                                    : const CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.green,
                                ),
                                onPressed: !isLoading
                                    ? () {
                                        if (categoryId == null) {
                                          setState(() {
                                            error = true;
                                          });
                                        } else {
                                          setState(() {
                                            error = false;
                                          });
                                          if (_formKey.currentState!
                                              .validate()) {
                                            FocusScope.of(context)
                                                .requestFocus(FocusNode());
                                            cashOut();
                                          }
                                        }
                                      }
                                    : () {},
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
