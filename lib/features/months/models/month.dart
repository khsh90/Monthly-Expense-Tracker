import 'package:json_annotation/json_annotation.dart';

part 'month.g.dart';

@JsonSerializable()
class Month {
  @JsonKey(name: '\$id')
  final String id;
  final String name;
  final int year;
  @JsonKey(name: 'month_index')
  final int monthIndex;
  @JsonKey(name: 'total_income')
  final double totalIncome;
  @JsonKey(name: 'total_expense')
  final double totalExpense;
  @JsonKey(name: 'remaining_balance')
  final double remainingBalance;

  Month({
    required this.id,
    required this.name,
    required this.year,
    required this.monthIndex,
    required this.totalIncome,
    required this.totalExpense,
    required this.remainingBalance,
  });

  factory Month.fromJson(Map<String, dynamic> json) => _$MonthFromJson(json);

  Map<String, dynamic> toJson() => _$MonthToJson(this);
}
