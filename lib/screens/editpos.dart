import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:restro_ms_bakery/controller/CartController.dart';
import 'package:restro_ms_bakery/controller/printController.dart';
import 'package:restro_ms_bakery/controller/urlController.dart';
import 'package:restro_ms_bakery/screens/homescreen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../models/Category.dart';
import '../models/Product.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class EditPosScreen extends StatefulWidget {
  const EditPosScreen({Key? key, this.data, this.orderId, this.urlController})
      : super(key: key);

  // ignore: prefer_typing_uninitialized_variables
  final data, orderId;
  final int? urlController;

  @override
  _EditPosScreenState createState() => _EditPosScreenState();
}

class _EditPosScreenState extends State<EditPosScreen> {
  TextEditingController guestController = TextEditingController();
  TextEditingController remarksController = TextEditingController();
  TextEditingController filterController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Category> categories = <Category>[];
  List<Product> products = <Product>[];
  final List<Product> _searchResult = <Product>[];

  Category? selectedCategory;

  int _isButtonDisabled = 1;
//  final url = "http://d163f8b8ae8d.ngrok.io/restroms/api";
  // final url = "${baseUrl}api";
  // ignore: unnecessary_string_interpolations
  // final imgUrl = "$baseUrl";

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
  // void showToast(String msg, {int duration, int gravity}) {
  //   Fluttertoast.showToast(msg:msg,  toastLength: duration, gravity: gravity);
  // }

  //fetch products
  Future<String> fetchProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var baseUrl = prefs.getString('baseUrl');
    var floorid = prefs.getString('floorId');
    var productUrl = Uri.parse('$baseUrl/api/products/$floorid');
    var res = await http.get(productUrl);
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
  }

