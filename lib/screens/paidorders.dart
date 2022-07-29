

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import 'package:restro_ms_bakery/controller/urlController.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';


import 'package:restro_ms_bakery/controller/initPrinter.dart';

class PaidOrders extends StatefulWidget {
  PaidOrders({Key? key, this.data}) : super(key: key);

  final data;

  @override
  _PaidOrdersState createState() => _PaidOrdersState();
}

class _PaidOrdersState extends State<PaidOrders> {
  List? orders = [];
  int count = 0;

  // final url = "${baseUrl}api/";

  Future<String> getOrderData() async {
    print('object');
    final urlController = Provider.of<UrlController>(context, listen: false);
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var baseUrl = prefs.getString('baseUrl');
    var id = prefs.get("userid");
    var paidedUrl = urlController.getUrlValue == 0
        ? "$baseUrl/api/tableOrders/getPaidOrders/$id"
        : urlController.getUrlValue == 1
            ? "$baseUrl/api/twOrders/getPaidOrders/$id"
            : "$baseUrl/api/hdOrders/getPaidOrders/$id";
    final response = await http.get(Uri.parse(paidedUrl));

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

  @override
  void initState() {
    getOrderData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final urlController = Provider.of<UrlController>(context, listen: false);
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return Scaffold(
      body: count == 0
          ? Center(
              child: Center(
                child: Text("No Orders Yet!"),
              ),
            )
          : ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Paid Orders : " + count.toString(),
                    style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  physics: ScrollPhysics(),
                  crossAxisCount: 7,
                  children: orders!.map((data) {
                    return Card(
                      color: Colors.green,
                      child: InkWell(
                        onLongPress: () async {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          final urlController = Provider.of<UrlController>(
                              context,
                              listen: false);
                          var baseUrl = prefs.getString('baseUrl');
                          var userId = prefs.get("userid");
                          Fluttertoast.showToast(
                              msg: 'Requesting Print',
                              toastLength: Toast.LENGTH_LONG);

                          var urlPrintData = urlController.getUrlValue == 0
                              ? '$baseUrl/api/tableOrders/printBill/$userId/${data['id']}'
                              : urlController.getUrlValue == 1
                                  ? '$baseUrl/api/twOrders/printBill/$userId/${data['id']}'
                                  : '$baseUrl/api/hdOrders/printBill/$userId/${data['id']}';

                          var res = await http.get(Uri.parse(urlPrintData));
                        print(res.statusCode);
                          if (res.statusCode == 200) {
                            var datas = jsonDecode(res.body)['data'];
                            print(datas);
                            
                            //     datas,
                            //     data['id'],
                            //     context,
                            //     urlController.urlValue,
                            //     data['settled_time']);
                            // if (result) {
                            //   Fluttertoast.showToast(
                            //       msg: 'Successfully Printed',
                            //       toastLength: Toast.LENGTH_LONG);
                            // } else {
                            //   Fluttertoast.showToast(
                            //       msg: 'Print isnot Connected',
                            //       toastLength: Toast.LENGTH_LONG);
                            // }
                          
                          
                          } else {
                            Fluttertoast.showToast(
                                msg: 'unAvaible to Connected',
                                toastLength: Toast.LENGTH_LONG);
                          }
                        },
                        onTap: () {
                          Fluttertoast.showToast(
                              msg: "Bill already paid",
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.CENTER,
                              textColor: Colors.white,
                              backgroundColor: Colors.green);
                        },
                        child: Center(
                          child: Container(
                            margin: EdgeInsets.only(top: 5.0),
                            child: Column(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Container(
                                    width: 40.0,
                                    child: Image.asset(
                                      "assets/table.png",
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Text(
                                  urlController.getUrlValue == 0
                                      ? data['table_name']
                                      : data['token_no'].toString(),
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    data['settled_time'],
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 13),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 5),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Card(
                                      color: Colors.lightGreen,
                                      elevation: 0,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "Rs. " + data['net_amount'],
                                          style: TextStyle(
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
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}

Future<bool> printingOrder(
    orderData, orderId, context, int? urlController, settedTime) async {
  final printerControllers =
      Provider.of<PrinterIpAddressController>(context, listen: false);
  const PaperSize paper = PaperSize.mm80;
  final profile = await CapabilityProfile.load();
  final printer = NetworkPrinter(paper, profile);
  var grossAmount = double.parse(orderData['gross_amount']);
  var vatAmount = ((grossAmount * 13) / 100);
  final PosPrintResult res = await printer.connect(
      printerControllers.getPrinterIpAddress,
      port: printerControllers.printerPort!);

  if (res == PosPrintResult.success) {
    var companyInfo = printerControllers.getCompanyInfo;
    if (urlController == 2) {
      printingBillForHD(printer, orderData, vatAmount, orderId, companyInfo,
          urlController, settedTime);
    } else {
      printingBill(printer, orderData, vatAmount, orderId, companyInfo,
          urlController, settedTime);
    }
    printer.disconnect();
    return true;
  } else {
    //  printer.disconnect();
    return false;
  }
}

printingBill(NetworkPrinter printer, data, vatAmount, orderId, companyInfo,
    urlController, settedTime) {
  printer.text(companyInfo['company_name'].toString(),
      styles: const PosStyles(align: PosAlign.center));
  printer.text(companyInfo['address'],
      styles: const PosStyles(align: PosAlign.center));
  printer.text('Phone No: ${companyInfo['phone']}',
      styles: const PosStyles(align: PosAlign.center));
  companyInfo['bill_type'] == 'VAT'
      ? printer.text('VAT: ${companyInfo['pan_vat_no']}',
          styles: const PosStyles(align: PosAlign.center))
      : printer.text('PAN: ${companyInfo['pan_vat_no']}',
          styles: const PosStyles(align: PosAlign.center));
  printer.text('');
  if (urlController != 0) {
    printer.text('Ref.code       : ${data['ref_code']}',
        styles: const PosStyles(bold: true));
  }
  printer.text('BillNumber     : ${data['bill_no']}');
  if (urlController == 0) {
    printer.text('TableName      : ${(data['table_name']).toString()}');
  }
  if (urlController == 1 && data['tw_name'] != '') {
    printer.text('T/W Name       : ${data['tw_name'].toString()}');
  }
  printer.text('Transaction    : $settedTime');
  printer.text('Payment Method : ${data['payment_method']}');
  printer.text('------------------------------------------------');
  printer.row([
    PosColumn(
        text: 'Sn',
        width: 1,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: 'Particulars',
        width: 5,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: 'Qty  ',
        width: 1,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: 'Rate',
        width: 2,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: 'Amount',
        width: 3,
        styles: const PosStyles(
          height: PosTextSize.size1,
        )),
  ]);
  printer.text('------------------------------------------------');
  var datas =
      urlController == 0 ? data['order_items'] : data['take_away_items'];

  for (int i = 0; i < datas.length; i++) {
    printer.row([
      PosColumn(
          text: (i + 1).toString(),
          width: 1,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontB)),
      PosColumn(
          text: '${(datas[i]['name'])}',
          width: 5,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontB)),
      PosColumn(
          text: (datas[i]['quantity'].toString()),
          width: 1,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontB)),
      PosColumn(
          text: (datas[i]['rate']).toString(),
          width: 2,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontB)),
      PosColumn(
          text: (double.parse(datas[i]['rate']) *
                  double.parse(datas[i]['quantity']))
              .toString(),
          width: 3,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontB)),
    ]);
  }
  printer.text(' ', styles: const PosStyles(fontType: PosFontType.fontA));

  // printer.text('Total:${data.totalAmount.toString()}',
  //     styles: PosStyles(align: PosAlign.right));
  printer.row([
    PosColumn(
      text: '',
      width: 5,
    ),
    PosColumn(
      text: '-------------------------',
      width: 7,
    ),
  ]);
  printer.row([
    PosColumn(
      text: '',
      width: 5,
      styles: const PosStyles(
        align: PosAlign.center,
        underline: true,
      ),
    ),
    PosColumn(
      text: 'Gross Amt: Rs.${data['gross_amount'].toString()}',
      width: 7,
    ),
  ]);
  printer.row([
    PosColumn(
      text: '',
      width: 5,
    ),
    PosColumn(
      text: 'Discount Amt: Rs.${data['discount'].toString()}',
      width: 7,
    ),
  ]);
  printer.row([
    PosColumn(
      text: '',
      width: 5,
    ),
    PosColumn(
      text: '-------------------------',
      width: 7,
    ),
  ]);
  printer.row([
    PosColumn(
      text: '',
      width: 5,
    ),
    PosColumn(
      text: 'Net Amt: Rs.${data['net_amount'].toString()}',
      width: 7,
    ),
  ]);
  // printer.text('In Words: ${NumberToWord().convert('en-in', int.tryParse(data['net_amount']))}');
  printer.text('------------------------------------------------');
  printer.text('Thank You for visit',
      styles: const PosStyles(align: PosAlign.center));
  printer.text('Visit again soon.......',
      styles: const PosStyles(align: PosAlign.center));
  printer.text('------------------------------------------------');

  // printer.text('....................',
  //     styles: PosStyles(align: PosAlign.center));
  // printer.text('Verified By', styles: PosStyles(align: PosAlign.center));
  // printer.text('NCT PTV.LTD',styles: PosStyles(height:PosTextSize.decSize(height, width)));
  printer.beep(n: 1);
  printer.feed(2);
  printer.cut(mode: PosCutMode.full);
}

printingBillForHD(NetworkPrinter printer, data, vatAmount, orderId, companyInfo,
    urlController, settedTime) {
  printer.text(companyInfo['company_name'].toString(),
      styles: const PosStyles(align: PosAlign.center));
  printer.text(companyInfo['address'],
      styles: const PosStyles(align: PosAlign.center));
  printer.text('Phone No: ${companyInfo['phone']}',
      styles: const PosStyles(align: PosAlign.center));
  companyInfo['bill_type'] == 'VAT'
      ? printer.text('VAT: ${companyInfo['pan_vat_no']}',
          styles: const PosStyles(align: PosAlign.center))
      : printer.text('PAN: ${companyInfo['pan_vat_no']}',
          styles: const PosStyles(align: PosAlign.center));
  printer.text('');
  printer.text('Ref.code       : ${data['ref_code']}',
      styles: const PosStyles(bold: true));
  printer.text('BillNumber     : ${data['bill_no']}');
  printer.text('Customer Name  : ${data['customer_name']}');
  printer.text('Transaction    : $settedTime');
  printer.text('Payment Method : ${data['payment_method']}');
  printer.text('------------------------------------------------');
  printer.row([
    PosColumn(
        text: 'Sn',
        width: 1,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: 'Particulars',
        width: 5,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: 'Qty  ',
        width: 1,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: 'Rate',
        width: 2,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: 'Amount',
        width: 3,
        styles: const PosStyles(
          height: PosTextSize.size1,
        )),
  ]);
  printer.text('------------------------------------------------');
  var datas = data['home_delivery_items'];

  for (int i = 0; i < datas.length; i++) {
    printer.row([
      PosColumn(
          text: (i + 1).toString(),
          width: 1,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontB)),
      PosColumn(
          text: '${(datas[i]['name'])}',
          width: 5,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontB)),
      PosColumn(
          text: (datas[i]['quantity'].toString()),
          width: 1,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontB)),
      PosColumn(
          text: (datas[i]['rate']).toString(),
          width: 2,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontB)),
      PosColumn(
          text: (double.parse(datas[i]['rate']) *
                  double.parse(datas[i]['quantity']))
              .toString(),
          width: 3,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontB)),
    ]);
  }
  printer.text(' ', styles: const PosStyles(fontType: PosFontType.fontA));

  // printer.text('Total:${data.totalAmount.toString()}',
  //     styles: PosStyles(align: PosAlign.right));
  printer.row([
    PosColumn(
      text: '',
      width: 5,
    ),
    PosColumn(
      text: '-------------------------',
      width: 7,
    ),
  ]);
  printer.row([
    PosColumn(
      text: '',
      width: 5,
      styles: const PosStyles(
        align: PosAlign.center,
        underline: true,
      ),
    ),
    PosColumn(
      text: 'Gross Amt: Rs.${data['gross_amount'].toString()}',
      width: 7,
    ),
  ]);
  printer.row([
    PosColumn(
      text: '',
      width: 5,
    ),
    PosColumn(
      text: 'Discount Amt: Rs.${data['discount'].toString()}',
      width: 7,
    ),
  ]);
  printer.row([
    PosColumn(
      text: '',
      width: 5,
    ),
    PosColumn(
      text: '-------------------------',
      width: 7,
    ),
  ]);
  printer.row([
    PosColumn(
      text: '',
      width: 5,
    ),
    PosColumn(
      text: 'Net Amt: Rs.${data['net_amount'].toString()}',
      width: 7,
    ),
  ]);
  // printer.text('In Words: ${NumberToWord().convert('en-in', int.tryParse(data['net_amount']))}');
  printer.text('------------------------------------------------');
  printer.text('Thank You for visit',
      styles: const PosStyles(align: PosAlign.center));
  printer.text('Visit again soon.......',
      styles: const PosStyles(align: PosAlign.center));
  printer.text('------------------------------------------------');

  // printer.text('....................',
  //     styles: PosStyles(align: PosAlign.center));
  // printer.text('Verified By', styles: PosStyles(align: PosAlign.center));
  // printer.text('NCT PTV.LTD',styles: PosStyles(height:PosTextSize.decSize(height, width)));
  printer.beep(n: 1);
  printer.feed(2);
  printer.cut(mode: PosCutMode.full);
}
