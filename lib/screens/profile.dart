import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:restro_ms_bakery/main.dart';
import 'package:restro_ms_bakery/models/floor.dart';

import 'package:restro_ms_bakery/screens/alertPage/cashout.dart';
import 'package:restro_ms_bakery/screens/alertPage/cashoutview.dart';
import 'package:restro_ms_bakery/screens/alertPage/dayclose.dart';
import 'package:restro_ms_bakery/screens/alertPage/swiptable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  ProfileScreen({Key? key, this.data}) : super(key: key);
  final data;
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;

  List<Floor> floor = [];
  var floorId;
  getFloorId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var floorid = prefs.getString('floorId');

    setState(() {
      floorId = floorid;
    });
  }

  Future fetchFloor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var baseUrl = prefs.getString('baseUrl');
    final url = Uri.parse("$baseUrl/api/floors");
    List<Floor> cats = [];
    var res = await http.get(url);
    if (res.statusCode == 200) {
      var jsonData = jsonDecode(res.body)['data'];
      for (var data in jsonData) {
        cats.add(Floor.fromJson(data));
      }
      if (mounted) {
        setState(() {
          floor = cats;
        });
      }

      return 'success';
    } else {
      throw "Can't get floor";
    }
  }

  changeFloor(id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString('userid');
    var baseUrl = prefs.getString('baseUrl');
    Map<String, String> header = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };

    final changeFloorUrl = Uri.parse('$baseUrl/api/floors/switch');
    var body = jsonEncode(<String, dynamic>{"floor_id": id, "user_id": userId});
    var response = await http.post(changeFloorUrl, headers: header, body: body);

    if (response.statusCode == 200) {
      prefs.remove('floorId');
      setState(() {
        prefs.setString('floorId', id.toString());
        floorId = id;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFloor();
    getFloorId();
  }

  bool isOpen = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            // crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 180,
                          child: ElevatedButton(
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.money_rounded),
                                  Text('Cash Out')
                                ]),
                            style: ElevatedButton.styleFrom(
                              primary: const Color(0xffCC471B),
                            ),
                            onPressed: () {
                              setState(() {
                                isOpen = !isOpen;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 180,
                      child: ElevatedButton(
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.swap_horiz_sharp),
                              Text('Swipe Table')
                            ]),
                        style: ElevatedButton.styleFrom(
                          primary: const Color(0xffCC471B),
                        ),
                        onPressed: () {
                          showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) {
                                return const SwipTable();
                              });
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 180,
                      child: ElevatedButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.lock),
                            Text("Day Close"),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: const Color(0xffCC471B),
                        ),
                        onPressed: () {
                          showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) {
                                return const DayClosePage();
                              });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left:5.0),
                        child: AnimatedContainer(
                          width: 170.0,
                          height: isOpen ? 100.0 : 0.0,
                          duration: Duration(seconds: 1),
                          curve: Curves.fastOutSlowIn,
                          child: Card(
                            elevation: 5.0,
                            margin: EdgeInsets.zero,
                              child: ListView(
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                    primary: const Color(0xffCC471B),
                                ),
                                onPressed: () {
                                  setState(() {
                                    isOpen = false;
                                  });
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return const CashoutView();
                                      });
                                },
                                icon: Icon(Icons.visibility_sharp),
                                label: Text('Cash Out View'),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                    primary: const Color(0xffCC471B),
                                ),
                                onPressed: () {
                                  setState(() {
                                    isOpen = false;
                                  });
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return const CashOutAddPage();
                                      });
                                },
                                icon: Icon(Icons.add),
                                label: Text('Cash Out Add'),
                              )
                            ],
                          )),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 60,),
                    Flexible(
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            child: Icon(
                              Icons.person,
                              size: 30,
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Text(
                            "${widget.data['display_name']}",
                            style: const TextStyle(
                                fontSize: 20.0, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(
                            height: 50,
                          ),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Switch the Floor',
                                    style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Icon(Icons.swap_vert_outlined)
                                ],
                              ),
                              const SizedBox(
                                height: 15.0,
                              ),
                              Container(
                                margin: const EdgeInsets.all(8.0),
                                height: 70.0,
                                child: Center(
                                  child: floor.isNotEmpty
                                      ? ListView.builder(
                                          shrinkWrap: true,
                                          scrollDirection: Axis.horizontal,
                                          itemCount: floor.length,
                                          itemBuilder: (context, int i) {
                                            return InkWell(
                                              onTap: () {
                                                if (floorId != floor[i].id) {
                                                  changeFloor(floor[i].id);
                                                  setState(() {
                                                    isLoading = true;
                                                  });
                                                }
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: Container(
                                                    height: 20.0,
                                                    width: 75.0,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                5.0),
                                                        color: floorId ==
                                                                floor[i].id
                                                            ? Color(0xffCC471B)
                                                                .withOpacity(0.8)
                                                            : Colors.grey,
                                                        border: Border.all(
                                                            width: 2,
                                                            color: floorId ==
                                                                    floor[i].id
                                                                ? Colors.green
                                                                : Colors.white)),
                                                    child: Center(
                                                        child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              7.0),
                                                      child: Text(
                                                        floor[i].name!,
                                                        style: const TextStyle(
                                                            fontSize: 13.0,
                                                            color: Colors.white),
                                                      ),
                                                    ))),
                                              ),
                                            );
                                          })
                                      : Container(
                                          height: 70,
                                        ),
                                ),
                              ),
                              const SizedBox(
                                height: 50,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 200,
                                  height: 40,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      primary: const Color(0xffCC471B),
                                    ),
                                    child: const Text(
                                      "Logout",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title:
                                                const Text("You want to logout?"),
                                            content: const Text("Are you sure?"),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text("Yes"),
                                                onPressed: () async {
                                                  SharedPreferences
                                                      sharedPreferences =
                                                      await SharedPreferences
                                                          .getInstance();
                                                  sharedPreferences
                                                      .remove('isLogin');
                                                  sharedPreferences
                                                      .remove('userid');
                                                  sharedPreferences
                                                      .remove('user');
                                                  Navigator.of(context)
                                                      .pushAndRemoveUntil(
                                                          MaterialPageRoute(
                                                              builder:
                                                                  (context) =>
                                                                      MyApp()),
                                                          (Route<dynamic>
                                                                  route) =>
                                                              false);
                                                },
                                              ),
                                              TextButton(
                                                child: const Text("Cancel"),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    Expanded(child: Text(''))
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
