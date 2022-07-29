import 'dart:typed_data';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/services.dart';

import 'package:image/image.dart';

import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import 'package:restro_ms_bakery/controller/initPrinter.dart';

import 'package:http/http.dart' as http;

String trime(name) {
  if (name.length >= 13) {
    String trimmedString = name.substring(0, 12);
    return trimmedString + '.';
  }
  return name.toString();
}

testReceipt(NetworkPrinter printer, data, vatAmount, orderId, companyInfo,
    urlController) {
  dynamic currentTime =
      DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
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
    printer.text('Ref.code    : ${data['ref_code']}',
        styles: const PosStyles(bold: true));
  }
  printer.text('BillNumber  : ${data['bill_no']}');
  if (urlController == 0) {
    printer.text('TableName   : ${(data['table_name']).toString()}');
  }
  if (urlController == 1 && data['tw_name'] != '') {
    printer.text('T/W Name   : ${data['tw_name'].toString()}');
  }
  printer.text('Transaction : ${currentTime.toString()}');
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

// ignore: missing_return
Future<bool> printingOrder(
    orderData, orderId, context, int? urlController) async {
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
    testReceipt(
        printer, orderData, vatAmount, orderId, companyInfo, urlController);
    printer.disconnect();
    return true;
  } else {
    //  printer.disconnect();
    return false;
  }
}

//////////////////////////////////////// Day Closing///////////////////////////////
Future<bool> printDayClosing(data, context) async {
  final printerControllers =
      Provider.of<PrinterIpAddressController>(context, listen: false);

  const PaperSize paper = PaperSize.mm80;
  final profile = await CapabilityProfile.load();
  final printer = NetworkPrinter(paper, profile);
  final PosPrintResult res = await printer.connect(
      printerControllers.printerIpAddress!,
      port: printerControllers.printerPort!);
  if (res == PosPrintResult.success) {
    printingDayClosing(printer, data);
    printClosingReport(printer, data);
    printCashCountsReport(printer, data);
    printer.disconnect();
    return true;
  } else {
    printer.disconnect();
    return false;
  }
}

printingDayClosing(printer, data) {
  dynamic currentTime =
      DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  var totalCount = data['total_cash_payment'] +
      data['total_fonepay_payment'] +
      data['total_fonepay_and_cash_payment'] +
      data['total_card_payment'] +
      data['total_credit_sales'];
  printer.text('--------------Cash Flow Details-----------------');
  printer.text('User      : ${data['day_opened_by']}');
  printer.text('Date Time : $currentTime');
  printer.text('');
  printer
      .text('Cash Payment         : ${data['total_cash_payment'].toString()}');
  printer.text(
      'Fonepay Payment      : ${data['total_fonepay_payment'].toString()}');
  printer.text(
      'Mf & Cash Payment    : ${data['total_fonepay_and_cash_payment'].toString()}');
  printer
      .text('Card Payment         : ${data['total_card_payment'].toString()}');
  printer
      .text('Credit Sales         : ${data['total_credit_sales'].toString()}');
  printer.text('------------------------------------------------');
  printer.text('Total                : ${totalCount.toString()}');
  printer.text('------------------------------------------------');
  printer.text('Discount Amount      : Rs.${data['total_discount_amount']}');
  printer.text('Cancel Amount        : Rs.${data['total_cancel_amount']}');
  printer.text('');
  printer.text('------------------------------------------------');
  printer.text('');
  printer.text('Total Cash Out       : Rs.${data['cash_out_amount']}');
  printer.text('Total Fonepay Amount : Rs.${data['system_fonepay_amount']}');
  printer.text('Total Card Amount    : Rs.${data['system_card_amount']}');
  printer.text('Total Credit Amount  : Rs.${data['total_credit_amount']}');
  printer.text('');
  printer.text('------------------------------------------------');
  printer.text('');
  printer.text('Opening Balance      : ${data['opening_balance']}');
  printer
      .text('Cash Received        : Rs.${data['total_cash_received_amount']}');
  printer.text(
      'Fonepay Received     : Rs.${data['total_fonepay_received_amount']}');
  printer
      .text('Card Received        : Rs.${data['total_card_received_amount']}');
  printer.text(
      'Cheque Received      : Rs.${data['total_cheque_received_amount']}');
  printer.text('Total Sale           : Rs.${data['sales_amount']}');
  printer.text('');
  printer.text('------------------------------------------------');
  printer.text('');
  printer.text('Total Amount         : Rs.${data['total_account_amount']}');
  printer.text('Total Expense        : Rs.${data['cash_out_amount']}');
  printer.text('');
  printer.text('------------------------------------------------');
  printer.text('');
  printer.text('Closing Amount       : Rs.${data['closing_amount']}');
  printer.text(
      'Fonepay & Card       : Rs.${data['system_fonepay_and_card_amount']}');
  printer.text(
      'Scan/POS Received    : Rs.${data['received_fonepay_card_cheque_amount']}');
  printer.text('Credit Amount        : Rs.${data['total_credit_amount']}');
  printer.text('');
  printer.text('------------------------------------------------');
  printer
      .text('Closing Cash Amount  : Rs.${data['total_closing_cash_amount']}');
  printer.text('------------------------------------------------');
  printer.text('');
  printer.text('');
  printer.text('....................',
      styles: const PosStyles(align: PosAlign.center));
  printer.text('Verified By', styles: const PosStyles(align: PosAlign.center));
  printer.beep(n: 1);
  printer.feed(2);
  printer.cut(mode: PosCutMode.full);
}

