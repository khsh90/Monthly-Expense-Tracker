// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionTemplate _$TransactionTemplateFromJson(Map<String, dynamic> json) =>
    TransactionTemplate(
      id: json[r'$id'] as String,
      categoryMain: $enumDecode(_$CategoryMainEnumMap, json['category_main']),
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$TransactionTemplateToJson(
  TransactionTemplate instance,
) => <String, dynamic>{
  r'$id': instance.id,
  'category_main': _$CategoryMainEnumMap[instance.categoryMain]!,
  'title': instance.title,
  'amount': instance.amount,
};

const _$CategoryMainEnumMap = {
  CategoryMain.income: 'Income',
  CategoryMain.mandatory: 'Mandatory',
  CategoryMain.optional: 'Optional',
  CategoryMain.debt: 'Debt',
  CategoryMain.savings: 'Savings',
};
