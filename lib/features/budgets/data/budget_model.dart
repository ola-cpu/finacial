class BudgetModel {
  final String id;
  final String category;
  final double monthlyLimit;

  BudgetModel({
    required this.id,
    required this.category,
    required this.monthlyLimit,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'],
      category: json['category'],
      monthlyLimit: json['monthly_limit'].toDouble(),
    );
  }
}