printClosingReport(printer, data) {
  dynamic currentTime =
      DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  printer.text('--------------Closing Report-----------------');

  printer.text('Day Opened By     : ${data['day_opened_by']}');
  printer.text('Opening Balance   : ${data['opening_balance']}');
  printer.text('Day Closed By     : ${data['day_closed_by']}');
  printer.text('Working Hour      : ${data['working_hour']}');
  printer.text('Table Orders      : ${data['total_t_orders']}');
  printer.text('HD Orders         : ${data['total_hd_orders']}');
  printer.text('T/W Orders        : ${data['total_tw_orders']}');
  printer.text('Total Orders      : ${data['total_orders']}');
  printer.text('Total Items       : ${data['total_items']}');
  printer.text('Close Date Time : ${currentTime.toString()}');
  printer.text('------------------------------------------------');
  printer.row([
    PosColumn(
        text: 'Sn',
        width: 1,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: 'Particulars',
        width: 8,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: '',
        width: 1,
        styles:
            const PosStyles(height: PosTextSize.size1, align: PosAlign.center)),
    PosColumn(
        text: 'Qty  ',
        width: 2,
        styles: const PosStyles(height: PosTextSize.size1)),
  ]);
  printer.text('------------------------------------------------');
  var itemsList = data['order_items'];
  for (int i = 0; i < itemsList.length; i++) {
    printer.row([
      PosColumn(
          text: (i + 1).toString(),
          width: 1,
          styles: const PosStyles(
            height: PosTextSize.size1,
          )),
      PosColumn(
          text: '${(itemsList[i]['name'])}',
          width: 8,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontB)),
      PosColumn(
          text: '',
          width: 1,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontA)),
      PosColumn(
          text: (itemsList[i]['quantity'].toString()),
          width: 2,
          styles: const PosStyles(height: PosTextSize.size1)),
    ]);
  }
  printer.text('');
  printer.text('------------------------------------------------');
  printer.row([
    PosColumn(
        text: '',
        width: 1,
        styles: const PosStyles(
          height: PosTextSize.size1,
        )),
    PosColumn(
        text: 'Total',
        width: 8,
        styles: const PosStyles(
          height: PosTextSize.size1,
        )),
    PosColumn(
        text: '',
        width: 1,
        styles: const PosStyles(
            height: PosTextSize.size1, fontType: PosFontType.fontA)),
    PosColumn(
        text: (data['total_quantity'].toString()),
        width: 2,
        styles: const PosStyles(height: PosTextSize.size1)),
  ]);
  printer.text('------------------------------------------------');
  printer.text('');
  printer.text('Cash Payment      : ${data['total_cash_payment']}');
  printer.text('Fonepay Payment   : ${data['total_fonepay_payment']}');
  printer.text('MF & Cash Payment : ${data['total_fonepay_and_cash_payment']}');
  printer.text('Card Payment      : ${data['total_card_payment']}');
  printer.text('Credit Sales      : ${data['total_credit_sales']}');
  printer.text('------------------------------------------------');
  printer.text('Total Discount    : Rs.${data['total_discount_amount']}');
  printer.text('Total Cancel      : Rs.${data['total_cancel_amount']}');
  printer.beep(n: 1);
  printer.feed(2);
  printer.cut(mode: PosCutMode.full);
}

