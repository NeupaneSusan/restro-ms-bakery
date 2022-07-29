class Cashout {
  String? id;
  String? cashoutCategoryId;
  String? dateTime;
  String? title;
  String? amount;
  String? description;
  String? cashoutCategoryName;

  Cashout(
      {this.id,
      this.cashoutCategoryId,
      this.dateTime,
      this.title,
      this.amount,
      this.description,
      this.cashoutCategoryName});

  Cashout.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    cashoutCategoryId = json['cashout_category_id'];
    dateTime = json['date_time'];
    title = json['title'];
    amount = json['amount'];
    description = json['description'];
    cashoutCategoryName = json['cashout_category_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['cashout_category_id'] = this.cashoutCategoryId;
    data['date_time'] = this.dateTime;
    data['title'] = this.title;
    data['amount'] = this.amount;
    data['description'] = this.description;
    data['cashout_category_name'] = this.cashoutCategoryName;
    return data;
  }
}
