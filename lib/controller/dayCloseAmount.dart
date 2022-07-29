import 'package:flutter/material.dart';

class AmountFlow with ChangeNotifier {
  bool _isLoading = false;
  double _thousandsAmount = 0;
  double _fiveHundredAmount = 0;
  double _hundredAmount = 0;
  double _fiftyAmount = 0;
  double _twentyAmount = 0;
  double _tenAmount = 0;
  double _fiveAmount = 0;
  double _twoAmount = 0;
  double _oneAmount = 0;
  double _icAmount = 0;
  double _fonepayAmount = 0;
  double _cardAmount = 0;
  double _totalCashAmount = 0;
  double _totalAmount = 0;

  get thousandsAmount => _thousandsAmount;
  get fiveHundredAmount => _fiveHundredAmount;
  get hundredAmount => _hundredAmount;
  get fiftyAmount => _fiftyAmount;
  get twentyAmount => _twentyAmount;
  get tenAmount => _tenAmount;
  get fiveAmount => _fiveAmount;
  get twoAmount => _twoAmount;
  get oneAmount => _oneAmount;
  get icAmount => _icAmount;
  get fonepayAmount => _fonepayAmount;
  get cardAmount => _cardAmount;
  get totalCashAmount => _totalCashAmount;
  get totalAmount => _totalAmount;

  set isLoading(bool value){
    _isLoading = value;
    notifyListeners();
  }
  bool get isLoading => _isLoading;
  setAmount(int value, double totalAmounts) {
    if (value == 1000) {
      _thousandsAmount = totalAmounts;
    } else if (value == 500) {
      _fiveHundredAmount = totalAmounts;
    } else if (value == 100) {
      _hundredAmount = totalAmounts;
    } else if (value == 50) {
      _fiftyAmount = totalAmounts;
    } else if (value == 20) {
      _twentyAmount = totalAmounts;
    } else if (value == 10) {
      _tenAmount = totalAmounts;
    } else if (value == 5) {
      _fiveAmount = totalAmounts;
    } else if (value == 2) {
      _twoAmount = totalAmounts;
    } else if (value == 1) {
      _oneAmount = totalAmounts;
    } else if (value == 0) {
      _icAmount = totalAmounts;
      //IC Amount
    } else if (value == 3) {
      _fonepayAmount = totalAmounts;
      //fonepayAmount
    } else if (value == 4) {
      _cardAmount = totalAmounts;
      //card Amount
    }
    calculateTotalCashAmount();
    calculatetotalAmount();
    notifyListeners();
  }

  calculateTotalCashAmount() {
    _totalCashAmount = _thousandsAmount +
        _fiveHundredAmount +
        _hundredAmount +
        _fiftyAmount +
        _twentyAmount +
        _tenAmount +
        _fiveAmount +
        _twoAmount +
        _oneAmount +
        _icAmount;
  }

  calculatetotalAmount() {
    _totalAmount = _totalCashAmount + _cardAmount + _fonepayAmount;
  }

  clearAll() {
    _thousandsAmount = 0.0;
    _fiveHundredAmount = 0.0;
    _hundredAmount = 0.0;
    _fiftyAmount = 0.0;
    _twentyAmount = 0.0;
    _tenAmount = 0.0;
    _fiveAmount = 0.0;
    _twoAmount = 0.0;
    _oneAmount = 0.0;
    _icAmount = 0.0;
    _cardAmount=0.0;
    _fonepayAmount =0.0;
    _totalAmount = 0.0;
    _totalCashAmount=0.0;
    notifyListeners();
  }

}