printCashCountsReport(printer, data) {
  dynamic currentTime =
      DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());

  printer.text('--------------Cash Counter details--------------');

  printer.text('Cash Count By     : ${data['day_closed_by']}');
  printer.text('Close Date Time   : ${currentTime.toString()}');
  printer.text('------------------------------------------------');
  printer.row([
    PosColumn(
        text: 'Sn',
        width: 1,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: 'Money Notes',
        width: 5,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: '',
        width: 2,
        styles:
            const PosStyles(height: PosTextSize.size1, align: PosAlign.center)),
    PosColumn(
        text: 'Cash Count  ',
        width: 4,
        styles: const PosStyles(height: PosTextSize.size1)),
  ]);
  printer.text('------------------------------------------------');

  Map<String, dynamic> itemsList =
      Map<String, dynamic>.from(data['cash_counts']);
  int i = 0;
  for (String key in itemsList.keys) {
    i = i + 1;
    // ignore: unrelated_type_equality_checks
    if (key == 'total_amount') {
    } else {
      printer.row([
        PosColumn(
            text: (i).toString(),
            width: 1,
            styles: const PosStyles(
              height: PosTextSize.size1,
            )),
        PosColumn(
            text: key,
            width: 5,
            styles: const PosStyles(
                height: PosTextSize.size1, fontType: PosFontType.fontA)),
        PosColumn(
            text: '',
            width: 2,
            styles: const PosStyles(
                height: PosTextSize.size1, fontType: PosFontType.fontA)),
        PosColumn(
            text: '${itemsList[key]}',
            width: 4,
            styles: const PosStyles(height: PosTextSize.size1)),
      ]);
    }
  }

  printer.text('');
  printer.text('------------------------------------------------');
  printer.text('');
  printer.text('Included IC Amount(NPR) : Rs. ${data['total_ic_amount']}');
  printer.text('Total Cash Amount       : Rs. ${data['total_cash_amount']}');
  printer.text('');

  printer.text('Cash Amount    : Rs.${data['total_cash_amount']}');
  printer.text('Fonepay Amount : Rs.${data['fonepay_amount']}');
  printer.text('Card Amount    : Rs.${data['card_amount']}');
  printer.text('');
  printer.text('');
  printer.text('....................',
      styles: const PosStyles(align: PosAlign.center));
  printer.text('Verified By', styles: const PosStyles(align: PosAlign.center));
  printer.beep(n: 1);
  printer.feed(2);
  printer.cut(mode: PosCutMode.full);
}

///////////////////////////////////////////////////////////////////////
/////////////////////Printing KOT For TakeAWAYS/////////////////////////
Future<bool> printingTokenTw(data, context, isUpdate) async {
  final printerControllers =
      Provider.of<PrinterIpAddressController>(context, listen: false);
  var jsonData = (data[0]);
  var result = groupBy(jsonData['take_away_items']);
  const PaperSize paper = PaperSize.mm80;
  final profile = await CapabilityProfile.load();
  final printer = NetworkPrinter(paper, profile);
  final PosPrintResult res = await printer.connect(
      printerControllers.printerIpAddress!,
      port: printerControllers.printerPort!);
  if (res == PosPrintResult.success) {
    for (var a in result) {
      var storeName = (a['storeName']);
      var orderItem = (a['Data']);
      printingTokenForTA(printer, data, storeName, orderItem,
          printerControllers.companyInfo, isUpdate);
    }
    printingTokenForTAForUser(
        printer, data, printerControllers.companyInfo, isUpdate);

    printer.disconnect();
    return true;
  } else {
    printer.disconnect();
    return false;
  }
}

