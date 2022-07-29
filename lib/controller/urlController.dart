import 'package:flutter/material.dart';

class UrlController with ChangeNotifier {
  //  urlValue== 0 tableOrders
  // urlValue == 1 takeAways
  // urlValue ==2 Homwdelivery
   int? urlValue ;
   get getUrlValue => urlValue;
    setUrlValue(int value){
       urlValue = value;
       notifyListeners();
   }
}