import 'package:flutter/material.dart';

import 'package:flutter_beep/flutter_beep.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:restro_ms_bakery/controller/CartController.dart';

import 'package:restro_ms_bakery/controller/printController.dart';
import 'package:restro_ms_bakery/controller/urlController.dart';
import 'package:restro_ms_bakery/screens/alertPage/home_delivery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../models/Category.dart';
import '../models/Tables.dart';
import '../models/Product.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class PosPage extends StatefulWidget {
  const PosPage({Key? key, this.data}) : super(key: key);

  final data;

  @override
  _PosPageState createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  TextEditingController guestController = TextEditingController();
  TextEditingController remarksController = TextEditingController();
  TextEditingController filterController = TextEditingController();
  TextEditingController twNameController = TextEditingController();

  List<Category> categories = <Category>[];
  List<Tables> tables = <Tables>[];
  List<Product> products = <Product>[];
  final List<Product> _searchResult = <Product>[];

  Category? selectedCategory;
  Tables? selectedTable;

  int? _isButtonDisabled;

  // final url = "${baseUrl}api";
  // // final url = "http://d163f8b8ae8d.ngrok.io/restroms/api";
  // final imgUrl = '$baseUrl';

//fetch categories
  // Future<String> fetchCategories() async {
  //   var res = await http.get(url + '/categories');
  //   if (res.statusCode == 200) {
  //     var jsonData = jsonDecode(res.body);

  //     List<Category> cats = [];
  //     for (var data in jsonData) {
  //       cats.add(Category.fromJson(data));
  //     }
  //     setState(() {
  //       categories = cats;
  //     });
  //     return 'success';
  //   } else {
  //     throw "Can't get categories.";
  //   }
  // }

