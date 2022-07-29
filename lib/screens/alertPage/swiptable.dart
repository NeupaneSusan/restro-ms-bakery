// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';


import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';

import 'package:restro_ms_bakery/models/Tables.dart';
import 'package:restro_ms_bakery/models/runningTable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SwipTable extends StatefulWidget {
  const SwipTable({Key? key}) : super(key: key);

  @override
  _SwipTableState createState() => _SwipTableState();
}

class _SwipTableState extends State<SwipTable> {
  List<Tables> availablecats = [];
  List<RunningtableModel> runningTable = [];

  String? runningValue;
  String? availableTable;
  // ignore: prefer_typing_uninitialized_variables
  var runningTableId;
  var availableTableId;
  bool isLoading = false;

  Future<List> availablefetchTables() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var baseUrl = prefs.getString('baseUrl');
    var floorId = prefs.getString('floorId');

    var tableUrl = Uri.parse('$baseUrl/api/tables/$floorId');
    var res = await http.get(tableUrl);

    if (res.statusCode == 200) {
      var jsonData = jsonDecode(res.body);

      availablecats = [];
      for (var data in jsonData['data']) {
        availablecats.add(Tables.fromJson(data));
      }
      return availablecats;
    } else if (res.statusCode == 204) {
      //  Navigator.pop(context);
      toast('No Table is Available', Colors.lightGreen);
      return availablecats;
    } else {
      throw "Can't get tables.";
    }
  }

  Future<List> fetchUnpaidTables() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var baseUrl = prefs.getString('baseUrl');
    var userId = prefs.getString('userid');

    var unpaidtableUrl =
        Uri.parse('$baseUrl/api/tableOrders/getUnPaidOrders/$userId');

    var res = await http.get(unpaidtableUrl);

    if (res.statusCode == 200) {
      var jsonData = jsonDecode(res.body);

      runningTable = [];
      for (var data in jsonData['data']) {
        runningTable.add(RunningtableModel.fromJson(data));
      }

      return runningTable;
    } else {
      throw "Can't get tables.";
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

  swipTable(setStates) async {
    setStates(() {
      isLoading = true;
    });

    SharedPreferences preferences = await SharedPreferences.getInstance();

    var baseUrl = preferences.getString('baseUrl');
    var userid = preferences.get('userid');

    var tableSwipeUrl = Uri.parse('$baseUrl/api/tableOrders/swipe/$userid');
    Map<String, String> header = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    var body = {
      "running_table_id": runningTableId,
      "available_table_id": availableTableId,
    };

    var response =
        await http.post(tableSwipeUrl, headers: header, body: jsonEncode(body));

    if (response.statusCode == 200) {
      var msg = jsonDecode(response.body)['data'];
      Navigator.pop(context);
      toast(msg['message'], Colors.green);
    } else {
      var msg = jsonDecode(response.body)['message'];

      toast(msg, Colors.orange);
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return !isLoading;
      },
      child: Dialog(
        child: SizedBox(
          height: 340,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Swipe Tables',
                    style:
                        TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                const Divider(
                  thickness: 1,
                ),
                const SizedBox(
                  height: 5.0,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 40,
                      color: Colors.orange,
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 50.0, vertical: 1.0),
                          child: Text(
                            'Running Tables',
                            style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 40,
                      color: const Color(0xffCC471B),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 50.0, vertical: 1.0),
                          child: Text(
                            'To',
                            style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 40,
                      color: Colors.green,
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 50.0, vertical: 1.0),
                          child: Text(
                            'Available Tables',
                            style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 50,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FutureBuilder(
                      future: fetchUnpaidTables(),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        return snapshot.hasData
                            ? Container(
                                height: 40,
                                width: 205,
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: StatefulBuilder(
                                      builder: (context, innState) {
                                    return DropdownButton<dynamic>(
                                      isExpanded: true,
                                      isDense: true,
                                      underline: const SizedBox(),
                                      hint: Text(
                                          runningValue ?? 'Select Customer'),
                                      items: snapshot.data
                                          .map<DropdownMenuItem<dynamic>>(
                                              (item) {
                                        return DropdownMenuItem<dynamic>(
                                          value: item,
                                          child: Text(item.tableName),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        innState(() {
                                          runningValue =
                                              value.tableName.toString();
                                          runningTableId = value.tableId;
                                        });
                                      },
                                    );
                                  }),
                                ),
                              )
                            : Container(
                                height: 40,
                                width: 205,
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: const [Text('Select Customer ')],
                                  ),
                                ));
                      },
                    ),
                    const SizedBox(
                      height: 40,
                      child: Center(
                        child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 50.0, vertical: 1.0),
                            child: Icon(Icons.swap_horizontal_circle)),
                      ),
                    ),
                    FutureBuilder(
                      future: availablefetchTables(),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        return snapshot.hasData
                            ? Container(
                                height: 40,
                                width: 205,
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: StatefulBuilder(
                                      builder: (context, innState) {
                                    return DropdownButton<dynamic>(
                                      isExpanded: true,
                                      isDense: true,
                                      underline: const SizedBox(),
                                      hint: Text(
                                          availableTable ?? 'Select Tables'),
                                      items: snapshot.data
                                          .map<DropdownMenuItem<dynamic>>(
                                              (item) {
                                        return DropdownMenuItem<dynamic>(
                                          value: item,
                                          child: Text(item.name),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        innState(() {
                                          availableTable =
                                              value.name.toString();
                                          availableTableId = value.id;
                                        });
                                      },
                                    );
                                  }),
                                ),
                              )
                            : Container(
                                height: 40,
                                width: 205,
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: const [Text('Select Tables')],
                                  ),
                                ));
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: StatefulBuilder(
                          builder: (context, StateSetter setStates) {
                        return SizedBox(
                          width: 180,
                          height: 45.0,
                          child: ElevatedButton(
                            child: !isLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                        Icon(Icons.swap_horiz_sharp),
                                        Text('Swap')
                                      ])
                                : const CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                            style: ElevatedButton.styleFrom(
                              primary: const Color(0xffCC471B),
                            ),
                            onPressed: () {
                              swipTable(setStates);
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