printingTokenForTA(printer, data, storeName, orderItem, companyInfo, isUpdate) {
  dynamic currentTime =
      DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  printer.text('');
  if (isUpdate) {
    printer.text('ADD',
        styles: const PosStyles(
          height: PosTextSize.size1,
          width: PosTextSize.size2,
          align: PosAlign.center,
          bold: true,
        ));
    printer.text('', styles: const PosStyles(fontType: PosFontType.fontA));
  }

  printer.text('');
  printer.text('-------------Take Away Token (TAT)--------------');
  printer.text('T/W No       : ${data[0]['token_no'].toString()}',
      styles: const PosStyles(bold: true));
  if (data[0]['tw_name'] != '') {
    printer.text('T/W Name     : ${data[0]['tw_name']}');
  }
  printer.text('Store Name   : $storeName',
      styles: const PosStyles(bold: true));

  printer.text('Date Time    : $currentTime');
  printer.text('------------------------------------------------');
  printer.row([
    PosColumn(
        text: 'Sn',
        width: 1,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: 'Particulars',
        width: 8,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: '',
        width: 1,
        styles:
            const PosStyles(height: PosTextSize.size1, align: PosAlign.center)),
    PosColumn(
        text: 'Qty  ',
        width: 2,
        styles: const PosStyles(height: PosTextSize.size1)),
  ]);
  printer.text('------------------------------------------------');

  for (int i = 0; i < orderItem.length; i++) {
    printer.row([
      PosColumn(
          text: (i + 1).toString(),
          width: 1,
          styles: const PosStyles(
            height: PosTextSize.size1,
          )),
      PosColumn(
          text: '${(orderItem[i]['name'])}',
          width: 8,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontA)),
      PosColumn(
          text: '',
          width: 1,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontA)),
      PosColumn(
          text: (orderItem[i]['quantity'].toString()),
          width: 2,
          styles: const PosStyles(height: PosTextSize.size1)),
    ]);
  }
  printer.text('');
  printer.text('Remark : ${data[0]['remark']}');
  // if (companyInfo['message'] != null) {

  //   printer.text(companyInfo['message'],
  //       styles: const PosStyles(align: PosAlign.center, bold: true));
  // }
  printer.text('');
  printer.beep(n: 1);
  printer.feed(2);
  printer.cut(mode: PosCutMode.full);
}

