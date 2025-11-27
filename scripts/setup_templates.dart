import 'dart:convert';
import 'package:http/http.dart' as http;

const String endpoint = 'https://fra.cloud.appwrite.io/v1';
const String projectId = '6927f8b4000c04df446a';
const String apiKey = 'standard_ddc3b892157d462af414363786cf33346a3cac4fe34537ee0e36d210867954ed75bef4e24fba5be482f402ac191878dad8f5d8798c5061364127e8f4add08868facc51ff6a9ceeb82c1a87cc7bab255ea0623d6e0257309fc48f253082c7753669758838d49be7487ebe080688c01a5182dd8364d0d0dac79ddbb27a94820a90';

const String databaseId = 'expense_tracker';
const String templatesCollectionId = 'transaction_templates';

Future<void> main() async {
  final headers = {
    'X-Appwrite-Project': projectId,
    'X-Appwrite-Key': apiKey,
    'Content-Type': 'application/json',
  };

  print('Creating Transaction Templates Collection...');
  await createCollection(headers);
  await createAttributes(headers);

  print('Setup Complete!');
}

Future<void> createCollection(Map<String, String> headers) async {
  try {
    final response = await http.post(
      Uri.parse('$endpoint/databases/$databaseId/collections'),
      headers: headers,
      body: jsonEncode({
        'collectionId': templatesCollectionId,
        'name': 'Transaction Templates',
        'permissions': [
          'read("any")',
          'write("any")',
          'update("any")',
          'delete("any")',
        ],
      }),
    );
    if (response.statusCode >= 400) {
      print('Collection creation failed (might already exist): ${response.body}');
    }
  } catch (e) {
    print('Error creating collection: $e');
  }
}

Future<void> createAttributes(Map<String, String> headers) async {
  final attributes = [
    {'key': 'category_main', 'type': 'string', 'size': 255, 'required': true},
    {'key': 'title', 'type': 'string', 'size': 255, 'required': true},
    {'key': 'amount', 'type': 'float', 'required': true},
  ];

  for (var attr in attributes) {
    await createAttribute(headers, attr);
  }
}

Future<void> createAttribute(Map<String, String> headers, Map<String, dynamic> attr) async {
  final type = attr['type'];
  final key = attr['key'];
  
  String url = '$endpoint/databases/$databaseId/collections/$templatesCollectionId/attributes/$type';
  
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
      if (!response.body.contains('Attribute already exists')) {
        print('Attribute $key creation failed: ${response.body}');
      }
    }
  } catch (e) {
    print('Error creating attribute $key: $e');
  }
}
