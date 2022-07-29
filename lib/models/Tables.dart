class Tables {
  dynamic id;
  dynamic name;
  dynamic capacity;
  dynamic available;
  dynamic storeId;
  
  Tables({this.id, this.name,this.capacity,this.available,this.storeId});

  factory Tables.fromJson(Map<String, dynamic> json) {
    return Tables(
        id: json['id'],
        name: json['table_name'],
        capacity: json['capacity'],
        available: json['available'],
        storeId: json['store_id']
     );
  }
}