printingTokenForTAForUser(printer, data, companyInfo, isUpdate) {
  dynamic currentTime =
      DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  printer.text('');
  if (isUpdate) {
    printer.text('ADD',
        styles: const PosStyles(
          height: PosTextSize.size1,
          width: PosTextSize.size2,
          align: PosAlign.center,
          bold: true,
        ));
    printer.text('', styles: const PosStyles(fontType: PosFontType.fontA));
  }
  printer.text(companyInfo['company_name'].toString(),
      styles: const PosStyles(align: PosAlign.center, bold: true));
  printer.text('');
  printer.text('-------------Take Away Token (TAT)--------------');
  printer.text('T/W No       : ${data[0]['token_no'].toString()}',
      styles: const PosStyles(bold: true));
  if (data[0]['tw_name'] != '') {
    printer.text('T/W Name     : ${data[0]['tw_name']}');
  }

  printer.text('Total Amount : Rs.${data[0]['net_amount'].toString()}');
  printer.text('Date Time    : $currentTime');
  printer.text('------------------------------------------------');
  printer.row([
    PosColumn(
        text: 'Sn',
        width: 1,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: 'Particulars',
        width: 8,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: '',
        width: 1,
        styles:
            const PosStyles(height: PosTextSize.size1, align: PosAlign.center)),
    PosColumn(
        text: 'Qty  ',
        width: 2,
        styles: const PosStyles(height: PosTextSize.size1)),
  ]);
  printer.text('------------------------------------------------');
  var datas = data[0]['take_away_items'];
  for (int i = 0; i < datas.length; i++) {
    printer.row([
      PosColumn(
          text: (i + 1).toString(),
          width: 1,
          styles: const PosStyles(
            height: PosTextSize.size1,
          )),
      PosColumn(
          text: '${(datas[i]['name'])}',
          width: 8,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontA)),
      PosColumn(
          text: '',
          width: 1,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontA)),
      PosColumn(
          text: (datas[i]['quantity'].toString()),
          width: 2,
          styles: const PosStyles(height: PosTextSize.size1)),
    ]);
  }
  printer.text('');
  printer.text('Remark : ${data[0]['remark']}');
  // print(companyInfo['message'].toString().isEmpty);
  // if (companyInfo['message'] != null) {

  //   printer.text(companyInfo['message'],
  //       styles: const PosStyles(align: PosAlign.center, bold: true));
  // }
  printer.text('');
  printer.text('Please wait for your turn.',
      styles: const PosStyles(align: PosAlign.center));
  printer.beep(n: 1);
  printer.feed(2);
  printer.cut(mode: PosCutMode.full);
}

/////////////////////////////////////////////////////////////

///////////////////Table KOT Priniting //////////////////////

Future<bool> printingOrderReceipt(data, context, bool isUpdate) async {
  var jsonData = (data[0]);
  var result = groupBy(jsonData['order_items']);
  final printerControllers =
      Provider.of<PrinterIpAddressController>(context, listen: false);
  const PaperSize paper = PaperSize.mm80;
  final profile = await CapabilityProfile.load();
  final printer = NetworkPrinter(paper, profile);
  final PosPrintResult res = await printer.connect(
      printerControllers.printerIpAddress!,
      port: printerControllers.printerPort!);
  if (res == PosPrintResult.success) {
    for (var a in result) {
      var storeName = (a['storeName']);
      var orderItem = (a['Data']);
      printingOrderReceiptforTABLE(
          printer, data, storeName, orderItem, isUpdate);
    }

    printer.disconnect();
    return true;
  } else {
    printer.disconnect();
    return false;
  }
}

printingOrderReceiptforTABLE(
    printer, data, storeName, List orderItem, bool isUpate) {
  dynamic currentTime =
      DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  printer.text('');
  if (isUpate) {
    printer.text('ADD',
        styles: const PosStyles(
          height: PosTextSize.size1,
          width: PosTextSize.size2,
          align: PosAlign.center,
          bold: true,
        ));
    printer.text('', styles: const PosStyles(fontType: PosFontType.fontA));
  }
  printer.text('-------------Order Receipt--------------');
  printer.text('Order Receipt By : ${data[0]['order_receipt_by'].toString()}');
  printer.text('Floor Name       : ${data[0]['floor_name'].toString()}');
  printer.text('Store Name       : $storeName',
      styles: const PosStyles(bold: true));
  printer.text('Table Name       : ${data[0]['table_name'].toString()}',
      styles: const PosStyles(bold: true));
  printer.text('KOT No.          : ${data[0]['kot_no'].toString()}',
      styles: const PosStyles(bold: true));
  printer.text('Date Time        : $currentTime');
  printer.text('------------------------------------------------');
  printer.row([
    PosColumn(
        text: 'Particulars',
        width: 9,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: '',
        width: 1,
        styles:
            const PosStyles(height: PosTextSize.size1, align: PosAlign.center)),
    PosColumn(
        text: 'Qty  ',
        width: 2,
        styles: const PosStyles(height: PosTextSize.size1)),
  ]);
  printer.text('------------------------------------------------');
  for (int i = 0; i < orderItem.length; i++) {
    printer.row([
      PosColumn(
          text: '${(orderItem[i]['name'])}',
          width: 9,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontA)),
      PosColumn(
          text: '',
          width: 1,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontA)),
      PosColumn(
          text: (orderItem[i]['quantity'].toString()),
          width: 2,
          styles: const PosStyles(height: PosTextSize.size1)),
    ]);
  }
  printer.text('');
  printer.text('Remark : ${data[0]['remark']}');
  printer.beep(n: 1);
  printer.feed(2);
  printer.cut(mode: PosCutMode.full);
}
/////////////////////////////////////////////////////////////////////////////////

