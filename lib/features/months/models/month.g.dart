// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'month.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Month _$MonthFromJson(Map<String, dynamic> json) => Month(
  id: json[r'$id'] as String,
  name: json['name'] as String,
  year: (json['year'] as num).toInt(),
  monthIndex: (json['month_index'] as num).toInt(),
  totalIncome: (json['total_income'] as num).toDouble(),
  totalExpense: (json['total_expense'] as num).toDouble(),
  remainingBalance: (json['remaining_balance'] as num).toDouble(),
);

Map<String, dynamic> _$MonthToJson(Month instance) => <String, dynamic>{
  r'$id': instance.id,
  'name': instance.name,
  'year': instance.year,
  'month_index': instance.monthIndex,
  'total_income': instance.totalIncome,
  'total_expense': instance.totalExpense,
  'remaining_balance': instance.remainingBalance,
};
