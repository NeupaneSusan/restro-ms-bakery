import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:restro_ms_bakery/controller/CartController.dart';
import 'package:restro_ms_bakery/controller/printController.dart';
import 'package:restro_ms_bakery/controller/urlController.dart';
import 'package:restro_ms_bakery/models/customer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class HomeDeliveryPage extends StatefulWidget {
  final String userId;
  final String? remark;
  final String storeId;

  const HomeDeliveryPage(
      {Key? key, required this.userId, this.remark, required this.storeId})
      : super(key: key);

  @override
  _HomeDeliveryPageState createState() => _HomeDeliveryPageState();
}

class _HomeDeliveryPageState extends State<HomeDeliveryPage> {
  TextEditingController customerAddressForm = TextEditingController();
  TextEditingController customerMobileForm = TextEditingController();
  TextEditingController customerNameForm = TextEditingController();
  final formkey = GlobalKey<FormState>();
  List<Customer> customerList = [];
  bool isOrder = true;
  bool isComplete = false;
  int _groupValue = 1;
  @override
  void initState() {
    fetchCustomer();
    super.initState();
  }

  Future fetchCustomer() async {
    setState(() {
      isComplete = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var baseUrl = prefs.getString('baseUrl');
    var customerUrl = Uri.parse('$baseUrl/api/customers');

    var res = await http.get(customerUrl);

    if (res.statusCode == 200) {
      List<Customer> customerLists = [];
      var jsonData = jsonDecode(res.body);
      for (var data in jsonData['data']) {
        customerLists.add(Customer.fromJson(data));
      }

      setState(() {
        isComplete = false;
        customerList = customerLists;
      });
      return customerList;
    } else {
      Navigator.pop(context);
      toast("can't load data", Colors.red);
      throw "Can't get data.";
    }
  }

  Future orderNow() async {
    setState(() {
      isComplete = true;
    });
    final urlController = Provider.of<UrlController>(context, listen: false);
    final cart = Provider.of<CartController>(context, listen: false);
    var cartItems = [];
    cart.items.forEach((key, value) => {
          cartItems.add({
            'product_id': key,
            'quantity': value.quantity,
            'rate': value.rate,
            'amount': (value.quantity! * value.rate!).toStringAsFixed(2),
            'product_store_id': value.storeId,
          })
        });

    if (urlController.getUrlValue == 2) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        var baseUrl = prefs.getString('baseUrl');
        Map<String, String> header = {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        };
        var orderUrl = Uri.parse('$baseUrl/api/hdOrders/create');
        var body = {
          "user_id": widget.userId,
          "customer_name": customerNameForm.text,
          "phone_no": customerMobileForm.text,
          "address": customerAddressForm.text,
          "gross_amount": cart.totalAmount.toStringAsFixed(2),
          "net_amount": cart.totalAmount.toStringAsFixed(2),
          "delivery_time": "04:00",
          "store_id": widget.storeId,
          "remark": widget.remark,
          "home_delivery_items": cartItems
        };
        var res = await http.post(
          orderUrl,
          headers: header,
          body: jsonEncode(body),
        );
        if (res.statusCode == 200) {
          cart.clear();
           Navigator.of(context).pop(true);
         
          toast('Printing KOT', Colors.black);
          var data = jsonDecode(res.body)['data'];
          var result =
              await printingHomeDeliveryOrderReceipt(data, context, false);
          if (result) {
            toast('Printing T/W Token', Colors.blueAccent);
          } else {
            toast('Unable to Connected Printer', Colors.redAccent);
          }
        } else {
          toast('Unable to create ', Colors.redAccent);
        }
        if (mounted) {
          setState(() {
            isComplete = false;
          });
        }
      } catch (error) {
        rethrow;
      }
    } else {
      toast('Unable to Checkout Please Restart you app', Colors.redAccent);
      setState(() {
        isComplete = false;
      });
    }
  }