/////////////////////// Checking Printinf/////////
Future<bool> checkPrint(context) async {
  final printerControllers =
      Provider.of<PrinterIpAddressController>(context, listen: false);
  const PaperSize paper = PaperSize.mm80;
  final profile = await CapabilityProfile.load();
  final printer = NetworkPrinter(paper, profile);
  final PosPrintResult res = await printer.connect(
      printerControllers.printerIpAddress!,
      port: printerControllers.printerPort!);
  if (res == PosPrintResult.success) {
    printer.disconnect();
    return true;
  } else {
    printer.disconnect();
    return false;
  }
}

////////////////////////CreditPriniting Bill ////////////////////////
Future<bool> printerCredit(data, urlController, context) async {
  final printerControllers =
      Provider.of<PrinterIpAddressController>(context, listen: false);
  var companyInfo = printerControllers.getCompanyInfo;
  const PaperSize paper = PaperSize.mm80;
  final profile = await CapabilityProfile.load();
  final printer = NetworkPrinter(paper, profile);
  final PosPrintResult res = await printer.connect(
      printerControllers.printerIpAddress!,
      port: printerControllers.printerPort!);

  if (res == PosPrintResult.success) {
    printingCreditBill(data, urlController, companyInfo, printer);
    printingCreditBill(data, urlController, companyInfo, printer);
    printer.disconnect();
    return true;
  } else {
    printer.disconnect();
    return false;
  }
}

