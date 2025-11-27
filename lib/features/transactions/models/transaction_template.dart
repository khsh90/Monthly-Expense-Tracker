import 'package:expense_tracker/features/transactions/models/transaction.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transaction_template.g.dart';

@JsonSerializable()
class TransactionTemplate {
  @JsonKey(name: '\$id')
  final String id;
  @JsonKey(name: 'category_main')
  final CategoryMain categoryMain;
  final String title;
  final double amount;

  TransactionTemplate({
    required this.id,
    required this.categoryMain,
    required this.title,
    required this.amount,
  });

  factory TransactionTemplate.fromJson(Map<String, dynamic> json) =>
      _$TransactionTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionTemplateToJson(this);
}
