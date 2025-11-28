import 'package:appwrite/appwrite.dart';
import '../lib/core/constants/appwrite_constants.dart';

void main() async {
  final client = Client()
    ..setEndpoint(AppwriteConstants.endpoint)
    ..setProject(AppwriteConstants.projectId);

  final databases = Databases(client);

  try {
    print('Verifying Appwrite connection...');
    print('Endpoint: ${AppwriteConstants.endpoint}');
    print('Project ID: ${AppwriteConstants.projectId}');
    
    final result = await databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.monthsCollectionId,
      queries: [Query.limit(1)],
    );
    print('Success! Connection established.');
    print('Found ${result.total} documents in months collection.');
  } catch (e) {
    print('Error: $e');
    if (e is AppwriteException) {
      print('Appwrite Error Code: ${e.code}');
      print('Appwrite Error Message: ${e.message}');
      print('Appwrite Error Type: ${e.type}');
    }
  }
}