printingCreditBill(data, urlController, companyInfo, printer) {
  dynamic currentTime =
      DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  printer.text('');

  printer.text(companyInfo['company_name'].toString(),
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  printer.text(companyInfo['address'].toString(),
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  printer.text(companyInfo['phone'].toString(),
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  printer.text(
      "${companyInfo['pan_vat_no'] == 'VAT' ? "VAT No." : "PAN No"}:${companyInfo['pan_vat_no']}",
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  printer.text('');
  if (urlController == 1) {
    printer.text('Ref.Code      : ${data['ref_code']}');
    printer.text('T/W Name      : ${data['tw_name']}');
  }
  printer.text('bill_no       : ${data['bill_no']}');
  printer.text('Customer Name : ${data['customer_name']}');
  if (urlController == 0) {
    printer.text('Table Name    : ${data['table_name']}');
  }

  printer.text('Date Time     : $currentTime');
  printer.text('------------------------------------------------');
  printer.row([
    PosColumn(
        text: 'Sn',
        width: 1,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: 'Particulars',
        width: 8,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: '',
        width: 1,
        styles:
            const PosStyles(height: PosTextSize.size1, align: PosAlign.center)),
    PosColumn(
        text: 'Qty  ',
        width: 2,
        styles: const PosStyles(height: PosTextSize.size1)),
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
            height: PosTextSize.size1,
          )),
      PosColumn(
          text: '${(datas[i]['name'])}',
          width: 8,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontB)),
      PosColumn(
          text: '',
          width: 1,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontA)),
      PosColumn(
          text: (datas[i]['quantity'].toString()),
          width: 2,
          styles: const PosStyles(height: PosTextSize.size1)),
    ]);
  }
  printer.text('------------------------------------------------');
  printer.text("Gross Amount   : ${data['gross_amount']}",
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  printer.text("Discount   : ${data['discount']}",
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  printer.text('            -----------------------------------',
      styles: const PosStyles(
        align: PosAlign.center,
      ));

  printer.text("Net Amount   : ${data['net_amount']}",
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  printer.text('            -----------------------------------',
      styles: const PosStyles(
        align: PosAlign.center,
      ));

  printer.text("Payment Status   : Settled",
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  printer.text("Payment Method  : Credit",
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  printer.text('------------------------------------------------');
  printer.text('');
  printer.text('Thank You For Visit',
      styles: const PosStyles(align: PosAlign.center));
  printer.text('Visit again soon...',
      styles: const PosStyles(align: PosAlign.center));
  printer.beep(n: 1);
  printer.feed(2);
  printer.cut(mode: PosCutMode.full);
}

///////////////////////////Home Delivery///////////////////////////////

Future<bool> printingHomeDeliveryOrderReceipt(
    data, context, bool isUpdate) async {
  final printerControllers =
      Provider.of<PrinterIpAddressController>(context, listen: false);
  var jsonData = (data[0]);
  var result = groupBy(jsonData['home_delivery_items']);
  const PaperSize paper = PaperSize.mm80;
  final profile = await CapabilityProfile.load();
  final printer = NetworkPrinter(paper, profile);
  final PosPrintResult res = await printer.connect(
      printerControllers.printerIpAddress!,
      port: printerControllers.printerPort!);

  if (res == PosPrintResult.success) {
    for (var a in result) {
      var storeName = (a['storeName']);
      var orderItem = (a['Data']);

      printingOrderReceiptforHD(printer, data, storeName, orderItem, isUpdate);
    }
    printer.disconnect();
    return true;
  } else {
    printer.disconnect();
    return false;
  }
}

printingOrderReceiptforHD(printer, data, storeName, orderItem, bool isUpate) {
  dynamic currentTime =
      DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  printer.text('');
  if (isUpate) {
    printer.text('ADD',
        styles: const PosStyles(
          height: PosTextSize.size1,
          width: PosTextSize.size2,
          align: PosAlign.center,
          bold: true,
        ));
    printer.text('', styles: const PosStyles(fontType: PosFontType.fontA));
  }
  printer.text('-------------Home Delivery --------------');
  printer.text('Order Receipt By : ${data[0]['order_receipt_by'].toString()}');
  printer.text('Floor Name       : ${data[0]['floor_name'].toString()}');
  printer.text('Store Name       : $storeName',
      styles: const PosStyles(bold: true));
  printer.text('HD Name          : ${data[0]['hd_no'].toString()}',
      styles: const PosStyles(bold: true));
  printer.text('KOT No.          : ${data[0]['kot_no'].toString()}',
      styles: const PosStyles(bold: true));
  printer.text('Address          : ${data[0]['address'].toString()}');
  printer.text('Date Time        : $currentTime');
  printer.text('------------------------------------------------');

  printer.row([
    PosColumn(
        text: 'Sn',
        width: 1,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: 'Particulars',
        width: 8,
        styles: const PosStyles(height: PosTextSize.size1)),
    PosColumn(
        text: '',
        width: 1,
        styles:
            const PosStyles(height: PosTextSize.size1, align: PosAlign.center)),
    PosColumn(
        text: 'Qty  ',
        width: 2,
        styles: const PosStyles(height: PosTextSize.size1)),
  ]);

  printer.text('------------------------------------------------');

  for (int i = 0; i < orderItem.length; i++) {
    printer.row([
      PosColumn(
          text: (i + 1).toString(),
          width: 1,
          styles: const PosStyles(
            height: PosTextSize.size1,
          )),
      PosColumn(
          text: '${orderItem[i]['name']}',
          width: 8,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontA)),
      PosColumn(
          text: '',
          width: 1,
          styles: const PosStyles(
              height: PosTextSize.size1, fontType: PosFontType.fontA)),
      PosColumn(
          text: '${orderItem[i]['quantity']}',
          width: 2,
          styles: const PosStyles(height: PosTextSize.size1)),
    ]);
  }
  printer.text('');
  printer.text('Remark : ${data[0]['remark']}');
  printer.beep(n: 1);
  printer.feed(2);
  printer.cut(mode: PosCutMode.full);
}

/////////////////////////Printing Bill For USER /////////////////////////////////////

Future<bool> printerHomeDelivery(data, qrImage, context) async {
  final printerControllers =
      Provider.of<PrinterIpAddressController>(context, listen: false);
  var companyInfo = printerControllers.getCompanyInfo;
  const PaperSize paper = PaperSize.mm80;
  final profile = await CapabilityProfile.load();
  final generator = NetworkPrinter(paper, profile);
  final PosPrintResult res = await generator.connect(
      printerControllers.printerIpAddress!,
      port: printerControllers.printerPort!);

  if (res == PosPrintResult.success) {
    printerHomeDeliveryBill(generator, companyInfo, qrImage, data);
    return true;
  } else {
    generator.disconnect();
    return false;
  }
}

printerHomeDeliveryBill(generator, companyInfo, qrImage, data) async {
  dynamic currentTime =
      DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  generator.text('');

  generator.text(companyInfo['company_name'].toString(),
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  generator.text(companyInfo['address'].toString(),
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  generator.text(companyInfo['phone'].toString(),
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  generator.text(
      "${companyInfo['pan_vat_no'] == 'VAT' ? "VAT No." : "PAN No"}:${companyInfo['pan_vat_no']}",
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  generator.text('');
  generator.text('Ref.Code      : ${data['hd_no']}',
      styles: const PosStyles(bold: true));
  generator.text('bill_no       : ${data['bill_no']}');
  generator.text('Customer Name : ${data['customer_name']}');
  generator.text('Mobile        : ${data['phone_no']}');
  generator.text('Address       : ${data['address']}');
  generator.text('Date Time     : $currentTime');
  generator.text('------------------------------------------------');
  generator.row([
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

  generator.text('------------------------------------------------');
  var datas = data['home_delivery_items'];
  for (int i = 0; i < datas.length; i++) {
    generator.row([
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
  generator.text('------------------------------------------------',
      styles: const PosStyles(fontType: PosFontType.fontA));
  generator.text("Gross Amount   : ${data['gross_amount']}",
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  generator.text("Discount   : ${data['discount']}",
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  generator.text('            -----------------------------------',
      styles: const PosStyles(
        align: PosAlign.center,
      ));

  generator.text("Net Amount   : ${data['net_amount']}",
      styles: const PosStyles(
        align: PosAlign.center,
      ));
  generator.text('            -----------------------------------',
      styles: const PosStyles(
        align: PosAlign.center,
      ));

  generator.text('------------------------------------------------');
  generator.text('Thank You For Visit',
      styles: const PosStyles(align: PosAlign.center));
  generator.text('Visit again soon...',
      styles: const PosStyles(align: PosAlign.center));
  generator.text('------------------------------------------------');
  // generator.text('Download our App ',
  //     styles: const PosStyles(align: PosAlign.center));
  // generator.text('Find us on Play Store && App Store',
  //     styles: const PosStyles(align: PosAlign.center));
  // generator.text('------------------------------------------------');
  
  var response = await http.get(
    Uri.parse(qrImage),
);
  final Uint8List imgBytes = response.bodyBytes;
  final Image image = decodeImage(imgBytes)!;
  generator.image(image);
  generator.text('Scan Me To Pay',styles: const PosStyles(align: PosAlign.center,height: PosTextSize.size2,bold: true ));
  generator.feed(1);
  generator.cut();
  generator.disconnect();
}

groupBy(data) {
  var datas = (data as List);
  final result = datas
      .fold(<String, List<dynamic>>{}, (Map<String, List<dynamic>> a, b) {
        a.putIfAbsent(b['store_name'], () => []).add(b);
        return a;
      })
      .values
      .where((l) => l.isNotEmpty)
      .map((l) => {
            'storeName': l.first['store_name'],
            'Data': l.map((e) => e).toList()
          })
      .toList();
  return result;
}

