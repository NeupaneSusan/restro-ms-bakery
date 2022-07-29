import 'package:flutter/material.dart';
import '../models/CartItem.dart';

class CartController extends ChangeNotifier {
  Map<String?, CartItem> _cartitems = {};

  Map<String?, CartItem> get items {
    return {..._cartitems};
  }

  void addItem(String pdtid, String? name, double rate, int? storeId) {
    if (_cartitems.containsKey(pdtid)) {
      _cartitems.update(
          pdtid,
          (existingCartItem) => CartItem(
              id: DateTime.now().toString(),
              name: existingCartItem.name,
              quantity: existingCartItem.quantity! + 1,
              storeId: existingCartItem.storeId,
              isNew: 1,
              plusQuantity: existingCartItem.plusQuantity + 1,
              oldQuantity: existingCartItem.oldQuantity,
              rate: existingCartItem.rate));
    } else {
      _cartitems.putIfAbsent(
          pdtid,
          () => CartItem(
                name: name,
                id: DateTime.now().toString(),
                quantity: 1,
                rate: rate,
                storeId: storeId,
                isNew: 1,
                plusQuantity: 1,
                oldQuantity: 0,
              ));
    }
    
    notifyListeners();
  }

  
  
  
  void addOldItem(
      String? pdtid, String? name, double rate, int storeId, int oldQty) {
    _cartitems.putIfAbsent(
        pdtid,
        () => CartItem(
              name: name,
              id: DateTime.now().toString(),
              quantity: oldQty,
              rate: rate,
              storeId: storeId,
              isNew: 0,
              plusQuantity: 0,
              oldQuantity: oldQty,
            ));

    notifyListeners();
  }

  void removeItem(String? id) {
    _cartitems.remove(id);
    notifyListeners();
  }

  void removeSingleItem(String? id) {
    if (!_cartitems.containsKey(id)) {
      return;
    }
    if (_cartitems[id]!.quantity! > 1) {
      _cartitems.update(
          id,
          (existingCartItem) => CartItem(
                id: DateTime.now().toString(),
                name: existingCartItem.name,
                quantity: existingCartItem.quantity! - 1,
                storeId: existingCartItem.storeId,
                rate: existingCartItem.rate,
              ));
    } else {
      removeItem(id);
    }
    notifyListeners();
  }

  void removeEditSingleItem(String? id) {
    if (!_cartitems.containsKey(id)) {
      return;
    }
    if (_cartitems[id]!.oldQuantity == 0 && _cartitems[id]!.quantity == 1) {
      removeItem(id);
    }

    if (_cartitems[id]!.quantity! > _cartitems[id]!.oldQuantity!) {
      _cartitems.update(
          id,
          (existingCartItem) => CartItem(
              id: DateTime.now().toString(),
              name: existingCartItem.name,
              quantity: existingCartItem.quantity! - 1,
              storeId: existingCartItem.storeId,
              plusQuantity: existingCartItem.plusQuantity - 1,
              oldQuantity: existingCartItem.oldQuantity,
              rate: existingCartItem.rate,
              isNew: 1));
    }

    if (_cartitems[id]!.oldQuantity == _cartitems[id]!.quantity) {
      _cartitems.update(
          id,
          (existingCartItem) => CartItem(
              id: DateTime.now().toString(),
              name: existingCartItem.name,
              quantity: existingCartItem.quantity,
              storeId: existingCartItem.storeId,
              plusQuantity: existingCartItem.plusQuantity,
              isNew: 0,
              oldQuantity: existingCartItem.oldQuantity,
              rate: existingCartItem.rate));
    }

    notifyListeners();
  }

  int get count {
    return _cartitems.length;
  }

  int get totalItemsCount {
    int total = 0;
    _cartitems.forEach((key, value) {
      total += value.quantity!;
    });
    return total;
  }

  double get totalAmount {
    var total = 0.0;
    _cartitems.forEach((key, cartItem) {
      total += cartItem.rate! * cartItem.quantity!;
    });
    return total;
  }

  void clear() {
    _cartitems = {};
    notifyListeners();
  }
  void changePrice(String pdtid,  double rate) {
    if (_cartitems.containsKey(pdtid)) {
      _cartitems.update(
          pdtid,
          (existingCartItem) => CartItem(
              id: DateTime.now().toString(),
              name: existingCartItem.name,
              quantity: existingCartItem.quantity,
              storeId: existingCartItem.storeId,
              isNew: 1,
              plusQuantity: existingCartItem.plusQuantity,
              oldQuantity: existingCartItem.oldQuantity,
              rate: rate));
    } 
    notifyListeners();
  }

  
  
  
}
