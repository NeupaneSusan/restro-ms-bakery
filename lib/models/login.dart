class Login{
  String? email;
  String? password;
  String? id;
  String? displayName;
  String? username;
  String? storeId;
  String? floorId;

  Login({this.email,this.password,this.id,this.displayName,this.username,this.storeId,this.floorId});

//  to fetch data
   Map toMap(){
    var map = Map<String, dynamic>();

    map["email"] = email;
    map["password"] = password;
    

    return map;

  }

}