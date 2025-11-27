# Database Setup Instructions

## Issue: Templates Not Showing

If the Fixed Transactions (Templates) are not showing in your app, it means the `transaction_templates` collection doesn't exist in your Appwrite database.

## Solution: Run the Setup Script

### Step 1: Run the Database Setup Script

```bash
cd "/home/khaled/Documents/Monthly Expense Tracker"
dart run scripts/setup_appwrite.dart
```

This script will create:
1. The `expense_tracker` database
2. The `months` collection
3. The `transactions` collection
4. **The `transaction_templates` collection** (this is what's missing!)

### Step 2: Verify in Appwrite Console

1. Go to https://cloud.appwrite.io/
2. Open your project
3. Navigate to Databases → `expense_tracker`
4. You should see three collections:
   - `months`
   - `transactions`
   - `transaction_templates` ← **This one must exist!**

### Step 3: Check Permissions

Make sure the `transaction_templates` collection has the following permissions:
- Read: Any
- Create: Any
- Update: Any
- Delete: Any

(Note: These are permissive settings for development. In production, you should restrict these!)

## Database Schema

### transaction_templates Collection

| Attribute      | Type   | Size | Required |
|---------------|--------|------|----------|
| category_main | string | 255  | Yes      |
| title         | string | 255  | Yes      |
| amount        | float  | -    | Yes      |

### Valid category_main Values
- `Income`
- `Mandatory`
- `Optional`
- `Debt`
- `Savings`

## How Templates Work

1. **Templates are blueprints** stored separately from transactions
2. When you create a new month with "Copy fixed expenses" checked, the app copies all templates as new transactions
3. **Changes to templates do NOT affect existing months** - only new months created after the change
4. Each month has its own independent copy of transactions

## Testing the Fix

After running the setup script:

1. **Open the app**
2. **Navigate to Fixed Transactions screen** (push pin icon)
3. **Add a new template**:
   - Click the + button
   - Fill in the details (e.g., "Rent", 5000, Mandatory)
   - Save
4. **Verify the template appears** in the list
5. **Create a new month**:
   - Go back to dashboard
   - Click + to add a new month
   - Make sure "Copy fixed expenses" is checked
   - Create the month
6. **Check the new month's transactions** - you should see the template copied

## Debugging

If templates still don't show after running the setup script:

### Check Console Logs

Run the app and check the console output:

```bash
flutter run
```

Look for these log messages:
- `"Loading templates..."` - When opening Fixed Transactions screen
- `"Templates fetched: X templates found"` - Should show how many templates exist
- `"Error fetching templates: ..."` - If there's an error

### Common Errors

1. **Collection not found**: Run the setup script again
2. **Permission denied**: Check collection permissions in Appwrite console
3. **Authentication error**: Make sure you're logged in to the app

## Manual Database Creation (Alternative)

If the script doesn't work, you can create the collection manually:

1. Go to Appwrite Console → Databases → `expense_tracker`
2. Click "Add Collection"
3. Collection ID: `transaction_templates`
4. Name: `Transaction Templates`
5. Click "Create"
6. Add these attributes:
   - `category_main` (String, size 255, required)
   - `title` (String, size 255, required)
   - `amount` (Float, required)
7. Set permissions to allow read/write for testing

## Need Help?

If you're still having issues:
1. Check the console logs for errors
2. Verify all three collections exist in Appwrite
3. Make sure you're logged in to the app
4. Try creating a template manually via Appwrite console to test permissions
