// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    TransactionModel(
      id: json[r'$id'] as String,
      monthId: json['month_id'] as String,
      categoryMain: $enumDecode(_$CategoryMainEnumMap, json['category_main']),
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      isFixed: json['is_fixed'] as bool,
    );

Map<String, dynamic> _$TransactionModelToJson(TransactionModel instance) =>
    <String, dynamic>{
      r'$id': instance.id,
      'month_id': instance.monthId,
      'category_main': _$CategoryMainEnumMap[instance.categoryMain]!,
      'title': instance.title,
      'amount': instance.amount,
      'is_fixed': instance.isFixed,
    };

const _$CategoryMainEnumMap = {
  CategoryMain.income: 'Income',
  CategoryMain.mandatory: 'Mandatory',
  CategoryMain.optional: 'Optional',
  CategoryMain.debt: 'Debt',
  CategoryMain.savings: 'Savings',
};
