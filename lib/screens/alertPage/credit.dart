import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';

import 'package:http/http.dart' as http;
import 'package:restro_ms_bakery/controller/printController.dart';
import 'package:restro_ms_bakery/models/customer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreditPage extends StatefulWidget {
  final int urlController;
  final dynamic orderId;
  final dynamic tableId;
  const CreditPage(
      {Key? key,
      required this.urlController,
      this.tableId,
      required this.orderId})
      : super(key: key);

  @override
  _CreditPageState createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  final _formKey = GlobalKey<FormState>();
  final customerNameForm = TextEditingController();
  final customerMobileForm = TextEditingController();
  final customerAddressForm = TextEditingController();
  var customerName;
  var customerId;
  double height = 180;

  int _groupValue = 1;
  bool isLoading = false;
  List<Customer> customerList = [];
  Future<Iterable<Customer>> fetchCustomer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var baseUrl = prefs.getString('baseUrl');
    var unpaidtableUrl = Uri.parse('$baseUrl/api/customers');

    var res = await http.get(unpaidtableUrl);

    if (res.statusCode == 200) {
      var jsonData = jsonDecode(res.body);

      customerList = [];
      for (var data in jsonData['data']) {
        customerList.add(Customer.fromJson(data));
      }

      return customerList.reversed;
    } else {
      Navigator.pop(context);
      toast("can't load data", Colors.red);
      throw "Can't get data.";
    }
  }

  creditSettle() async {
    setState(() {
      isLoading = true;
    });
    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();

      var baseUrl = preferences.getString('baseUrl');
      var userId = preferences.get('userid');

      Map<String, String> header = {
        'Accept': 'application/json',
      };
      var body = widget.urlController == 0
          ? {"customer_id": customerId, "table_id": widget.tableId}
          : {"customer_id": customerId};

      var creditSettleUrl = widget.urlController == 0
          ? "$baseUrl/api/tableOrders/settleCredit/$userId/${widget.orderId}"
          : "$baseUrl/api/twOrders/settleCredit/$userId/${widget.orderId}";
      var response = await http.post(Uri.parse(creditSettleUrl),
          body: body, headers: header);

      if (response.statusCode == 200) {
        toast('Requesting Printer', Colors.blueGrey);
        var data = jsonDecode(response.body)['data'];

        var check = await printerCredit(data, widget.urlController, context);
        if (check) {
          Navigator.of(context).pop(true);
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pop(true);
          Navigator.of(context).pop(true);
          toast('Unable to Print', Colors.green);
        }
      } else {
        var message = jsonDecode(response.body)['message'];
        toast(message, Colors.green);
        Navigator.of(context).pop(true);
        Navigator.of(context).pop(true);
      }
      setState(() {
        isLoading = false;
      });
    }
    // ignore: empty_catches
    catch (error) {
      toast('Unable to Settled', Colors.red);
      setState(() {
        isLoading = false;
      });
    }
  }

  void toast(message, color) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        textColor: Colors.white,
        backgroundColor: color);
  }

  registerCustomer() async {
    Map<String, String> header = {
      'Accept': 'application/json',
    };
    var body = {
      "name": customerNameForm.text,
      "mobile_no": customerMobileForm.text,
      "address": customerAddressForm.text,
      "gender": _groupValue == 1 ? "male" : "female"
    };
   SharedPreferences prefs = await SharedPreferences.getInstance();
      var baseUrl = prefs.getString('baseUrl');
    var registerCustomerUrl = Uri.parse('$baseUrl/api/customers/register');
    var respone =
        await http.post(registerCustomerUrl, body: body, headers: header);
    if (respone.statusCode == 200) {
      toast('Successfully add Customer', Colors.greenAccent);
      fetchCustomer();
      toast('Loading the data with for a second', Colors.greenAccent);
      _formKey.currentState!.reset();
      customerAddressForm.clear();
      customerNameForm.clear();
      customerMobileForm.clear();
    } else {
      toast('Uable add Customer', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: !isLoading
          ? () async {
              return true;
            }
          : () async {
              return false;
            },
      child: Dialog(
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: height,
              child: SingleChildScrollView(
                physics: height == 180
                    ? NeverScrollableScrollPhysics()
                    : AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 15.0),
                  child: Column(
                    children: [
                      const Text("Settle on Customer's Account",
                          style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xffCC471B))),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: FutureBuilder(
                                future: fetchCustomer(),
                                builder: (BuildContext context,
                                    AsyncSnapshot snapshot) {
                                  return snapshot.hasData
                                      ? 
                                      
                                      Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: StatefulBuilder(
                                                builder: (context, innState) {
                                              return DropdownButton<dynamic>(
                                                isExpanded: true,
                                                isDense: true,
                                                underline: const SizedBox(),
                                                hint: Text(customerName ??
                                                    'Select Customer'),
                                                items: snapshot.data.map<
                                                    DropdownMenuItem<
                                                        dynamic>>((item) {
                                                  return DropdownMenuItem<
                                                      dynamic>(
                                                    value: item,
                                                    child: Text(item.name),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  innState(() {
                                                    customerName =
                                                        value.name.toString();
                                                    customerId = value.id;
                                                  });
                                                },
                                              );
                                            }),
                                          ),
                                        )
                                      
                                      
                                      
                                      : Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              children: const [
                                                Text('Select Customer')
                                              ],
                                            ),
                                          ));
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 180.0,
                            ),
                            SizedBox(
                              height: 45.0,
                              child: ElevatedButton(
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.arrow_forward_ios_sharp,
                                        color: Colors.white,
                                      ),
                                      Text('Settle Now')
                                    ]),
                                // : const CircularProgressIndicator(
                                //     color: Colors.white,
                                //   ),
                                style: ElevatedButton.styleFrom(
                                  primary: const Color(0xff00a65a),
                                ),
                                onPressed: () {
                                  if (!isLoading) {
                                    creditSettle();
                                  }
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Want to Register Your New Customer ?",
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Color(0xffCC471B)),
                            ),
                            SizedBox(
                              height: 35.0,
                              child: ElevatedButton(
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.person_add,
                                        color: Colors.white,
                                      ),
                                      Text(
                                        'Register Here',
                                      )
                                    ]),
                                // : const CircularProgressIndicator(
                                //     color: Colors.white,
                                //   ),
                                style: ElevatedButton.styleFrom(
                                  primary: const Color(0xffCC471B),
                                ),
                                onPressed: () {
                                  if (!isLoading) {
                                    setState(() {
                                      height = 500;
                                    });
                                  }
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Customer Name',
                                        style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      TextFormField(
                                          controller: customerNameForm,
                                          keyboardType: TextInputType.text,
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return 'Enter Customer Name';
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            hintText: 'Enter Customer Name',
                                            contentPadding:
                                                const EdgeInsets.only(
                                              bottom: 10.0,
                                              left: 8,
                                            ),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5.0)),
                                          )),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  width: 80,
                                ),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Customer Mobile No.',
                                        style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      TextFormField(
                                          controller: customerMobileForm,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return "Enter Customer's Mobile No.";
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            hintText:
                                                "Enter Customer's Mobile No.",
                                            contentPadding:
                                                const EdgeInsets.only(
                                              bottom: 10.0,
                                              left: 8,
                                            ),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5.0)),
                                          )),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Address',
                                        style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      TextFormField(
                                          controller: customerAddressForm,
                                          keyboardType: TextInputType.text,
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return "Enter Customer's Address.";
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            hintText:
                                                "Enter Customer's Address.",
                                            contentPadding:
                                                const EdgeInsets.only(
                                              bottom: 10.0,
                                              left: 8,
                                            ),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5.0)),
                                          )),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  width: 80,
                                ),
                                Flexible(
                                    child: Column(
                                  children: [
                                    const Text(
                                      'Gender',
                                      style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: RadioListTile(
                                            title: const Text('Male'),
                                            value: 1,
                                            groupValue: _groupValue,
                                            onChanged: (int? value) {
                                              if (!isLoading) {
                                                setState(() {
                                                  _groupValue = value!;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        Flexible(
                                          child: RadioListTile(
                                            title: const Text('Female'),
                                            value: 2,
                                            groupValue: _groupValue,
                                            onChanged: (int? value) {
                                              if (!isLoading) {
                                                setState(() {
                                                  _groupValue = value!;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ))
                              ],
                            ),
                            SizedBox(
                              height: 40,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                SizedBox(
                                  width: 250,
                                  height: 35.0,
                                  child: ElevatedButton(
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.cancel_rounded,
                                            color: Colors.white,
                                          ),
                                          Text(
                                            'Cancel',
                                          )
                                        ]),
                                    // : const CircularProgressIndicator(
                                    //     color: Colors.white,
                                    //   ),
                                    style: ElevatedButton.styleFrom(
                                      primary: const Color(0xfff39c12),
                                    ),
                                    onPressed: () {
                                      if (!isLoading) {
                                        setState(() {
                                          height = 180.0;
                                        });
                                        _formKey.currentState!.reset();
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 0.0,
                                ),
                                SizedBox(
                                  width: 250,
                                  height: 35.0,
                                  child: ElevatedButton(
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.person_add,
                                            color: Colors.white,
                                          ),
                                          Text(
                                            'Register Here',
                                          )
                                        ]),
                                    // : const CircularProgressIndicator(
                                    //     color: Colors.white,
                                    //   ),
                                    style: ElevatedButton.styleFrom(
                                      primary: Color(0xffCC471B),
                                    ),
                                    onPressed: () {
                                      if (!isLoading) {
                                        if (_formKey.currentState!.validate()) {
                                          FocusScope.of(context)
                                              .requestFocus(FocusNode());
                                          registerCustomer();
                                        }
                                      }
                                    },
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      )
                   
                   
                   
                   
                    ],
                  ),
                ),
              ))),
    );
  }
}