  Future resigterCustomer() async {
    setState(() {
      isComplete = true;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var baseUrl = prefs.getString('baseUrl');

      var body = {
        "name": customerNameForm.text,
        "mobile_no": customerMobileForm.text,
        "address": customerAddressForm.text,
        "gender": _groupValue == 1 ? "male" : "female"
      };
      Map<String, String> header = {
        'Accept': 'application/json',
      };
      var registerCustomerUrl = Uri.parse('$baseUrl/api/customers/register');
      var respone =
          await http.post(registerCustomerUrl, body: body, headers: header);
      
      if (respone.statusCode == 200) {
        toast('Successfully add Customer', Colors.greenAccent);
        fetchCustomer();
        toast('Loading the data with for a second', Colors.greenAccent);
        formkey.currentState!.reset();
        customerAddressForm.clear();
        customerNameForm.clear();
        customerMobileForm.clear();
        setState(() {
          isComplete = false;
          isOrder = true;
        });
      } else {
        var message = jsonDecode(respone.body)['message'];
        toast(message, Colors.red);
        setState(() {
          isComplete = false;
        });
      }
    } catch (err) {
      print(err);
      rethrow;
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

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
        child: Form(
          key: formkey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (!isOrder)
                  const Text(
                    "Want to Register Your New Customer ?",
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Color(0xffCC471B)),
                  ),
                const SizedBox(
                  height: 10.0,
                ),
                Row(
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Name',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          // Autocomplete<Customer>(
                          //   optionsBuilder: (textEditingValue) {
                          //     print(textEditingValue);
                          //     return customerList
                          //         .where((Customer customer) => customer.name!
                          //             .toLowerCase()
                          //             .startsWith(
                          //                 textEditingValue.text.toLowerCase()))
                          //         .toList();
                          //   },
                          //   fieldViewBuilder: (BuildContext context,
                          //       TextEditingController
                          //           fieldTextEditingController,
                          //       FocusNode fieldFocusNode,
                          //       VoidCallback onFieldSubmitted) {
                          //     return
                          //     TextFormField(
                          //         controller: fieldTextEditingController,
                          //         keyboardType: TextInputType.text,
                          //         validator: (value) {
                          //           if (value!.isEmpty) {
                          //             return 'Enter Customer Name';
                          //           }
                          //           return null;
                          //         },
                          //         decoration: InputDecoration(
                          //           hintText: 'Enter Customer Name',
                          //           contentPadding: const EdgeInsets.only(
                          //             bottom: 10.0,
                          //             left: 8,
                          //           ),
                          //           border: OutlineInputBorder(
                          //               borderRadius:
                          //                   BorderRadius.circular(5.0)),
                          //         ));

                          //   },

                          //   optionsViewBuilder: (BuildContext context,
                          //       AutocompleteOnSelected<Customer> onSelected,
                          //       Iterable<Customer> options) {
                          //     return Container(
                          //         width: 300,
                          //         color: Colors.cyan,
                          //         child: ListView.builder(
                          //           padding: const EdgeInsets.all(10.0),
                          //           itemCount: options.length,
                          //           itemBuilder: (context, int index) {
                          //             final Customer option =
                          //                 options.elementAt(index);
                          //             return GestureDetector(
                          //               onTap: () {},
                          //               child: ListTile(
                          //                   title:
                          //                       Text(option.name.toString())),
                          //             );
                          //           },
                          //         ));
                          //   },
                          // ),

                          Autocomplete<Customer>(
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<Customer>.empty();
                              } else {
                                return customerList.where((word) => word.name!
                                    .toLowerCase()
                                    .contains(
                                        textEditingValue.text.toLowerCase()));
                              }
                            },
                            displayStringForOption: (Customer customer) =>
                                customer.name.toString(),
                            optionsViewBuilder:
                                (context, Function onSelected, options) {
                              return Material(
                                elevation: 4,
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);

                                    return ListTile(
                                      title: Text(option.name!),
                                      subtitle: Text(option.mobileNo!),
                                      onTap: () {
                                        onSelected(option);
                                        FocusScope.of(context).unfocus();
                                        // onSelected(option);
                                        // on
                                      },
                                    );
                                  },
                                  separatorBuilder: (context, index) =>
                                      Divider(),
                                  itemCount: options.length,
                                ),
                              );
                            },
                            onSelected: (value) {
                              customerAddressForm.text =
                                  value.address.toString();
                              customerMobileForm.text =
                                  value.mobileNo.toString();
                              // customerNameForm.text = value.name.toString();
                            },
                            fieldViewBuilder: (context, controller, focusNode,
                                onEditingComplete) {
                              customerNameForm = controller;

                              return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  onEditingComplete: onEditingComplete,
                                  keyboardType: TextInputType.text,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Enter Customer Name';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Enter Customer Name',
                                    contentPadding: const EdgeInsets.only(
                                      bottom: 10.0,
                                      left: 8,
                                    ),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0)),
                                  ));

                              //   // TextField(
                              //   controller: controller,
                              //   focusNode: focusNode,
                              //   onEditingComplete: onEditingComplete,
                              //   decoration: InputDecoration(
                              //     border: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(8),
                              //       borderSide:
                              //           BorderSide(color: Colors.grey[300]!),
                              //     ),
                              //     focusedBorder: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(8),
                              //       borderSide:
                              //           BorderSide(color: Colors.grey[300]!),
                              //     ),
                              //     enabledBorder: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(8),
                              //       borderSide:
                              //           BorderSide(color: Colors.grey[300]!),
                              //     ),
                              //     hintText: "Search Something",
                              //     prefixIcon: Icon(Icons.search),
                              //   ),
                              // );
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 80,
                    ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Mobile No.',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.w500),
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
                                hintText: "Enter Customer's Mobile No.",
                                contentPadding: const EdgeInsets.only(
                                  bottom: 10.0,
                                  left: 8,
                                ),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.0)),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Address',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.w500),
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
                                hintText: "Enter Customer's Address.",
                                contentPadding: const EdgeInsets.only(
                                  bottom: 10.0,
                                  left: 8,
                                ),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.0)),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 80,
                    ),
                    Flexible(
                        child: !isOrder
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      Expanded(
                                        child: RadioListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Male'),
                                          value: 1,
                                          groupValue: _groupValue,
                                          onChanged: (int? value) {
                                            setState(() {
                                              _groupValue = value!;
                                            });
                                          },
                                        ),
                                      ),
                                      Flexible(
                                        child: RadioListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Female'),
                                          value: 2,
                                          groupValue: _groupValue,
                                          onChanged: (int? value) {
                                            setState(() {
                                              _groupValue = value!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              )
                            : Container())
                  ],
                ),
                const SizedBox(
                  height: 40,
                ),
                if (!isComplete)
                  !isOrder
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SizedBox(
                              width: 250,
                              height: 35.0,
                              child: ElevatedButton(
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                  customerAddressForm.clear();
                                  customerMobileForm.clear();
                                  customerNameForm.clear();
                                  setState(() {
                                    isOrder = true;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 0.0,
                            ),
                            SizedBox(
                              width: 250,
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
                                  primary: Color(0xffCC471B),
                                ),
                                onPressed: () {
                                  if (formkey.currentState!.validate()) {
                                    FocusScope.of(context)
                                        .requestFocus(FocusNode());
                                    resigterCustomer();
                                  }
                                },
                              ),
                            )
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SizedBox(
                              width: 250,
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
                                  primary: Color(0xffCC471B),
                                ),
                                onPressed: () {
                                  setState(() {
                                    isOrder = false;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 200,
                              height: 35.0,
                              child: ElevatedButton(
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Now Order',
                                      )
                                    ]),
                                // : const CircularProgressIndicator(
                                //     color: Colors.white,
                                //   ),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.teal,
                                ),
                                onPressed: () {
                                  if (formkey.currentState!.validate()) {
                                    FocusScope.of(context)
                                        .requestFocus(FocusNode());
                                    orderNow();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