// toast
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
    var categoryUrl =
        Uri.parse('$baseUrl/api/products/getProductByCategory/' + id);
    var res = await http.get(categoryUrl);
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
  }

  // ignore: prefer_typing_uninitialized_variables
  var oldOrder;
  List<dynamic>? oldOrderItems;
  double discount = 0.0;

  Future<String> fetchOrder(userId, orderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var baseUrl = prefs.getString('baseUrl');
    CartController model = Provider.of<CartController>(context, listen: false);
    model.clear();
    var editUrl = widget.urlController == 0
        ? "$baseUrl/api/tableOrders/edit/$userId/$orderId"
        : widget.urlController == 1
            ? "$baseUrl/api/twOrders/edit/$userId/$orderId"
            : '$baseUrl/api/hdOrders/edit/$userId/$orderId';

    var res = await http.get(Uri.parse(editUrl));

    if (res.statusCode == 200) {
      var jsonData = json.decode(res.body);

      setState(() {
        oldOrder = jsonData['data'];
        oldOrderItems = widget.urlController == 0
            ? oldOrder['order_items']
            : widget.urlController == 1
                ? oldOrder['take_away_items']
                : oldOrder['home_deliveries_items'];
        guestController.text =
            widget.urlController == 0 ? oldOrder['no_of_guest'] : '0';
        discount = double.parse(jsonData['data']['discount']);
        _isButtonDisabled = 0;
      });

      for (var order in oldOrderItems!) {
        Provider.of<CartController>(context, listen: false).addOldItem(
            order['product_id'],
            order['name'],
            double.parse(order['rate']),
            int.parse(order['product_store_id']),
            int.parse(order['qty']));
      }

      return 'success';
    } else {
      throw "Can't get products.";
    }
  }

  // post address
  // ignore: missing_return
  Future<bool> checkout({var body, cart}) async {
    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();

      var baseUrl = preferences.getString('baseUrl');
      var userid = preferences.get('userid');

      setState(() {
        _isButtonDisabled = 1;
      });

      Map<String, String> header = {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      };
      var updateOrderUrl = widget.urlController == 0
          ? '$baseUrl/api/tableOrders/$userid/${oldOrder['id']}'
          : widget.urlController == 1
              ? '$baseUrl/api/twOrders/$userid/${oldOrder['id']}'
              : '$baseUrl/api/hdOrders/$userid/${oldOrder['id']}';
      var res = await http.put(
        Uri.parse(updateOrderUrl),
        headers: header,
        body: body,
      );

      if (res.statusCode == 200) {
        setState(() {
          _isButtonDisabled = 0;
        });
        toast("Order Updated Successfully", Colors.green);
        cart.clear();
        guestController.text = 0.toString();
        var data = jsonDecode(res.body)['data'];
        Navigator.of(context).pop(true);
        Navigator.of(context);
        print(data);
        var check = widget.urlController == 0
            ? await printingOrderReceipt(data, context, true)
            : widget.urlController == 1
                ? await printingTokenTw(data, context, true)
                : await printingHomeDeliveryOrderReceipt(data, context, true);

        if (check) {
          toast('Printing', Colors.blue);
        } else {
          toast('Unable to print', Colors.red);
        }

        return true;
      } else if (res.statusCode == 406) {
        var message = json.decode(res.body)['message'];
        toast(message, Colors.green);
        setState(() {
          _isButtonDisabled = 0;
        });
        return false;
      } else if (res.statusCode == 401) {
        var message = json.decode(res.body)['message'];
        toast(message, Colors.orange);

        setState(() {
          _isButtonDisabled = 0;
        });
        return false;
      } else if (res.statusCode == 503) {
        var message = json.decode(res.body)['message'];
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Text(message),
                actions: <Widget>[
                  const SizedBox(width: 20.0),
                  // ignore: deprecated_member_use
                  FlatButton(
                      child: const Text("Close"),
                      onPressed: () {
                        Navigator.of(context).pop();
                        cart.clear();
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return HomeScreen();
                        }));
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

        toast("Update failed", Colors.red);

        return false;
      }
    } catch (eror) {
      return false;
    }
    // print(res.statusCode);
  }

  // check internet
  internetChecker() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      const EditPosScreen();
    } else {
      Scaffold(
        key: _scaffoldKey,
        body: const Center(
          child: Text("No Internet Connection"),
        ),
      );
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

  @override
  void initState() {
    fetchProducts();
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      fetchOrder(widget.data['id'], widget.orderId);
    });
  }

  checkIsnew(check) {
    check.forEach((element) {
      if (element['is_new'] == 1) {
        return true;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final urlController = Provider.of<UrlController>(context, listen: false);
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return WillPopScope(
      onWillPop: () async => false,
      child: Consumer<CartController>(builder: (context, cart, child) {
        return Scaffold(
          key: _scaffoldKey,
          body: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: SafeArea(
                child: Container(
              margin:
                  const EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 0),
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

                                        Container(
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
                                                  child: Text(
                                                oldOrder != null
                                                    ? urlController
                                                                .getUrlValue ==
                                                            0
                                                        ? oldOrder['table_name']
                                                        : urlController
                                                                    .getUrlValue ==
                                                                1
                                                            ? oldOrder[
                                                                'token_no']
                                                            : oldOrder['hd_no']
                                                    : "",
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              )),
                                            )),

                                        const SizedBox(width: 10),
                                        Container(
                                          height: 35,
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey)),
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
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.41,
                                          decoration: BoxDecoration(
                                              color: Colors.white30,
                                              border: Border.all(
                                                  color: Colors.grey)),
                                          child: TextFormField(
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
                                            width: 130,
                                            child: Text(
                                              'Item Name',
                                              style: TextStyle(
                                                  color: Colors.white),
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
                                            width: 60,
                                            child: Text(
                                              'Price',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 70,
                                            child: Center(
                                              child: Text(
                                                'Amount',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 20,
                                            child: Text(
                                              'X',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ]),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        border: Border.all(
                                            color: Colors.teal[100]!)),
                                    width:
                                        MediaQuery.of(context).size.width * 0.6,
                                    child: ListView(
                                      children: [
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.6,
                                          child: Padding(
                                            padding: const EdgeInsets.all(1.0),
                                            child: ListView.builder(
                                              scrollDirection: Axis.vertical,
                                              itemCount: cart.items.length,
                                              itemBuilder:
                                                  (BuildContext context,
                                                          int i) =>
                                                      Card(
                                                elevation: 1,
                                                color: cart.items.values
                                                            .toList()[cart.items
                                                                    .length -
                                                                i -
                                                                1]
                                                            .isNew ==
                                                        1
                                                    ? Colors.orange
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
                                                              color: Colors
                                                                  .white38,
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
                                                                      Vibration.vibrate(
                                                                          duration:
                                                                              150,
                                                                          amplitude:
                                                                              1);
                                                                      FlutterBeep
                                                                          .beep();
                                                                      if (cart.items
                                                                              .values
                                                                              .toList()[cart.items.length -
                                                                                  i -
                                                                                  1]
                                                                              .quantity! >
                                                                          cart.items
                                                                              .values
                                                                              .toList()[cart.items.length - i - 1]
                                                                              .oldQuantity!) {
                                                                        cart.removeEditSingleItem(cart
                                                                            .items
                                                                            .keys
                                                                            .toList()[cart
                                                                                .items.length -
                                                                            i -
                                                                            1]);
                                                                      }
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
                                                                Text(cart.items
                                                                    .values
                                                                    .toList()[cart
                                                                            .items
                                                                            .length -
                                                                        i -
                                                                        1]
                                                                    .quantity
                                                                    .toString()),
                                                                GestureDetector(
                                                                  onTap: () {
                                                                    Vibration.vibrate(
                                                                        duration:
                                                                            150,
                                                                        amplitude:
                                                                            1);
                                                                    FlutterBeep
                                                                        .beep();
                                                                    // playAudio();
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
                                                                          .storeId,
                                                                    );
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
                                                          margin:
                                                              EdgeInsets.zero,
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: 10.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Colors.white38,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          width: 100,
                                                          height: 35,
                                                          child: TextFormField(
                                                            readOnly: cart.items
                                                                        .values
                                                                        .toList()[cart.items.length -
                                                                            i -
                                                                            1]
                                                                        .oldQuantity ==
                                                                    0
                                                                ? false
                                                                : true,
                                                            decoration:
                                                                const InputDecoration(
                                                              contentPadding:
                                                                  EdgeInsets.only(
                                                                      bottom:
                                                                          10.0),
                                                              border:
                                                                  InputBorder
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
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                            width: 20,
                                                            child: cart.items
                                                                        .values
                                                                        .toList()[cart.items.length -
                                                                            i -
                                                                            1]
                                                                        .oldQuantity ==
                                                                    0
                                                                ? InkWell(
                                                                    onTap: () {
                                                                      Vibration.vibrate(
                                                                          duration:
                                                                              150,
                                                                          amplitude:
                                                                              1);
                                                                      FlutterBeep
                                                                          .beep();
                                                                      cart.removeItem(
                                                                        cart.items
                                                                            .keys
                                                                            .toList()[cart
                                                                                .items.length -
                                                                            i -
                                                                            1],
                                                                      );
                                                                    },
                                                                    child: const Icon(
                                                                        Icons
                                                                            .delete,
                                                                        color: Colors
                                                                            .red))
                                                                : InkWell(
                                                                    onTap: () {
                                                                      Vibration.vibrate(
                                                                          duration:
                                                                              150,
                                                                          amplitude:
                                                                              1);
                                                                      FlutterBeep
                                                                          .beep();
                                                                      cart.items
                                                                          .forEach((key,
                                                                              value) {});
                                                                    },
                                                                    child: const Icon(
                                                                        Icons
                                                                            .check,
                                                                        color: Colors
                                                                            .green))),
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
                              child: Column(
                                children: [
                                  Container(
                                    decoration:
                                        BoxDecoration(color: Colors.grey[200]),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Column(children: [
                                            const Text('Total Quantity'),
                                            Text(
                                                cart.totalItemsCount.toString())
                                          ]),
                                          Column(children: [
                                            const Text('Gross Amount'),
                                            Text(
                                                "Rs.${(cart.totalAmount).toStringAsFixed(2)}")
                                          ]),
                                          Column(children: [
                                            const Text('Discount Amount'),
                                            Text("Rs.${discount.toString()}")
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
                                                      height: 24,
                                                      child: TextFormField(
                                                        controller:
                                                            guestController,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        decoration:
                                                            const InputDecoration(
                                                                border:
                                                                    InputBorder
                                                                        .none),
                                                      ))
                                                ])
                                              : Container(),
                                          Column(children: [
                                            const Text('Net Amount'),
                                            Text("Rs." +
                                                (cart.totalAmount - (discount))
                                                    .toStringAsFixed(2))
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
                                              padding:
                                                  const EdgeInsets.all(6.0),
                                              // ignore: deprecated_member_use
                                              child: RaisedButton(
                                                color: Colors.redAccent,
                                                onPressed: () {
                                                  if (_isButtonDisabled == 0) {
                                                    cart.clear();
                                                    Navigator.pop(context);
                                                  }
                                                },
                                                child: const Text(
                                                  'Back',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(6.0),
                                              // ignore: deprecated_member_use
                                              child: RaisedButton(
                                                color: Colors.orange,
                                                onPressed: _isButtonDisabled ==
                                                        0
                                                    ? () {
                                                        Vibration.vibrate(
                                                            duration: 150,
                                                            amplitude: 1);

                                                        var cartItems = [];
                                                        cart.items
                                                            .forEach(
                                                                (key, value) =>
                                                                    {
                                                                      cartItems
                                                                          .add({
                                                                        'product_id':
                                                                            key,
                                                                        'quantity':
                                                                            value.quantity,
                                                                        'rate':
                                                                            value.rate,
                                                                        'amount':
                                                                            (value.quantity! * value.rate!).toStringAsFixed(2),
                                                                        'product_store_id':
                                                                            value.storeId,
                                                                        'plus_quantity':
                                                                            value.plusQuantity,
                                                                        'is_new':
                                                                            value.isNew ??
                                                                                0,
                                                                        'order_id':
                                                                            oldOrder['id']
                                                                      })
                                                                    });

                                                        bool found = cartItems
                                                            .any((element) =>
                                                                element[
                                                                    'is_new'] ==
                                                                1);
                                                        if (found == true) {
                                                          if (cartItems.any(
                                                              (element) =>
                                                                  element[
                                                                      'rate'] ==
                                                                  0.0)) {
                                                            toast(
                                                                'Please set the price ',
                                                                Colors.orange);
                                                          } else {
                                                            String body;
                                                            if (urlController
                                                                    .getUrlValue ==
                                                                0) {
                                                              body =
                                                                  jsonEncode(<
                                                                      String,
                                                                      dynamic>{
                                                                'order_items':
                                                                    cartItems,
                                                                'gross_amount': cart
                                                                    .totalAmount
                                                                    .toStringAsFixed(
                                                                        2),
                                                                'net_amount': (cart
                                                                            .totalAmount -
                                                                        discount)
                                                                    .toStringAsFixed(
                                                                        2),
                                                                'user_id':
                                                                    widget.data[
                                                                        'id'],
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
                                                                    oldOrder[
                                                                        'table_id'],
                                                              });
                                                              checkout(
                                                                  body: body,
                                                                  cart: cart);
                                                            } else if (urlController
                                                                    .getUrlValue ==
                                                                1) {
                                                              body =
                                                                  jsonEncode(<
                                                                      String,
                                                                      dynamic>{
                                                                'take_away_items':
                                                                    cartItems,
                                                                'gross_amount': cart
                                                                    .totalAmount
                                                                    .toStringAsFixed(
                                                                        2),
                                                                'net_amount': (cart
                                                                            .totalAmount -
                                                                        discount)
                                                                    .toStringAsFixed(
                                                                        2),
                                                                'user_id':
                                                                    widget.data[
                                                                        'id'],
                                                                'store_id': widget
                                                                        .data[
                                                                    'store_id'],
                                                                'remark':
                                                                    remarksController
                                                                        .text,
                                                              });

                                                              //print(body);

                                                              checkout(
                                                                  body: body,
                                                                  cart: cart);
                                                            } else {
                                                              body =
                                                                  jsonEncode(<
                                                                      String,
                                                                      dynamic>{
                                                                'home_delivery_items':
                                                                    cartItems,
                                                                'gross_amount': cart
                                                                    .totalAmount
                                                                    .toStringAsFixed(
                                                                        2),
                                                                'net_amount': (cart
                                                                            .totalAmount -
                                                                        discount)
                                                                    .toStringAsFixed(
                                                                        2),
                                                                'address':
                                                                    oldOrder[
                                                                        'address'],
                                                                'phone_no':
                                                                    oldOrder[
                                                                        'phone_no'],
                                                                'customer_name':
                                                                    oldOrder[
                                                                        'customer_name'],
                                                                'remark':
                                                                    remarksController
                                                                        .text,
                                                              });
                                                              checkout(
                                                                  body: body,
                                                                  cart: cart);
                                                            }
                                                          }
                                                        } else {
                                                          Fluttertoast.showToast(
                                                              msg:
                                                                  "No item added",
                                                              gravity:
                                                                  ToastGravity
                                                                      .CENTER);
                                                        }
                                                      }
                                                    : null,
                                                child: Text(
                                                  _isButtonDisabled == 1
                                                      ? "Hold on..."
                                                      : "Update Now",
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]),
                                  ),
                                ],
                              ),
                            )
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
                                top:
                                    BorderSide(color: Colors.orange, width: 5)),
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
                                        width: 5.0,
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
                                              style: TextStyle(
                                                  color: Colors.white),
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
                                height:
                                    MediaQuery.of(context).size.height * 0.85,
                                width:
                                    MediaQuery.of(context).size.height * 0.65,
                                child: _searchResult.length != 0 ||
                                        filterController.text.isNotEmpty
                                    ? GridView.count(
                                        crossAxisCount: 3,
                                        padding: const EdgeInsets.all(4.0),
                                        children: _searchResult.map((product) {
                                          return Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: InkWell(
                                              onTap: () {
                                                // playAudio();
                                                Vibration.vibrate(
                                                    duration: 150,
                                                    amplitude: 1);
                                                FlutterBeep.beep();
                                                cart.addItem(
                                                  product.id.toString(),
                                                  product.name.toString(),
                                                  double.parse(product.price),
                                                  int.parse(product.storeId),
                                                );
                                              },
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                    color: Color(0xFFcc471b),
                                                    borderRadius:
                                                        BorderRadius.only(
                                                            topRight:
                                                                Radius.circular(
                                                                    40),
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
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
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
                                                                ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            1.0),
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
                                                        const EdgeInsets.all(
                                                            1.0),
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
                                                    duration: 150,
                                                    amplitude: 1);
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
                                                            topRight:
                                                                Radius.circular(
                                                                    40),
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
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
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
                                                                ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            1.0),
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
                                                        const EdgeInsets.all(
                                                            1.0),
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
      }),
    );
  
  
  
  }
}


//   Widget getCategories(List<Category> categories) {
//     return DropdownButton<Category>(
//       icon: Container(
//           margin: EdgeInsets.only(left: 10),
//           alignment: Alignment.topRight,
//           child: Icon(Icons.arrow_drop_down)),
//       underline: Text(''),
//       iconSize: 20,
//       hint: Text("Select Category"),
//       value: selectedCategory,
//       onChanged: (Category val) {
//         setState(() {
//           selectedCategory = val;
//           fetchProductsByCategoryWise(val.id);
//         });
//       },
//       items: categories.map((Category user) {
//         return DropdownMenuItem<Category>(
//           value: user,
//           child: Row(
//             children: <Widget>[
//               Icon(
//                 Icons.restaurant_menu_sharp,
//                 size: 18,
//                 color: Colors.teal,
//               ),
//               SizedBox(
//                 width: 10,
//               ),
//               Text(
//                 user.name,
//                 style: TextStyle(color: Colors.black),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }

// }
