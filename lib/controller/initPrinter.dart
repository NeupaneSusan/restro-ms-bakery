import 'package:flutter/material.dart';

class PrinterIpAddressController with ChangeNotifier {
  dynamic companyInfo;
  String? printerIpAddress;
  int? printerPort;
  bool isLoading = false;
  get getPrinterIpAddress => printerIpAddress;
  get getPrinterPort => printerPort;
  get getLoading => isLoading;
  get getCompanyInfo => companyInfo;
  setPrinterIpAddress(String? ipAddress, int? port) {
    printerIpAddress = ipAddress;
    printerPort = port;
    notifyListeners();
  }
  setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
  setCompanyProfile(data) {
    companyInfo = data;
    notifyListeners();
  }
}