//fetch tables
  Future<String> fetchTables() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var baseUrl = prefs.getString('baseUrl');
    var floorId = prefs.getString('floorId');
    var tableUrl = Uri.parse('$baseUrl/api/tables/$floorId');
    var res = await http.get(tableUrl);

    if (res.statusCode == 200) {
      var jsonData = jsonDecode(res.body);
      List<Tables> cats = [];
      for (var data in jsonData['data']) {
        cats.add(Tables.fromJson(data));
      }
      if (mounted) {
        setState(() {
          tables = cats;
        });
      }
      return 'success';
    } else if (res.statusCode == 204) {
      toast('No Table is Available', Colors.lightGreen);
      return 'success';
    } else {
      throw "Can't get tables.";
    }
  }

  //fetch products

  Future<String> fetchProducts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var baseUrl = prefs.getString('baseUrl');
      var floorId = prefs.getString('floorId');
      var floorUrl = Uri.parse('$baseUrl/api/products/$floorId}');
      var res = await http.get(floorUrl);
      if (res.statusCode == 200) {
        var jsonData = jsonDecode(res.body);
        List<Product> cats = [];
        for (var data in jsonData) {
          cats.add(Product.fromJson(data));
        }
        if (mounted) {
          setState(() {
            products = cats;
          });
        }

        return 'success';
      } else {
        throw "Can't get products.";
      }
    } catch (error) {
      toast('No internet', Colors.redAccent);
      throw "Can't get products.";
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

  //fetch products by categorywise
  Future<String> fetchProductsByCategoryWise(id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var baseUrl = prefs.getString('baseUrl');
    var categoryWiseUrl =
        Uri.parse('$baseUrl/api/products/getProductByCategory/' + id);
    var res = await http.get(categoryWiseUrl);
    if (res.statusCode == 200) {
      var jsonData = jsonDecode(res.body);
      List<Product> cats = [];
      for (var data in jsonData) {
        cats.add(Product.fromJson(data));
      }
      setState(() {
        products = cats;
      });
      return 'success';
    } else {
      throw "Can't get products.";
    }
  }

  // post address
  // ignore: missing_return
  Future<bool> checkout({var body, cart}) async {
    final urlController = Provider.of<UrlController>(context, listen: false);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var baseUrl = prefs.getString('baseUrl');
    Map<String, String> header = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    var orderUrl = urlController.getUrlValue == 0
        ? '$baseUrl/api/tableOrders'
        : '$baseUrl/api/twOrders/create';
    var res = await http.post(
      Uri.parse(orderUrl),
      headers: header,
      body: body,
    );

    if (res.statusCode == 200) {
      toast("Order Success", Colors.green);
      selectedTable = null;
      guestController.text = 0.toString();
      twNameController.clear();
      if (urlController.getUrlValue == 1) {
        var data = jsonDecode(res.body)['data'];

        var result = await printingTokenTw(data, context, false);
        if (result) {
          toast('Printing T/W Token', Colors.blueAccent);
        } else {
          toast('Unable to Connected Printer', Colors.redAccent);
        }
      }
      if (urlController.getUrlValue == 0) {
        fetchTables();
        var data = jsonDecode(res.body)['data'];
        var result = await printingOrderReceipt(data, context, false);
        if (result) {
          toast('Printing T/W Token', Colors.blueAccent);
        } else {
          toast('Unable to Connected Printer', Colors.redAccent);
        }
      }
      setState(() {
        _isButtonDisabled = 0;
      });
      cart.clear();
      return true;
    } else if (res.statusCode == 503) {
      var message = json.decode(res.body)['message'];
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text(message),
              actions: <Widget>[
                const SizedBox(width: 20.0),
                TextButton(
                    child: const Text("Close"),
                    onPressed: () {
                      Navigator.of(context).pop();
                      cart.clear();
                      selectedTable = null;
                    }),
                const SizedBox(width: 180.0),
              ],
            );
          });

      setState(() {
        _isButtonDisabled = 0;
      });
      return false;
    } else {
      setState(() {
        _isButtonDisabled = 0;
      });
      var jsonData = json.decode(res.body);
      toast(jsonData['message'].toString(), Colors.red);

      return false;
    }
  }

  //search result
  onSearchTextChanged(String text) async {
    _searchResult.clear();
    selectedCategory = null;

    if (text.isEmpty) {
      setState(() {});
      return;
    } else {
      for (var product in products) {
        var pname = product.name.toLowerCase();
        if (pname.contains(text.toLowerCase())) {
          setState(() {
            _searchResult.add(product);
          });
        }
      }
    }
    setState(() {});
  }

  // checkDayOpen() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   var baseUrl = prefs.getString('baseUrl');
  //   var checkurl = Uri.parse('$baseUrl/api/daySettings/checkDayStatus');
  //   var res = await http.get(checkurl);
  //   if (res.statusCode == 200) {
  //     var data = jsonDecode(res.body);
  //     if (data['status'] != 1) {
  //       showDialog(
  //           barrierDismissible: false,
  //           context: context,
  //           builder: (context) {
  //             return WillPopScope(
  //                 onWillPop: () async {
  //                   return false;
  //                 },
  //                 child: const AlertPage());
  //           });
  //     }
  //   }
  // }

  @override
  void initState() {
    fetchProducts();
    // fetchCategories();
    fetchTables();
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      final cartController =
          Provider.of<CartController>(context, listen: false);
      cartController.clear();
    });
    _isButtonDisabled = 0;
  }

  @override
  Widget build(BuildContext context) {
    final urlController = Provider.of<UrlController>(context, listen: false);
    return 
    Consumer<CartController>(builder: (context, cart, child) {
      return Scaffold(
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: SafeArea(
              child: Container(
            margin: const EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 0),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Card(
                    elevation: 5,
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                              top: BorderSide(color: Colors.teal, width: 5))),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                              child: Column(
                            children: [
                              Row(children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      // Container(

                                      //   decoration: BoxDecoration(
                                      //       border:
                                      //           Border.all(color: Colors.grey)),
                                      //   child: Padding(
                                      //     padding: const EdgeInsets.all(8.0),
                                      //     child: Text('Table No.'),
                                      //   ),
                                      // ),
                                      InkWell(
                                        onTap: () async {
                                          if (urlController.getUrlValue == 0) {
                                            FocusScope.of(context)
                                                .requestFocus(FocusNode());
                                            getTables(context);
                                          }
                                        },
                                        child: Container(
                                            width: 100,
                                            height: 35,
                                            decoration: BoxDecoration(
                                                color: Colors.teal,
                                                border: Border.all(
                                                    color: Colors.grey)),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Center(
                                                  child: urlController
                                                              .getUrlValue ==
                                                          0
                                                      ? Text(
                                                          selectedTable != null
                                                              ? selectedTable!
                                                                  .name
                                                              : 'Select Table',
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                        )
                                                      : urlController
                                                                  .getUrlValue ==
                                                              1
                                                          ? const Text(
                                                              'Take Away',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white))
                                                          : const Text('HD',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white))),
                                            )),
                                      ),
                                      const SizedBox(width: 10),
                                      urlController.getUrlValue == 0
                                          ? Container()
                                          : Container(
                                              width: 100,
                                              height: 35,
                                              decoration: BoxDecoration(
                                                  color: Colors.white30,
                                                  border: Border.all(
                                                      color: Colors.grey)),
                                              child: TextField(
                                                controller: twNameController,
                                                decoration:
                                                    const InputDecoration(
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.all(6.5),
                                                        hintText: 'Name Field',
                                                        border:
                                                            InputBorder.none),
                                              ),
                                            ),
                                      SizedBox(
                                          width: urlController.getUrlValue == 0
                                              ? 0.0
                                              : 10),
                                      Container(
                                        height: 35,
                                        decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.grey)),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.edit,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),

                                      Container(
                                        width: urlController.getUrlValue == 0
                                            ? MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.418
                                            : MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.3,
                                        height: 35,
                                        decoration: BoxDecoration(
                                            color: Colors.white30,
                                            border:
                                                Border.all(color: Colors.grey)),
                                        child: TextField(
                                          controller: remarksController,
                                          decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.all(6.5),
                                              hintText: 'Remarks',
                                              border: InputBorder.none),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
                              Container(
                                color: const Color(0xFFcc471b),
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: const [
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            'Item Name',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: Center(
                                            child: Text(
                                              'Quantity',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            'Price',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: Center(
                                            child: Text(
                                              'Amount',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 10,
                                          child: Text(
                                            'X',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ]),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      border:
                                          Border.all(color: Colors.teal[100]!)),
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: ListView(
                                    children: [
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.53,
                                        child: Padding(
                                          padding: const EdgeInsets.all(1.0),
                                          child: ListView.builder(
                                            scrollDirection: Axis.vertical,
                                            itemCount: cart.items.length,
                                            itemBuilder:
                                                (BuildContext context, int i) =>
                                                    Card(
                                              elevation: 1,
                                              color: i % 2 == 0
                                                  ? Colors.deepOrange[200]
                                                  : Colors.deepOrange[300],
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(1.0),
                                                child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      SizedBox(
                                                        width: 130,
                                                        child: Text(
                                                          cart.items.values
                                                              .toList()[cart
                                                                      .items
                                                                      .length -
                                                                  i -
                                                                  1]
                                                              .name!,
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                        ),
                                                      ),
                                                      Container(
                                                        decoration: BoxDecoration(
                                                            color:
                                                                Colors.white38,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10)),
                                                        width: 100,
                                                        child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .all(
                                                                        5.0),
                                                                child:
                                                                    GestureDetector(
                                                                  onTap: () {
                                                                    cart.removeSingleItem(cart
                                                                        .items
                                                                        .keys
                                                                        .toList()[cart
                                                                            .items
                                                                            .length -
                                                                        i -
                                                                        1]);
                                                                    Vibration.vibrate(
                                                                        duration:
                                                                            150,
                                                                        amplitude:
                                                                            1);
                                                                    FlutterBeep
                                                                        .beep();
                                                                  },
                                                                  child:
                                                                      const Icon(
                                                                    Icons
                                                                        .remove_circle_outline,
                                                                    color: Colors
                                                                        .red,
                                                                  ),
                                                                ),
                                                              ),
                                                              Text(cart
                                                                  .items.values
                                                                  .toList()[cart
                                                                          .items
                                                                          .length -
                                                                      i -
                                                                      1]
                                                                  .quantity
                                                                  .toString()),
                                                              InkWell(
                                                                enableFeedback:
                                                                    true,
                                                                onTap: () {
                                                                  cart.addItem(
                                                                      cart.items
                                                                          .keys
                                                                          .toList()[cart.items.length -
                                                                              i -
                                                                              1]
                                                                          .toString(),
                                                                      cart.items
                                                                          .values
                                                                          .toList()[cart.items.length -
                                                                              i -
                                                                              1]
                                                                          .name,
                                                                      double.parse(cart
                                                                          .items
                                                                          .values
                                                                          .toList()[cart.items.length -
                                                                              i -
                                                                              1]
                                                                          .rate
                                                                          .toString()),
                                                                      cart.items
                                                                          .values
                                                                          .toList()[cart.items.length -
                                                                              i -
                                                                              1]
                                                                          .storeId);
                                                                  Vibration.vibrate(
                                                                      duration:
                                                                          150,
                                                                      amplitude:
                                                                          1);
                                                                  FlutterBeep
                                                                      .beep();
                                                                },
                                                                child:
                                                                    const Icon(
                                                                  Icons
                                                                      .add_circle_outline,
                                                                  color: Colors
                                                                      .green,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 1)
                                                            ]),
                                                      ),
                                                      Container(
                                                        margin: EdgeInsets.zero,
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 10.0),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white38,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        width: 100,
                                                        height: 35,
                                                        child: TextFormField(
                                                          decoration:
                                                              const InputDecoration(
                                                            contentPadding:
                                                                EdgeInsets.only(
                                                                    bottom:
                                                                        10.0),
                                                            border: InputBorder
                                                                .none,
                                                          ),
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          key: Key(cart
                                                              .items.keys
                                                              .toString()),
                                                          initialValue: cart
                                                              .items.values
                                                              .toList()[cart
                                                                      .items
                                                                      .length -
                                                                  i -
                                                                  1]
                                                              .rate
                                                              .toString(),
                                                          onChanged: (value) {
                                                            String price;
                                                            price =
                                                                value.isEmpty
                                                                    ? '0.0'
                                                                    : value;
                                                            cart.changePrice(
                                                              cart.items.keys
                                                                  .toList()[cart
                                                                          .items
                                                                          .length -
                                                                      i -
                                                                      1]
                                                                  .toString(),
                                                              double.parse(
                                                                  price),
                                                            );
                                                          },
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 70,
                                                        child: Center(
                                                          child: Text(
                                                            (cart.items.values
                                                                        .toList()[cart.items.length -
                                                                            i -
                                                                            1]
                                                                        .rate! *
                                                                    cart.items
                                                                        .values
                                                                        .toList()[cart.items.length -
                                                                            i -
                                                                            1]
                                                                        .quantity!)
                                                                .toStringAsFixed(
                                                                    2),
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                          width: 20,
                                                          child: InkWell(
                                                              onTap: () {
                                                                cart.removeItem(
                                                                  cart.items
                                                                      .keys
                                                                      .toList()[cart
                                                                          .items
                                                                          .length -
                                                                      i -
                                                                      1],
                                                                );
                                                                Vibration.vibrate(
                                                                    duration:
                                                                        150,
                                                                    amplitude:
                                                                        1);
                                                                FlutterBeep
                                                                    .beep();
                                                              },
                                                              child: const Icon(
                                                                  Icons.delete,
                                                                  color: Colors
                                                                      .red))),
                                                    ]),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Column(
                              children: [
                                Container(
                                  decoration:
                                      BoxDecoration(color: Colors.grey[200]),
                                  child: Padding(
                                    padding: const EdgeInsets.all(1.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(children: [
                                          const Text('Total Quantity'),
                                          Text(cart.totalItemsCount.toString())
                                        ]),
                                        Column(children: [
                                          const Text('Gross Amount'),
                                          Text(
                                              "Rs.${(cart.totalAmount).toStringAsFixed(2)}")
                                        ]),
                                        urlController.getUrlValue == 0
                                            ? Column(children: [
                                                const Text('No. of Guest'),
                                                Container(
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                        color: Colors.white),
                                                    width: 70,
                                                    height: 20,
                                                    child: TextFormField(
                                                      controller:
                                                          guestController,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      decoration:
                                                          const InputDecoration(
                                                              isDense: true,
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .all(2),
                                                              border:
                                                                  InputBorder
                                                                      .none),
                                                    ))
                                              ])
                                            : Container(),
                                        Column(children: [
                                          const Text('Net Amount'),
                                          Text(
                                              "Rs.${(cart.totalAmount).toStringAsFixed(2)}")
                                        ]),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  color: Colors.grey[200],
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 6.0, bottom: 0.0),
                                            child: TextButton(
                                              style: TextButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                              ),
                                              onPressed: () {
                                                cart.clear();
                                                selectedTable = null;
                                                guestController.text = '';
                                                remarksController.text = '';
                                                setState(() {
                                                  _isButtonDisabled = 0;
                                                  Vibration.vibrate(
                                                      duration: 150,
                                                      amplitude: 1);
                                                  FlutterBeep.beep();
                                                });
                                              },
                                              child: const Text(
                                                'Reset POS',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 200),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: 6.0, bottom: 0.0),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  primary: Colors.teal),
                                              onPressed: _isButtonDisabled == 0
                                                  ? () {
                                                      Vibration.vibrate(
                                                          duration: 150,
                                                          amplitude: 1);
                                                      FlutterBeep.beep();
                                                      var cartItems = [];
                                                      
                                                        
                                                      cart.items
                                                          .forEach(
                                                              (key, value) => {
                                                                    cartItems
                                                                        .add({
                                                                      'product_id':
                                                                          key,
                                                                      'quantity':
                                                                          value
                                                                              .quantity,
                                                                      'rate': value
                                                                          .rate,
                                                                      'amount': (value.quantity! *
                                                                              value.rate!)
                                                                          .toStringAsFixed(2),
                                                                      'product_store_id':
                                                                          value
                                                                              .storeId,
                                                                    })
                                                                  });
                                                         
                                                          
                                                      if (cartItems.isEmpty) {
                                                        toast(
                                                            'Select at leact one item',
                                                            Colors.orange);
                                                      } else if (cartItems
                                                            .any((element) =>
                                                                element[
                                                                    'rate'] ==
                                                                0.0)){

                                                        toast(
                                                            'Please set the price ',
                                                            Colors.orange);
                                                      } 
                                                      else {
                                                        if ((selectedTable ==
                                                                    null ||
                                                                widget.data ==
                                                                    null) &&
                                                            urlController
                                                                    .getUrlValue ==
                                                                0) {
                                                          getTables(context);
                                                        }

                                                        if (urlController
                                                                .getUrlValue ==
                                                            0) {
                                                          if (selectedTable !=
                                                                  null &&
                                                              widget.data !=
                                                                  null &&
                                                              cartItems
                                                                  .isNotEmpty) {
                                                            var body =
                                                                jsonEncode(<
                                                                    String,
                                                                    dynamic>{
                                                              'order_items':
                                                                  cartItems,
                                                              'gross_amount': cart
                                                                  .totalAmount
                                                                  .toStringAsFixed(
                                                                      2),
                                                              'net_amount': cart
                                                                  .totalAmount
                                                                  .toStringAsFixed(
                                                                      2),
                                                              'user_id': widget
                                                                  .data['id'],
                                                              'store_id': widget
                                                                      .data[
                                                                  'store_id'],
                                                              'no_of_guest':
                                                                  guestController
                                                                      .text,
                                                              'remark':
                                                                  remarksController
                                                                      .text,
                                                              'table_id':
                                                                  selectedTable!
                                                                      .id
                                                            });
                                                            checkout(
                                                                body: body,
                                                                cart: cart);
                                                            remarksController
                                                                .clear();
                                                            setState(() {
                                                              _isButtonDisabled =
                                                                  1;
                                                            });
                                                          }
                                                        } else if (urlController
                                                                .getUrlValue ==
                                                            1) {
                                                          if (widget.data !=
                                                                  null &&
                                                              cartItems
                                                                  .isNotEmpty) {
                                                            var body =
                                                                jsonEncode(<
                                                                    String,
                                                                    dynamic>{
                                                              'take_away_items':
                                                                  cartItems,
                                                              'gross_amount': cart
                                                                  .totalAmount
                                                                  .toStringAsFixed(
                                                                      2),
                                                              'net_amount': cart
                                                                  .totalAmount
                                                                  .toStringAsFixed(
                                                                      2),
                                                              'user_id': widget
                                                                  .data['id'],
                                                              'store_id': widget
                                                                      .data[
                                                                  'store_id'],
                                                              'tw_name':
                                                                  twNameController
                                                                      .text,
                                                              // 'no_of_guest':
                                                              //     guestController.text,
                                                              'remark':
                                                                  remarksController
                                                                      .text,
                                                            });
                                                            checkout(
                                                                body: body,
                                                                cart: cart);
                                                            remarksController
                                                                .clear();
                                                            setState(() {
                                                              _isButtonDisabled =
                                                                  1;
                                                            });
                                                          }
                                                        } else if (urlController
                                                                .getUrlValue ==
                                                            2) {
                                                          if (widget.data !=
                                                                  null &&
                                                              cartItems
                                                                  .isNotEmpty) {
                                                            FocusScope.of(
                                                                    context)
                                                                .requestFocus(
                                                                    FocusNode());
                                                            showDialog(
                                                                barrierDismissible:
                                                                    false,
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return HomeDeliveryPage(
                                                                    userId: widget
                                                                            .data[
                                                                        'id'],
                                                                    remark:
                                                                        remarksController
                                                                            .text,
                                                                    storeId: widget
                                                                            .data[
                                                                        'store_id'],
                                                                  );
                                                                }).then((value) {
                                                              if (value ==
                                                                  true) {
                                                                remarksController
                                                                    .clear();
                                                              }
                                                            });
                                                          }
                                                        }
                                                      
                                                      
                                                     }
                                                    }
                                                  : null,
                                              child: Text(
                                                _isButtonDisabled == 1
                                                    ? "Hold on..."
                                                    : "Order Now",
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        )
                                      ]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Card(
                    elevation: 5,
                    child: Container(
                      decoration: const BoxDecoration(
                          border: Border(
                              top: BorderSide(color: Colors.orange, width: 5)),
                          color: Colors.white),
                      child: ListView(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6.0),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Expanded(
                                    //   flex: 2,
                                    //   child: Container(

                                    //     decoration: BoxDecoration(
                                    //         color: Colors.white,
                                    //         border: Border.all(
                                    //             color: Colors.grey[400]),
                                    //         borderRadius:
                                    //             BorderRadius.circular(5)),
                                    //     height: 35,
                                    //     // width:
                                    //     //     MediaQuery.of(context).size.width * 0.2,
                                    //     child: Padding(
                                    //       padding: const EdgeInsets.all(4.0),
                                    //       child: getCategories(categories),
                                    //     ),
                                    //   ),
                                    // ),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                                color: Colors.grey[400]!),
                                            borderRadius:
                                                BorderRadius.circular(2)),
                                        height: 35,
                                        // width:
                                        //     MediaQuery.of(context).size.width * 0.15,

                                        child: TextField(
                                          controller: filterController,
                                          onChanged: onSearchTextChanged,
                                          //  autocorrect: true,
                                          decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.all(6.5),
                                              hintText: 'Search Item',
                                              border: InputBorder.none),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 3.0,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                          color: Colors.teal,
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: InkWell(
                                          onTap: () {
                                            filterController.clear();
                                            onSearchTextChanged('');
                                            selectedCategory = null;
                                            fetchProducts();
                                          },
                                          child: const Text(
                                            'All',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    )
                                  ]),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.75,
                              width: MediaQuery.of(context).size.height * 0.65,
                              child: _searchResult.isNotEmpty ||
                                      filterController.text.isNotEmpty
                                  ? GridView.count(
                                      crossAxisCount: 3,
                                      padding: const EdgeInsets.all(4.0),
                                      children: _searchResult.map((product) {
                                        return Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: InkWell(
                                            onTap: () {
                                              cart.addItem(
                                                  product.id.toString(),
                                                  product.name.toString(),
                                                  double.parse(product.price),
                                                  int.parse(product.storeId));
                                              Vibration.vibrate(
                                                  duration: 150, amplitude: 1);
                                              FlutterBeep.beep();
                                            },
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                  color: Color(0xFFcc471b),
                                                  borderRadius:
                                                      BorderRadius.only(
                                                          topRight: Radius
                                                              .circular(40),
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  5),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  5),
                                                          topLeft:
                                                              Radius.circular(
                                                                  40))),
                                              child: Column(children: [
                                                Card(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50)),
                                                  child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50),
                                                      child:
                                                          product.image != null
                                                              ? Image.network(
                                                                  product.image,
                                                                  height: 65,
                                                                  width: 65,
                                                                )
                                                              : Image.asset(
                                                                  'assets/logo.png',
                                                                  height: 65,
                                                                  width: 65,
                                                                )),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(1.0),
                                                  child: Text(
                                                    product.name.toString(),
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(1.0),
                                                  child: Text(
                                                    'Rs.' +
                                                        product.price
                                                            .toString(),
                                                    style: const TextStyle(
                                                        color: Colors.yellow,
                                                        fontSize: 12),
                                                  ),
                                                )
                                              ]),
                                            ),
                                          ),
                                        );
                                      }).toList())
                                  : GridView.count(
                                      crossAxisCount: 3,
                                      padding: const EdgeInsets.all(4.0),
                                      children: products.map((product) {
                                        return Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: InkWell(
                                            onTap: () {
                                              Vibration.vibrate(
                                                  duration: 150, amplitude: 1);
                                              FlutterBeep.beep();
                                              cart.addItem(
                                                  product.id.toString(),
                                                  product.name.toString(),
                                                  double.parse(product.price),
                                                  int.parse(product.storeId));
                                            },
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                  color: Color(0xFFcc471b),
                                                  borderRadius:
                                                      BorderRadius.only(
                                                          topRight: Radius
                                                              .circular(40),
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  5),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  5),
                                                          topLeft:
                                                              Radius.circular(
                                                                  40))),
                                              child: Column(children: [
                                                Card(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50)),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50),
                                                    child: product.image != null
                                                        ? Image.network(
                                                            product.image,
                                                            height: 65,
                                                            width: 65,
                                                          )
                                                        : Image.asset(
                                                            'assets/logo.png',
                                                            height: 65,
                                                            width: 65,
                                                          ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(1.0),
                                                  child: Text(
                                                    product.name.toString(),
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(1.0),
                                                  child: Text(
                                                    'Rs.' +
                                                        product.price
                                                            .toString(),
                                                    style: const TextStyle(
                                                        color: Colors.yellow,
                                                        fontSize: 12),
                                                  ),
                                                )
                                              ]),
                                            ),
                                          ),
                                        );
                                      }).toList()))
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ),
      );
    });
  
  
  
  }

  // Widget getCategories(List<Category> categories) {
  //   return DropdownButton<Category>(
  //     icon: Container(
  //         margin: EdgeInsets.only(left: 10,),
  //         alignment: Alignment.topRight,
  //         child: Icon(Icons.arrow_drop_down)),
  //     underline: Text(''),
  //     iconSize: 20,
  //     hint: Text("Select Category"),
  //     value: selectedCategory,
  //     onChanged: (Category val) {
  //       setState(() {
  //         selectedCategory = val;
  //         fetchProductsByCategoryWise(val.id);
  //       });
  //     },
  //     items: categories.map((Category user) {
  //       return DropdownMenuItem<Category>(
  //         value: user,
  //         child: Row(
  //           children: <Widget>[
  //             Icon(
  //               Icons.restaurant_menu_sharp,
  //               size: 18,
  //               color: Colors.teal,
  //             ),
  //             SizedBox(
  //               width: 10,
  //             ),
  //             Text(
  //               user.name,
  //               style: TextStyle(color: Colors.black),
  //             ),
  //           ],
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

  void getTables(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (_) {
          return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              width: MediaQuery.of(context).size.height * 0.65,
              child: tables.isNotEmpty
                  ? GridView.count(
                      crossAxisCount: 10,
                      padding: const EdgeInsets.all(4.0),
                      children: tables.map((table) {
                        return Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: InkWell(
                            onTap: () {
                              Vibration.vibrate(duration: 150, amplitude: 1);
                              setState(() {
                                selectedTable = table;
                                guestController.text = selectedTable!.capacity;
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.teal,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              child: Column(children: [
                                const SizedBox(height: 10),
                                const Padding(
                                    padding: EdgeInsets.all(6.0),
                                    child: Icon(
                                      Icons.table_chart_outlined,
                                      color: Colors.white,
                                    )),
                                Padding(
                                  padding: const EdgeInsets.all(1.0),
                                  child: Text(
                                    table.name.toString(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        );
                      }).toList())
                  : const Center(child: CircularProgressIndicator()));
        });
  }
}
