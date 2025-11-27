import 'package:json_annotation/json_annotation.dart';

part 'transaction.g.dart';

enum CategoryMain {
  @JsonValue('Income')
  income,
  @JsonValue('Mandatory')
  mandatory,
  @JsonValue('Optional')
  optional,
  @JsonValue('Debt')
  debt,
  @JsonValue('Savings')
  savings,
}

@JsonSerializable()
class TransactionModel {
  @JsonKey(name: '\$id')
  final String id;
  @JsonKey(name: 'month_id')
  final String monthId;
  @JsonKey(name: 'category_main')
  final CategoryMain categoryMain;
  final String title;
  final double amount;
  @JsonKey(name: 'is_fixed')
  final bool isFixed;

  TransactionModel({
    required this.id,
    required this.monthId,
    required this.categoryMain,
    required this.title,
    required this.amount,
    required this.isFixed,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);
}
