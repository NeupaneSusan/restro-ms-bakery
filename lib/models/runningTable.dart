class RunningtableModel {
  String? tableId;
  String? tableName;

  RunningtableModel({this.tableId, this.tableName});

  RunningtableModel.fromJson(Map<String, dynamic> json) {
    tableId = json['table_id'];
    tableName = json['table_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['table_id'] = this.tableId;
    data['table_name'] = this.tableName;
    return data;
  }
}