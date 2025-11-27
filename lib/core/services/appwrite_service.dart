import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:expense_tracker/core/constants/appwrite_constants.dart';
import 'package:expense_tracker/features/months/models/month.dart';
import 'package:expense_tracker/features/transactions/models/transaction.dart';
import 'package:expense_tracker/features/transactions/models/transaction_template.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appwriteServiceProvider = Provider<AppwriteService>((ref) {
  return AppwriteService();
});

class AppwriteService {
  late Client _client;
  late Account _account;
  late Databases _databases;

  AppwriteService() {
    _client = Client()
      ..setEndpoint(AppwriteConstants.endpoint)
      ..setProject(AppwriteConstants.projectId);

    _account = Account(_client);
    _databases = Databases(_client);
  }

  // Auth
  Future<models.Session> login(String email, String password) async {
    try {
      return await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
    } catch (e) {
      // Check if session already exists or handle other errors
      rethrow;
    }
  }

  Future<models.User> getUser() async {
    return await _account.get();
  }

  Future<void> logout() async {
    await _account.deleteSession(sessionId: 'current');
  }

  // Database - Months
  Future<Month> createMonth({
    required String name,
    required int year,
    required int monthIndex,
  }) async {
    final id = ID.unique();
    final doc = await _databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.monthsCollectionId,
      documentId: id,
      data: {
        'name': name,
        'year': year,
        'month_index': monthIndex,
        'total_income': 0.0,
        'total_expense': 0.0,
        'remaining_balance': 0.0,
      },
    );
    return Month.fromJson(doc.data);
  }

  Future<List<Month>> getMonths() async {
    final result = await _databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.monthsCollectionId,
      queries: [
        Query.orderDesc('year'),
        Query.orderDesc('month_index'),
      ],
    );
    return result.documents.map((e) => Month.fromJson(e.data)).toList();
  }

  // Database - Transactions
  Future<TransactionModel> createTransaction({
    required String monthId,
    required CategoryMain categoryMain,
    required String title,
    required double amount,
    required bool isFixed,
  }) async {
    final id = ID.unique();
    final doc = await _databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.transactionsCollectionId,
      documentId: id,
      data: {
        'month_id': monthId,
        'category_main': _categoryToString(categoryMain),
        'title': title,
        'amount': amount,
        'is_fixed': isFixed,
      },
    );
    return TransactionModel.fromJson(doc.data);
  }

  Future<List<TransactionModel>> getTransactions(String monthId) async {
    final result = await _databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.transactionsCollectionId,
      queries: [
        Query.equal('month_id', monthId),
      ],
    );
    return result.documents.map((e) => TransactionModel.fromJson(e.data)).toList();
  }

  Future<TransactionModel> updateTransaction({
    required String transactionId,
    required String monthId,
    required CategoryMain categoryMain,
    required String title,
    required double amount,
    required bool isFixed,
  }) async {
    final doc = await _databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.transactionsCollectionId,
      documentId: transactionId,
      data: {
        'month_id': monthId,
        'category_main': _categoryToString(categoryMain),
        'title': title,
        'amount': amount,
        'is_fixed': isFixed,
      },
    );
    return TransactionModel.fromJson(doc.data);
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _databases.deleteDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.transactionsCollectionId,
      documentId: transactionId,
    );
  }

  Future<void> updateMonthTotals(String monthId) async {
    // Get all transactions for this month
    final transactions = await getTransactions(monthId);
    
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    
    for (var transaction in transactions) {
      if (transaction.categoryMain == CategoryMain.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }
    
    double remainingBalance = totalIncome - totalExpense;
    
    // Update the month document
    await _databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.monthsCollectionId,
      documentId: monthId,
      data: {
        'total_income': totalIncome,
        'total_expense': totalExpense,
        'remaining_balance': remainingBalance,
      },
    );
  }

  // Business Logic: Generate Next Month
  // IMPORTANT: This method copies templates into new months as independent transactions.
  // Changes to templates will NOT affect existing months, only future months created
  // after the template change. This ensures data integrity and prevents unintended
  // modifications to historical data.
  Future<String> generateNextMonth({
    required String previousMonthId,
    required String newMonthName,
    required int newYear,
    required int newMonthIndex,
  }) async {
    // 1. Create the new month with zero totals
    final newMonth = await createMonth(
      name: newMonthName,
      year: newYear,
      monthIndex: newMonthIndex,
    );

    // 2. Fetch all templates (fixed expenses/income) from the templates collection
    final templates = await getTemplates();
    print('Generating next month with ${templates.length} templates');

    // 3. Create independent transactions from templates in the new month
    // These are COPIES of the templates, not references. Each month owns its transactions.
    // Users can modify these transactions without affecting:
    //   - The original templates
    //   - Transactions in other months
    for (var template in templates) {
      print('Copying template: ${template.title} to month ${newMonth.id}');
      await createTransaction(
        monthId: newMonth.id,
        categoryMain: template.categoryMain,
        title: template.title,
        amount: template.amount,
        isFixed: false, // These are now regular transactions, not linked to templates
      );
    }

    // 4. Update month totals to reflect the copied transactions
    await updateMonthTotals(newMonth.id);
    print('Month generation complete with ${templates.length} transactions copied');

    // Return the new month ID so caller can switch to it
    return newMonth.id;
  }

  // ===== TEMPLATE METHODS =====
  // Templates are stored separately from transactions. They serve as blueprints
  // for creating recurring transactions when a new month is generated.
  //
  // Template Behavior:
  // - Templates are independent from month transactions
  // - Modifying a template does NOT affect existing months
  // - Templates are only used when creating NEW months
  // - Each month gets COPIES of templates, not references

  Future<List<TransactionTemplate>> getTemplates() async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.templatesCollectionId,
      );

      print('Templates fetched: ${docs.documents.length} templates found');
      return docs.documents
          .map((doc) => TransactionTemplate.fromJson(doc.data))
          .toList();
    } catch (e) {
      print('Error fetching templates: $e');
      rethrow;
    }
  }

  Future<TransactionTemplate> createTemplate({
    required CategoryMain categoryMain,
    required String title,
    required double amount,
  }) async {
    try {
      final id = ID.unique();
      print('Creating template: $title with amount $amount in category ${_categoryToString(categoryMain)}');
      final doc = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.templatesCollectionId,
        documentId: id,
        data: {
          'category_main': _categoryToString(categoryMain),
          'title': title,
          'amount': amount,
        },
      );
      print('Template created successfully: ${doc.$id}');
      return TransactionTemplate.fromJson(doc.data);
    } catch (e) {
      print('Error creating template: $e');
      rethrow;
    }
  }

  Future<TransactionTemplate> updateTemplate({
    required String templateId,
    required CategoryMain categoryMain,
    required String title,
    required double amount,
  }) async {
    final doc = await _databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.templatesCollectionId,
      documentId: templateId,
      data: {
        'category_main': _categoryToString(categoryMain),
        'title': title,
        'amount': amount,
      },
    );
    return TransactionTemplate.fromJson(doc.data);
  }

  Future<void> deleteTemplate(String templateId) async {
    await _databases.deleteDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.templatesCollectionId,
      documentId: templateId,
    );
  }

  // Helper method to create or update template by title (avoids duplicates)
  Future<void> createOrUpdateTemplateByTitle({
    required CategoryMain categoryMain,
    required String title,
    required double amount,
  }) async {
    try {
      // Check if a template with this title already exists
      final templates = await getTemplates();
      final existingTemplate = templates.where((t) => t.title == title).firstOrNull;

      if (existingTemplate != null) {
        // Update existing template
        print('Updating existing template: $title (ID: ${existingTemplate.id})');
        await updateTemplate(
          templateId: existingTemplate.id,
          categoryMain: categoryMain,
          title: title,
          amount: amount,
        );
      } else {
        // Create new template
        print('Creating new template: $title');
        await createTemplate(
          categoryMain: categoryMain,
          title: title,
          amount: amount,
        );
      }
    } catch (e) {
      print('Error in createOrUpdateTemplateByTitle: $e');
      rethrow;
    }
  }

  // Helper method to delete template by title
  Future<void> deleteTemplateByTitle(String title) async {
    try {
      final templates = await getTemplates();
      final template = templates.where((t) => t.title == title).firstOrNull;

      if (template != null) {
        print('Deleting template: $title (ID: ${template.id})');
        await deleteTemplate(template.id);
      } else {
        print('No template found with title: $title');
      }
    } catch (e) {
      print('Error in deleteTemplateByTitle: $e');
      rethrow;
    }
  }

  // ===== DELETE MONTH =====
  
  Future<void> deleteMonth(String monthId) async {
    // 1. Delete all transactions in this month
    final transactions = await getTransactions(monthId);
    for (var transaction in transactions) {
      await deleteTransaction(transaction.id);
    }
    
    // 2. Delete the month itself
    await _databases.deleteDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.monthsCollectionId,
      documentId: monthId,
    );
  }

  String _categoryToString(CategoryMain category) {
    switch (category) {
      case CategoryMain.income:
        return 'Income';
      case CategoryMain.mandatory:
        return 'Mandatory';
      case CategoryMain.optional:
        return 'Optional';
      case CategoryMain.debt:
        return 'Debt';
      case CategoryMain.savings:
        return 'Savings';
    }
  }

  CategoryMain _parseCategory(String value) {
    switch (value) {
      case 'Income':
        return CategoryMain.income;
      case 'Mandatory':
        return CategoryMain.mandatory;
      case 'Optional':
        return CategoryMain.optional;
      case 'Debt':
        return CategoryMain.debt;
      case 'Savings':
        return CategoryMain.savings;
      default:
        return CategoryMain.optional;
    }
  }
}
