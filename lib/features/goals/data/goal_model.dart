class GoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime deadline;

  GoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.deadline,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'],
      title: json['title'],
      targetAmount: json['target_amount'].toDouble(),
      savedAmount: json['saved_amount'].toDouble(),
      deadline: DateTime.parse(json['deadline']),
    );
  }
}
