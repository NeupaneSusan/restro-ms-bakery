import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:restro_ms_bakery/models/cashout.dart';
import 'package:restro_ms_bakery/screens/alertPage/cashout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CashoutView extends StatelessWidget {
  const CashoutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: FutureBuilder<List<Cashout>>(
          future: getCashout(),
          builder: ((context, snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return ListView(
                padding: const EdgeInsets.only(top: 10.0),
                children: [
                  const Center(
                      child: Text(
                    'Cash Out List',
                    style: TextStyle(
                        fontSize: 18.0,
                        color: Color(0xffCC471B),
                        fontWeight: FontWeight.w500),
                  )),
                  DataTable(
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Text(
                          'S.N',
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Particulars',
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Amount',
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Date&Time',
                        ),
                      ),
                    ],
                    rows: snapshot
                        .data! // Loops through dataColumnText, each iteration assigning the value to element
                        .map(
                          ((element) => DataRow(
                                cells: <DataCell>[
                                  DataCell(Text(
                                      (snapshot.data!.indexOf(element) + 1)
                                          .toString())),
                                  DataCell(Text(element
                                      .title!)), //Extracting from Map element the value
                                  DataCell(Text(element.amount!)),
                                  DataCell(Text(element.dateTime!)),
                                ],
                              )),
                        )
                        .toList(),
                  ),
                ],
              );

              //  Expanded(
              //    child:
              //
              // ListView.builder(
              //      itemCount: snapshot.data!.length,
              //      itemBuilder: ((context, index) {
              //        var data = snapshot.data![index];
              //      return Padding(
              //        padding: const EdgeInsets.only(left:8.0,right: 8.0),
              //        child: Card(child: Padding(
              //          padding: const EdgeInsets.all(8.0),
              //          child: Column(
              //            crossAxisAlignment: CrossAxisAlignment.start,
              //            children: [
              //             Row(
              //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //               children: [
              //                 Text("${data.dateTime}"),
              //                 Text("${data.title}"),
              //                 Text('${data.cashoutCategoryName}')

              //               ],

              //             ),
              //             Text('${data.description}'),
              //             Align(
              //               alignment: Alignment.topRight,
              //               child: Text('Rs.${data.amount}'),
              //             )
              //          ],),
              //        ),),
              //      );
              //    })),
              //  ),

            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          })),
    );
  }

  Future<List<Cashout>> getCashout() async {
    List<Cashout> cashoutList = [];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      var baseUrl = prefs.getString('baseUrl');
      var url = Uri.parse("$baseUrl/api/cashOuts");

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        cashoutList =
            data.map<Cashout>((json) => Cashout.fromJson(json)).toList();
      }
    } catch (err) {
      print(err);
    }
    return cashoutList.reversed.toList();
  }
}
