// ignore: file_names
import 'package:flutter/material.dart';

class BillController with ChangeNotifier {
  String? _discountType;
  String? _paymentMethod = "Cash";
  bool discoutField = false;
  bool fonpayField = false;
  bool cashField = true;
  double? _discount = 0.0;
  double? _chageAmount = 0.0;
  double? actualAmount = 0.0;
  double? _totalPaid = 0.0;
  double _returnAmount = 0.0;
  String? get getdiscountType => _discountType;
  double? get getDiscount => _discount;
  String? get getpaymentMethod => _paymentMethod;
  bool get getFonpayField => fonpayField;
  bool get getcashField => cashField;
  double? get changeTotalAmount => _chageAmount;

  double? get getTotalPaid => _totalPaid;

  double get getReturnAmount => _returnAmount;
  setTotalAmount(String grossAmount, String discount) {
    actualAmount = double.tryParse(grossAmount);
    _discount = double.tryParse(discount);
    _chageAmount = _discountType == 'DP'
        ? actualAmount! - ((actualAmount! * _discount!) / 100)
        : actualAmount! - _discount!;
    _returnAmount = 0.0;
    _totalPaid = 0.0;
    _paymentMethod = "Cash";
    fonpayField = false;
    cashField = true;
    notifyListeners();
  }

  setDiscountType(String? value) {
    _discountType = value;
    if (value == 'Select') {
      _discount = 0.0;
      _chageAmount = actualAmount;
      if (getpaymentMethod == 'Cash') {
        if (getTotalPaid != 0) {
          _totalPaid = getTotalPaid;
          _returnAmount = _totalPaid! > changeTotalAmount!
              ? _totalPaid! - changeTotalAmount!
              : 0.0;
        } else {
          _totalPaid = 0.0;
          _returnAmount = 0.0;
        }
      } else {
        _totalPaid = actualAmount;
      }

      discoutField = false;
    } else if (value == 'FA') {
      _chageAmount = actualAmount! - getDiscount!;
      if (getTotalPaid != 0) {
        _totalPaid = getTotalPaid;
        _returnAmount = _totalPaid! > _chageAmount!
            ? _totalPaid! - changeTotalAmount!
            : 0.0;
      } else {
        _totalPaid = 0.0;
        _returnAmount = 0.0;
      }
      discoutField = true;
    } else if (value == 'Cancel') {
      _chageAmount = actualAmount! - getDiscount!;
      if (getTotalPaid != 0) {
        _totalPaid = getTotalPaid;
        _returnAmount = _totalPaid! > _chageAmount!
            ? _totalPaid! - changeTotalAmount!
            : 0.0;
      } else {
        _totalPaid = 0.0;
        _returnAmount = 0.0;
      }
      discoutField = true;
    } else if (value == 'DP') {
      _chageAmount = actualAmount! - ((actualAmount! * getDiscount!) / 100);
      if (getTotalPaid != 0) {
        _totalPaid = getTotalPaid;
        _returnAmount = _totalPaid! > _chageAmount!
            ? _totalPaid! - changeTotalAmount!
            : 0.0;
      } else {
        _totalPaid = 0.0;
        _returnAmount = 0.0;
      }
      discoutField = true;
    }

    notifyListeners();
  }

  setPaymentMethod(String? value) {
    _paymentMethod = value;
    if (_paymentMethod == "Cash") {
      cashField = true;
      fonpayField = false;
      _returnAmount = 0.0;
      _totalPaid = 0.0;
    }
    else if  (_paymentMethod == 'Manual Fonpay' || _paymentMethod=='eSewa') {
      cashField = false;
      fonpayField = false;
      _totalPaid = changeTotalAmount;
      _returnAmount = 0.0;
    }
    if (_paymentMethod == 'Card') {
      cashField = false;
      fonpayField = false;
      _totalPaid = changeTotalAmount;
      _returnAmount = 0.0;
    }
    if (_paymentMethod == 'mf-and-cash') {
      cashField = true;
      fonpayField = true;
      _totalPaid = 0.0;
      _returnAmount = 0.0;
    }
    notifyListeners();
  }

  onChangeValueAmount(value) {
    if (value.isEmpty) {
      _chageAmount = actualAmount;
      _discount = 0;
      if (getpaymentMethod == 'Manual Fonpay' || getpaymentMethod == 'Card' || getpaymentMethod=='eSewa') {
        _totalPaid = _chageAmount;
      } else {
        _totalPaid = getTotalPaid;
      }
      notifyListeners();
    } else {
      
      var a = _discountType == 'DP'
          ? actualAmount! - ((actualAmount! * double.tryParse(value)!) / 100)
          : actualAmount! - double.tryParse(value)!;
      _chageAmount = a;
      _discount = double.tryParse(value);
      if (getpaymentMethod == 'Cash' || getpaymentMethod == 'mf-and-cash') {
        if (getTotalPaid != 0) {
          if (getTotalPaid! > _chageAmount!) {
            _returnAmount = getTotalPaid! - _chageAmount!;
          } else {
            _returnAmount = 0.0;
          }
        }
      } else {
        _totalPaid = a;
      }
      notifyListeners();
    }
  }

  cashAmountPayment(value) {
    _totalPaid = value.isEmpty ? 0.0 : double.tryParse(value);
    _returnAmount = value.isEmpty
        ? 0.0
        : (_totalPaid! > _chageAmount!)
            ? _totalPaid! - _chageAmount!
            : 0.0;
    notifyListeners();
  }

  clear() {
    _paymentMethod = "Cash";
    fonpayField = false;
    cashField = true;
    discoutField = false;
    _chageAmount = 0.0;
    actualAmount = 0.0;
    _totalPaid = 0.0;
    _returnAmount = 0.0;
    _discount = 0.0;
    notifyListeners();
  }
}
