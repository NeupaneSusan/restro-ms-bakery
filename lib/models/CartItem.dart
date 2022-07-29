class CartItem {
  String? id;
  String? name;
  double? rate;
  int? quantity;
  int? storeId;
  int plusQuantity;
  int? isNew;
  int? oldQuantity;
  CartItem({this.id, this.name, this.rate, this.quantity,this.storeId,this.isNew,this.plusQuantity = 0,this.oldQuantity, int? isedit});
  

  @override
  String toString() {
    return 'CartItem(id: $id, name: $name, rate: $rate, quantity: $quantity, storeId: $storeId, plusQuantity: $plusQuantity, isNew: $isNew, oldQuantity: $oldQuantity)';
  }
}
