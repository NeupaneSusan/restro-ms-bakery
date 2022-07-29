// ignore_for_file: unnecessary_new, prefer_collection_literals

class Customer {
  String? id;
  String? name;
  String? mobileNo;
  String? address;

  Customer({this.id, this.name, this.mobileNo,this.address});

  Customer.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    mobileNo = json['mobile_no'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['name'] = name;
    data['mobile_no'] = mobileNo;
    data['address'] = address;
    return data;
  }
}