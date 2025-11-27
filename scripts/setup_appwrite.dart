import 'dart:convert';
import 'package:http/http.dart' as http;

const String endpoint = 'https://fra.cloud.appwrite.io/v1';
const String projectId = 'YOUR_PROJECT_ID';
const String apiKey = 'YOUR_API_KEY_HERE'; // TODO: Replace with your API Key or use environment variables

const String databaseId = 'expense_tracker';
const String monthsCollectionId = 'months';
const String transactionsCollectionId = 'transactions';
const String templatesCollectionId = 'transaction_templates';

Future<void> main() async {
  final headers = {
    'X-Appwrite-Project': projectId,
    'X-Appwrite-Key': apiKey,
    'Content-Type': 'application/json',
  };

  print('Creating Database...');
  await createDatabase(headers);

  print('Creating Months Collection...');
  await createCollection(headers, monthsCollectionId, 'Months');
  await createMonthAttributes(headers);

  print('Creating Transactions Collection...');
  await createCollection(headers, transactionsCollectionId, 'Transactions');
  await createTransactionAttributes(headers);

  print('Creating Transaction Templates Collection...');
  await createCollection(headers, templatesCollectionId, 'Transaction Templates');
  await createTemplateAttributes(headers);

  print('Setup Complete!');
}

Future<void> createDatabase(Map<String, String> headers) async {
  try {
    final response = await http.post(
      Uri.parse('$endpoint/databases'),
      headers: headers,
      body: jsonEncode({
        'databaseId': databaseId,
        'name': 'Expense Tracker DB',
      }),
    );
    if (response.statusCode >= 400) {
      print('Database creation failed (might already exist): ${response.body}');
    }
  } catch (e) {
    print('Error creating database: $e');
  }
}

Future<void> createCollection(
    Map<String, String> headers, String collectionId, String name) async {
  try {
    final response = await http.post(
      Uri.parse('$endpoint/databases/$databaseId/collections'),
      headers: headers,
      body: jsonEncode({
        'collectionId': collectionId,
        'name': name,
        'permissions': [
          'read("any")',
          'write("any")', // For simplicity in this demo. Secure this in prod!
          'update("any")',
          'delete("any")',
        ],
      }),
    );
    if (response.statusCode >= 400) {
      print('Collection $name creation failed: ${response.body}');
    }
  } catch (e) {
    print('Error creating collection $name: $e');
  }
}

Future<void> createMonthAttributes(Map<String, String> headers) async {
  final attributes = [
    {'key': 'name', 'type': 'string', 'size': 255, 'required': true},
    {'key': 'year', 'type': 'integer', 'required': true},
    {'key': 'month_index', 'type': 'integer', 'required': true},
    {'key': 'total_income', 'type': 'float', 'required': true},
    {'key': 'total_expense', 'type': 'float', 'required': true},
    {'key': 'remaining_balance', 'type': 'float', 'required': true},
  ];

  for (var attr in attributes) {
    await createAttribute(headers, monthsCollectionId, attr);
  }
}

Future<void> createTransactionAttributes(Map<String, String> headers) async {
  final attributes = [
    {'key': 'month_id', 'type': 'string', 'size': 255, 'required': true},
    {'key': 'category_main', 'type': 'string', 'size': 255, 'required': true},
    {'key': 'title', 'type': 'string', 'size': 255, 'required': true},
    {'key': 'amount', 'type': 'float', 'required': true},
    {'key': 'is_fixed', 'type': 'boolean', 'required': true},
  ];

  for (var attr in attributes) {
    await createAttribute(headers, transactionsCollectionId, attr);
  }
}

Future<void> createTemplateAttributes(Map<String, String> headers) async {
  final attributes = [
    {'key': 'category_main', 'type': 'string', 'size': 255, 'required': true},
    {'key': 'title', 'type': 'string', 'size': 255, 'required': true},
    {'key': 'amount', 'type': 'float', 'required': true},
  ];

  for (var attr in attributes) {
    await createAttribute(headers, templatesCollectionId, attr);
  }
}

Future<void> createAttribute(Map<String, String> headers, String collectionId,
    Map<String, dynamic> attr) async {
  final type = attr['type'];
  final key = attr['key'];
  
  String url = '$endpoint/databases/$databaseId/collections/$collectionId/attributes/$type';
  
  final body = {
    'key': key,
    'required': attr['required'],
  };
  
  if (type == 'string') {
    body['size'] = attr['size'];
  }

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
     if (response.statusCode >= 400) {
       // Ignore "Attribute already exists" errors
      if (!response.body.contains('Attribute already exists')) {
         print('Attribute $key creation failed: ${response.body}');
      }
    }
  } catch (e) {
    print('Error creating attribute $key: $e');
  }
}
