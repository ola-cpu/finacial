class IncomeModel {
  final String id;
  final String title;
  final double amount;
  final String category;

  IncomeModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
  });

  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    return IncomeModel(
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
