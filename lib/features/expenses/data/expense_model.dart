class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String category;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      title: json['title'],
      amount: json['amount'].toDouble(),
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
    };
  }
}
