class Product {
  dynamic id;
  dynamic name;
  dynamic price;
  dynamic image;
  dynamic storeId;
  
  Product({this.id, this.name,this.price,this.image,this.storeId});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
        id: json['id'],
        name: json['name'],
        price: json['price'],
        image: json['image'],
        storeId:json['store_id']
     );
  }
}
