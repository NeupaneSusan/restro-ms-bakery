// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';


import 'package:restro_ms_bakery/controller/printController.dart';
import 'package:restro_ms_bakery/controller/urlController.dart';
import 'package:restro_ms_bakery/screens/alertPage/credit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import 'package:restro_ms_bakery/controller/billController.dart';
// import 'package:restro_ms_online/controller/printController.dart';
// import 'package:restro_ms/screens/loginscreen.dart';
// import 'package:restro_ms/screens/paidorders.dart';
// import 'package:restro_ms/screens/fonepay.dart';
import 'editpos.dart';
import 'package:flutter/services.dart';

class OrderScreen extends StatefulWidget {
  OrderScreen({Key? key, this.data}) : super(key: key);

  final data;

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List? orders = [];
  int count = 0;
  bool isLoading = false;

  Future<String> getOrderData() async {
    final urlController = Provider.of<UrlController>(context, listen: false);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var baseUrl = prefs.getString('baseUrl');
    var id = prefs.get("userid");
    var getOrderUrl = urlController.getUrlValue == 0
        ? "$baseUrl/api/tableOrders/getUnpaidOrders/$id"
        : urlController.getUrlValue == 1
            ? "$baseUrl/api/twOrders/getUnPaidOrders/$id"
            : "$baseUrl/api/hdOrders/getUnPaidOrders/$id";
    final response = await http.get(Uri.parse(getOrderUrl));

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      
      if (mounted) {
        setState(() {
          orders = jsonData['data'];
          count = orders!.length;
        });
      }

      return "success";
    } else {
      throw Exception('Failed to load data');
    }
  }

  // Future<String> _billRequest(orderId) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   var id = prefs.get("userid");
  //   final response =
  //       await http.get(url + "/tableOrders/requestBill/$id/$orderId");

  //   if (response.statusCode == 200) {
  //   Fluttertoast.showToast(msg:"Bill Successfully Requested", context,
  //         duration: Toast.LENGTH_LONG,
  //         gravity: Toast.CENTER,
  //         textColor: Colors.white,
  //         backgroundColor: Colors.green);
  //     return "success";
  //   } else {
  //     throw Exception('Failed to load data');
  //   }
  // }

  @override
  void initState() {
    getOrderData();
    super.initState();
  }
  String fixedString(value){
    return double.parse(value).toStringAsFixed(2);
  }
  @override
  Widget build(BuildContext context) {
    final urlController = Provider.of<UrlController>(context, listen: false);
    var width = MediaQuery.of(context).size.width - 230;
    var height = MediaQuery.of(context).size.height - 80;
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return Scaffold(
      key: _scaffoldKey,
      body: count == 0
          ? const Center(
              child: Center(
                child: Text("No Orders Yet!"),
              ),
            )
          : ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    urlController.getUrlValue == 0
                        ? "Current Running Tables : $count "
                        : urlController.getUrlValue == 1
                            ? "Current Running Take Aways : $count"
                            : 'Current Running HD : $count',
                    style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  crossAxisCount: 7,
                  children: orders!.map((data) {
                    return WillPopScope(
                      onWillPop: () async {
                        return true;
                      },
                      child: InkWell(
                        onLongPress: () async {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          var id = prefs.get("userid");
                          Vibration.vibrate(duration: 150, amplitude: 1);
                          showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) {
                                return AlertBody(
                                  userId: id,
                                  orderId: data['id'],
                                  discount: data['discount'],
                                  discountType: data['discount_type'],
                                  netAmount: data['net_amount'],
                                  grossAmount: data['gross_amount'],
                                  height: height,
                                  tableId: data['table_id'],
                                  discoutDetails: data['discount_details'],
                                  urlController: urlController.getUrlValue,
                                  width: width,
                                );
                              }).then((value) {
                            if (value != null && value == true) {
                              getOrderData();
                            }
                          });

                          // _neverSatisfied(
                          //     data['id'], data['user_id'],data['net_amount'], width, height);
                        },
                        child: Card(
                          color: data['is_printed'] == '0'
                              ? Colors.red
                              : Colors.grey[500],
                          child: InkWell(
                            onTap: !isLoading ?  () async {
                                Vibration.vibrate(duration: 150, amplitude: 1);
                              if (urlController.getUrlValue == 0) {
                                setState(() {
                                  isLoading = true;
                                });
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                var baseUrl = prefs.getString('baseUrl');
                                
                                var res = await http.get(Uri.parse(
                                    "$baseUrl/api/tableOrders/${widget.data['id']}/${data['id']}"));
                                 
                                if (res.statusCode == 200) {
                                  if(mounted){
                                    isLoading = false;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => EditPosScreen(
                                            urlController:
                                                urlController.getUrlValue,
                                            orderId: data['id'],
                                            data: widget.data)),
                                  ).then((value) {
                                    if (value != null && value == true) {
                                      getOrderData();
                                    }
                                  });
                                  //  Navigator.push(context,MaterialPageRoute(builder: (context) => EditPosScreen(
                                  //         orderId: data['id'], data: widget.data))).then((value) { setState(() {});
                                  // Navigator.of(context).push(
                                  //     MaterialPageRoute(builder: (context){
                                  //   return EditPosScreen(
                                  //       orderId: data['id'], data: widget.data);
                                  // }));
                                } else if (res.statusCode == 406) {
                                  var message =
                                      json.decode(res.body)['message'];
                                  Fluttertoast.showToast(
                                      msg: message,
                                      toastLength: Toast.LENGTH_LONG,
                                      gravity: ToastGravity.CENTER,
                                      textColor: Colors.white,
                                      backgroundColor: Colors.green);
                                } else if (res.statusCode == 401) {
                                  var message =
                                      json.decode(res.body)['message'];
                                  Fluttertoast.showToast(
                                      msg: message,
                                      toastLength: Toast.LENGTH_LONG,
                                      gravity: ToastGravity.CENTER,
                                      textColor: Colors.white,
                                      backgroundColor: Colors.orange);
                                }
                                setState(() {
                                  isLoading = false;
                                });
                              } else {
                                setState(() {
                                  isLoading = false;
                                });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EditPosScreen(
                                          urlController:
                                              urlController.getUrlValue,
                                          orderId: data['id'],
                                          data: widget.data)),
                                ).then((value) {
                                  if (value != null && value == true) {
                                    getOrderData();
                                  }
                                });
                              }
                            } : (){
                             
                            },
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                margin: const EdgeInsets.only(top: 5),
                                child: Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 35.0),
                                      child: SizedBox(
                                        width: 40.0,
                                        child: Image.asset(
                                          "assets/table.png",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      urlController.getUrlValue == 0
                                          ? data['table_name'].toString()
                                          : urlController.getUrlValue == 1
                                              ? data['token_no'].toString()
                                              : data['hd_no'].toString(),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 13),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: Text(
                                        data['order_created_time'].toString(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 13),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 5),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Card(
                                          color: Colors.redAccent,
                                          elevation: 0,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              "Rs. ${fixedString(data['net_amount'])}",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  // Future<void> _neverSatisfied(orderId, userId,totalAmount, width, height) {
  //   return showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return Dialog(
  //           backgroundColor: Color(0Xfffd2d6de),
  //           shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(20.0)), //this right here
  //           child: AlertBody(width:width));

  //       });
  // }
}

class AlertBody extends StatefulWidget {
  final double? width, height;
  final String? discountType, discoutDetails;
  final String? grossAmount, discount, netAmount;
  final String? orderId;
  final dynamic userId;
  final dynamic tableId;

  final int? urlController;

  const AlertBody(
      {Key? key,
      this.width,
      this.height,
      this.discountType,
      this.discount,
      this.discoutDetails,
      this.grossAmount,
      this.netAmount,
      this.orderId,
      this.userId,
      this.tableId,
      this.urlController})
      : super(key: key);

  @override
  _AlertBodyState createState() => _AlertBodyState();
}

class _AlertBodyState extends State<AlertBody> {
  var fontStyles = const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500);
  TextEditingController _discountController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _fonePayController = TextEditingController();
  TextEditingController _discoutDetailsController = TextEditingController();
  final discoutTypeList = [
    {
      "name": 'Select',
      "value": 'Select',
    },
    {"name": 'Fixed Amount', "value": "FA"},
    {"name": 'Percentage', "value": 'DP'},
    {"name": 'Cancel Amount', "value": 'Cancel'}
  ];
  final paymentMethodList = [
    {"text": 'Cash', "value": 'Cash'},
    {"text": 'ManualFonepay', "value": 'Manual Fonpay'},
    {"text": "MF & Cash", "value": 'mf-and-cash'},
    {"text": "Card", "value": "Card"},
    {"text": "Credit", 'value': "Credit"},
    {"text": "E-Sewa", 'value': "eSewa"}
  ];
  @override
  void initState() {
    super.initState();

    final billcontroller = Provider.of<BillController>(context, listen: false);
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _discountController = TextEditingController(text: widget.discount);
      _discoutDetailsController =
          TextEditingController(text: widget.discoutDetails);
      billcontroller.setDiscountType(
          widget.discountType!.isEmpty ? 'Select' : widget.discountType);
      billcontroller.setTotalAmount(
        widget.grossAmount!,
        widget.discount!.isEmpty ? '0.0' : widget.discount!,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillController>(builder: (context, billController, chilc) {
      return Dialog(
        backgroundColor: const Color(0xfffd2d6de),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: SizedBox(
          height: 240,
          width: widget.width,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Flexible(
                      //     child: Column(
                      //   children: [
                      //     // Text(
                      //     //   'Total qty: 4',
                      //     //   style: fontStyles,
                      //     // ),
                      //     const SizedBox(
                      //       height: 5.0,
                      //     ),
                      //     Text('Status: Unpaid', style: fontStyles)
                      //   ],
                      // )),
                      Flexible(
                          child: Column(
                        children: [
                          Text('Gross Amount', style: fontStyles),
                          const SizedBox(
                            height: 5.0,
                          ),
                          Text(widget.grossAmount!, style: fontStyles)
                        ],
                      )),
                      Flexible(
                          child: Column(
                        children: [
                          Text('Discount Type', style: fontStyles),
                          const SizedBox(
                            height: 5.0,
                          ),
                          Container(
                              width: 145.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: Colors.blueGrey, // set border color
                                    width: 1.0), // set border width
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(
                                        10.0)), // set rounded corner radius
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton(
                                    value: billController.getdiscountType,
                                    items: discoutTypeList.map((e) {
                                      return DropdownMenuItem(
                                          value: e['value'],
                                          child: Text(e['name']!));
                                    }).toList(),
                                    onChanged: (dynamic value) {
                                      if (value == 'Select') {
                                        _discountController.clear();
                                      }
                                      // _cashController.clear();
                                      //  _discountController.clear();
                                      billController.setDiscountType(value);
                                    },
                                  ),
                                ),
                              )),
                        ],
                      )),
                      Flexible(
                          child: Column(
                        children: [
                          Text(
                            'Discount',
                            style: fontStyles,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Container(
                            height: 40.0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: billController.discoutField
                                      ? Colors.blueGrey
                                      : Colors.white, // set border color
                                  width: 1.0), // set border width
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(
                                      10.0)), // set rounded corner radius
                            ),
                            child: TextFormField(
                                keyboardType: TextInputType.number,
                                controller: _discountController..text,
                                //  initialValue: '',
                                onChanged: (value) {
                                  billController.onChangeValueAmount(value);
                                },
                                enabled: billController.discoutField,
                                decoration: const InputDecoration(
                                    hintText: '0',
                                    contentPadding:
                                        EdgeInsets.only(left: 10, bottom: 10.0),
                                    border: InputBorder.none)),
                          ),
                        ],
                      )),
                      Flexible(
                          child: Column(
                        children: [
                          Text(
                            'Net Amount',
                            style: fontStyles,
                          ),
                          const SizedBox(
                            height: 5.0,
                          ),
                          Text(
                            'Rs.${billController.changeTotalAmount}',
                            style: fontStyles,
                          )
                        ],
                      )),
                      Flexible(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.local_offer),
                          label: const Text('Discount'),
                          style: ElevatedButton.styleFrom(
                              primary: Colors.blue[400],
                              fixedSize: const Size(120, 35)),
                          onPressed: () {
                            if (billController.getdiscountType != 'Select') {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return SizedBox(
                                    width: 250.0,
                                    height: 250.0,
                                    child: AlertDialog(
                                      title: const Text('Discount Detail'),
                                      content: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                              color: Colors
                                                  .blueGrey, // set border color
                                              width: 1.0), // set border width
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(
                                                  10.0)), // set rounded corner radius
                                        ),
                                        child: TextField(
                                          controller: _discoutDetailsController,
                                          maxLines: 2,
                                          expands: false,
                                          decoration: const InputDecoration(
                                              border: InputBorder.none),
                                        ),
                                      ),
                                      actions: <Widget>[
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              primary: Colors.green,
                                              fixedSize: const Size(100, 35)),
                                          child: const Text('Save'),
                                          onPressed: () {
                                            Fluttertoast.showToast(
                                              msg: 'Requesting',
                                              toastLength: Toast.LENGTH_LONG,
                                            );
                                            saveDiscount(widget.urlController);
                                          },
                                        ),
                                        ElevatedButton(
                                          child: const Text('Close me!'),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        )
                                      ],
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                          child: Column(
                        children: [
                          Text(
                            'Payment Method',
                            style: fontStyles,
                          ),
                          const SizedBox(
                            height: 5.0,
                          ),
                          Container(
                            width: 150,
                            height: 40.0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: Colors.blueGrey, // set border color
                                  width: 1.0), // set border width
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(
                                      10.0)), // set rounded corner radius
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 2.0, right: 2.0),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<dynamic>(
                                  value: billController.getpaymentMethod,
                                  items: paymentMethodList.map((e) {
                                    return DropdownMenuItem(
                                        value: e['value'],
                                        child: Text(e['text']!));
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value == "Credit") {
                                      showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (context) {
                                            return CreditPage(
                                              urlController:
                                                  widget.urlController!,
                                              tableId: widget.tableId,
                                              orderId: widget.orderId,
                                            );
                                          });
                                    } else {
                                      if (billController.getpaymentMethod !=
                                          value) {
                                        if (value != 'Cash') {
                                          _cashController.clear();
                                        }
                                        if (value != ' mf-and-cash') {
                                          _fonePayController.clear();
                                        }
                                        billController.setPaymentMethod(value);
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      )),
                      Flexible(
                          child: Column(
                        children: [
                          Text(
                            billController.getpaymentMethod == 'eSewa'
                                ? 'eSewa Amount'
                                : 'FonePay Amount',
                            style: fontStyles,
                          ),
                          const SizedBox(
                            height: 5.0,
                          ),
                          Container(
                            height: 40.0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: billController.getFonpayField
                                      ? Colors.blueGrey
                                      : Colors.white, // set border color
                                  width: 1.0), // set border width
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(
                                      10.0)), // set rounded corner radius
                            ),
                            child: TextField(
                                enabled: billController.getFonpayField,
                                controller: _fonePayController,
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  if (billController.getpaymentMethod ==
                                      'mf-and-cash') {
                                    var cash = _cashController.text.isEmpty
                                        ? 0.0
                                        : double.tryParse(
                                            _cashController.text)!;

                                    var fonePay = value.isEmpty
                                        ? 0.0
                                        : double.tryParse(value)!;

                                    var total = (cash + fonePay).toString();

                                    billController.cashAmountPayment(total);
                                  }
                                },
                                decoration: InputDecoration(
                                    hintText: billController.getpaymentMethod ==
                                                'Manual Fonpay' ||
                                            billController.getpaymentMethod ==
                                                'eSewa'
                                        ? billController.getTotalPaid.toString()
                                        : '0',
                                    contentPadding: const EdgeInsets.only(
                                        left: 10.0, bottom: 10.0),
                                    border: InputBorder.none)),
                          ),
                        ],
                      )),
                      Flexible(
                          child: Column(
                        children: [
                          Text(
                            'Cash Amount',
                            style: fontStyles,
                          ),
                          const SizedBox(
                            height: 5.0,
                          ),
                          Container(
                            height: 40.0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: billController.getcashField
                                      ? Colors.blueGrey
                                      : Colors.white, // set border color
                                  width: 1.0), // set border width
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(
                                      10.0)), // set rounded corner radius
                            ),
                            child: TextFormField(
                                enabled: billController.getcashField,
                                controller: _cashController,
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  if (value.isEmpty) {
                                    _cashController.clear();
                                  }
                                  if (billController.getpaymentMethod ==
                                      'mf-and-cash') {
                                    var cash = value.isEmpty
                                        ? 0.0
                                        : double.tryParse(value)!;
                                    var fonePay =
                                        _fonePayController.text.isEmpty
                                            ? 0.0
                                            : double.tryParse(
                                                _fonePayController.text)!;

                                    var total = (cash + fonePay).toString();

                                    billController.cashAmountPayment(total);
                                  } else {
                                    billController.cashAmountPayment(value);
                                  }
                                },
                                decoration: const InputDecoration(
                                    hintText: '0',
                                    contentPadding: EdgeInsets.only(
                                        left: 10.0, bottom: 10.0),
                                    border: InputBorder.none)),
                          ),
                        ],
                      )),
                      Flexible(
                          child: Column(
                        children: [
                          Text(
                            'Total Paid',
                            style: fontStyles,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Rs.${billController.getTotalPaid}',
                            style: fontStyles,
                          )
                        ],
                      )),
                      Flexible(
                          child: Column(
                        children: [
                          Text(
                            'Return Amount',
                            style: fontStyles,
                          ),
                          const SizedBox(
                            height: 5.0,
                          ),
                          Text(
                            'Rs: ${billController.getReturnAmount}',
                            style: fontStyles,
                          )
                        ],
                      ))
                    ],
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("Close"),
                          style: ElevatedButton.styleFrom(
                              primary: Colors.redAccent,
                              fixedSize: const Size(100, 35)),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),

                      // Flexible(
                      //   child: ElevatedButton.icon(
                      //     icon: const Icon(Icons.local_offer),
                      //     label: const Text('Discount'),
                      //     style: ElevatedButton.styleFrom(
                      //         primary: Colors.blue[400],
                      //         fixedSize: const Size(120, 35)),
                      //     onPressed: () {
                      //       if (billController.getdiscountType != 'Select') {
                      //         showDialog(
                      //           context: context,
                      //           builder: (context) {
                      //             return SizedBox(
                      //               width: 250.0,
                      //               height: 250.0,
                      //               child: AlertDialog(
                      //                 title: const Text('Discount Detail'),
                      //                 content: Container(
                      //                   decoration: BoxDecoration(
                      //                     color: Colors.white,
                      //                     border: Border.all(
                      //                         color: Colors
                      //                             .blueGrey, // set border color
                      //                         width: 1.0), // set border width
                      //                     borderRadius: const BorderRadius.all(
                      //                         Radius.circular(
                      //                             10.0)), // set rounded corner radius
                      //                   ),
                      //                   child: TextField(
                      //                     controller: _discoutDetailsController,
                      //                     maxLines: 2,
                      //                     expands: false,
                      //                     decoration: const InputDecoration(
                      //                         border: InputBorder.none),
                      //                   ),
                      //                 ),
                      //                 actions: <Widget>[
                      //                   ElevatedButton(
                      //                     style: ElevatedButton.styleFrom(
                      //                         primary: Colors.green,
                      //                         fixedSize: const Size(100, 35)),
                      //                     child: const Text('Save'),
                      //                     onPressed: () {
                      //                       Fluttertoast.showToast(
                      //                         msg: 'Requesting',
                      //                         toastLength: Toast.LENGTH_LONG,
                      //                       );
                      //                       saveDiscount(widget.urlController);
                      //                     },
                      //                   ),
                      //                   ElevatedButton(
                      //                     child: const Text('Close me!'),
                      //                     onPressed: () {
                      //                       Navigator.pop(context);
                      //                     },
                      //                   )
                      //                 ],
                      //               ),
                      //             );
                      //           },
                      //         );
                      //       }
                      //     },
                      //   ),
                      // ),

                      Flexible(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.print_sharp),
                          label: const Text("Print"),
                          style: ElevatedButton.styleFrom(
                              primary: Colors.blueAccent,
                              fixedSize: const Size(100, 35)),
                          onPressed: () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            var baseUrl = prefs.getString('baseUrl');
                            Fluttertoast.showToast(
                                msg: 'Requesting Print',
                                toastLength: Toast.LENGTH_LONG);

                            var urlPrintData = widget.urlController == 0
                                ? '$baseUrl/api/tableOrders/printBill/${widget.userId}/${widget.orderId}'
                                : widget.urlController == 1
                                    ? '$baseUrl/api/twOrders/printBill/${widget.userId}/${widget.orderId}'
                                    : '$baseUrl/api/hdOrders/printBill/${widget.userId}/${widget.orderId}';

                            var res = await http.get(Uri.parse(urlPrintData));
                            if (res.statusCode == 200) {
                              if (widget.urlController == 2) {
                                var data = jsonDecode(res.body);
                                var info = data['data'];
                                var qrImage = data['qr_image'];
                                var result = await printerHomeDelivery(
                                  info,
                                  qrImage,
                                  context,
                                );
                                if (result) {
                                  Fluttertoast.showToast(
                                      msg: 'Successfully Printed',
                                      toastLength: Toast.LENGTH_LONG);
                                  Navigator.of(context).pop(true);
                                } else {
                                  Fluttertoast.showToast(
                                      msg: 'Print isnot Connected',
                                      toastLength: Toast.LENGTH_LONG);
                                  Navigator.of(context).pop(true);
                                }
                              } else {
                                var data = jsonDecode(res.body)['data'];

                                var result = await printingOrder(
                                    data,
                                    widget.orderId,
                                    context,
                                    widget.urlController);
                                if (result) {
                                  Fluttertoast.showToast(
                                      msg: 'Successfully Printed',
                                      toastLength: Toast.LENGTH_LONG);
                                  Navigator.of(context).pop(true);
                                } else {
                                  Fluttertoast.showToast(
                                      msg: 'Print isnot Connected',
                                      toastLength: Toast.LENGTH_LONG);
                                  Navigator.of(context).pop(true);
                                }
                              }
                            } else {
                              Fluttertoast.showToast(
                                  msg: 'unAvaible to Connected',
                                  toastLength: Toast.LENGTH_LONG);
                            }
                          },
                        ),
                      ),
                      Flexible(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.euro_symbol),
                          label: const Text('Paid'),
                          style: ElevatedButton.styleFrom(
                              primary: Colors.green[400],
                              fixedSize: const Size(100, 35)),
                          onPressed: () {
                            if (billController.getpaymentMethod == 'Cash') {
                              paidFunction(widget.urlController);
                            } else {
                              if (billController.getTotalPaid! >=
                                  billController.changeTotalAmount!) {
                                Fluttertoast.showToast(msg: 'Requesting');
                                paidFunction(widget.urlController);
                              } else {
                                Fluttertoast.showToast(
                                    msg: 'Please Provide full Money');
                              }
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
    });
  }

  void saveDiscount(urlController) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var baseUrl = prefs.getString('baseUrl');
    final billController = Provider.of<BillController>(context, listen: false);
    var discoutUrl = urlController == 0
        ? '$baseUrl/api/tableOrders/discount/${widget.userId}/${widget.orderId}'
        : urlController == 1
            ? '$baseUrl/api/twOrders/discount/${widget.userId}/${widget.orderId}'
            : '$baseUrl/api/hdOrders/discount/${widget.userId}/${widget.orderId}';
    Map<String, String> header = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    var body = {
      "discount_details": _discoutDetailsController.text,
      "discount_type": billController.getdiscountType == 'Select'
          ? ''
          : billController.getdiscountType,
      "discount": _discountController.text,
      "net_amount": billController.changeTotalAmount,
    };

    var response = await http.post(Uri.parse(discoutUrl),
        body: jsonEncode(body), headers: header);
    if (response.statusCode == 200) {
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: 'Successfully Discounted', toastLength: Toast.LENGTH_LONG);
      Navigator.of(context).pop(true);
    } else {
      Fluttertoast.showToast(
          msg: 'Unable to Connect', toastLength: Toast.LENGTH_LONG);
    }
  }

  void paidFunction(urlController) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var baseUrl = prefs.getString('baseUrl');
    final billController = Provider.of<BillController>(context, listen: false);
    var fonepay = billController.getpaymentMethod == 'Cash'
        ? 0
        : billController.getpaymentMethod == 'Manual Fonpay'
            ? billController.changeTotalAmount
            : billController.getpaymentMethod == 'mf-and-cash'
                ? _fonePayController.text
                : 0.0;
    var cashAmout = billController.getpaymentMethod == 'Cash' ||
            billController.getpaymentMethod == 'mf-and-cash'
        ? _cashController.text
        : billController.getpaymentMethod == 'Card'|| billController.getpaymentMethod =='eSewa'
            ? billController.changeTotalAmount
            : 0.0;
    var urlPaid = urlController == 0
        ? '$baseUrl/api/tableOrders/paid/${widget.userId}/${widget.orderId}'
        : urlController == 1
            ? '$baseUrl/api/twOrders/paid/${widget.userId}/${widget.orderId}'
            : '$baseUrl/api/hdOrders/paid/${widget.userId}/${widget.orderId}';

    var body = urlController == 0
        ? {
            "payment_method": billController.getpaymentMethod,
            "fonepay_amount": fonepay,
            "cash_amount": cashAmout,
            "table_id": widget.tableId,
          }
        : {
            "payment_method": billController.getpaymentMethod,
            "fonepay_amount": fonepay,
            "cash_amount": cashAmout,
          };
    Map<String, String> header = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
 
    var response = await http.post(Uri.parse(urlPaid),
        body: jsonEncode(body), headers: header);
    
    if (response.statusCode == 200) {
      Fluttertoast.showToast(
          msg: 'Successfully Paid', toastLength: Toast.LENGTH_LONG);
      Navigator.of(context).pop(true);
    } else {
      Fluttertoast.showToast(
          msg: 'Unable to Connect', toastLength: Toast.LENGTH_LONG);
    }
  
  
  
  }
}
