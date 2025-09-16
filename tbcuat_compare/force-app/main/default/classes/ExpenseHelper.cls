public with sharing class ExpenseHelper {
    public static void manageExpenses(List<sirenum__Expense__c> newExpenseList, Map<Id, sirenum__Expense__c> oldExpenseMap) {
        Set<Id> timesheetIds = new Set<Id>();

        if (oldExpenseMap == null) {
            // If oldExpenseMap is null, it means this is an insert operation
            for (sirenum__Expense__c expense : newExpenseList) {
                if (expense.sirenum__Timesheet__c != null) {
                    timesheetIds.add(expense.sirenum__Timesheet__c);
                }
            }
        } else if (newExpenseList == null) {
            // If newExpenseList is null or empty, it means this is a delete operation
            for (sirenum__Expense__c expense : oldExpenseMap.values()) {
                if (expense.sirenum__Timesheet__c != null) {
                    timesheetIds.add(expense.sirenum__Timesheet__c);
                }
            }
        } else {            
            for (sirenum__Expense__c expense : newExpenseList) {
                if (expense.sirenum__Timesheet__c == null &&  oldExpenseMap.get(expense.id)?.sirenum__Timesheet__c == null) {
                    continue;                    
                }

                if (expense.ChargeExpenseValue__c == oldExpenseMap.get(expense.id)?.ChargeExpenseValue__c && expense.Expense_Value__c == oldExpenseMap.get(expense.id)?.Expense_Value__c &&
                    expense.sirenum__Timesheet__c == oldExpenseMap.get(expense.id)?.sirenum__Timesheet__c) {
                    continue;
                }

                timesheetIds.add(expense.sirenum__Timesheet__c);
            }
        }
        
        if (timesheetIds.isEmpty()) {
            return; // No timesheets to process
        }

        List <AggregateResult> groupedResults = 
           [SELECT sirenum__Timesheet__c, sirenum__Expense_Type__r.TAX_VAT__c isTaxed, sum(ChargeExpenseValue__c) totalExpenseCharge, sum(Expense_Value__c) totalExpensePay from sirenum__Expense__c 
            WHERE sirenum__Timesheet__c IN :timesheetIds 
            AND (ChargeExpenseValue__c != null OR Expense_Value__c != null)
            GROUP BY sirenum__Timesheet__c, sirenum__Expense_Type__r.TAX_VAT__c];
        
        Map<id, sirenum__Timesheet__c> timesheetsToUpdate = new Map<id, sirenum__Timesheet__c>();
        for (AggregateResult ar : groupedResults)  {
            sirenum__Timesheet__c timesheet = timesheetsToUpdate.get((Id)ar.get('sirenum__Timesheet__c'));
            if (timesheet == null) {
                timesheet = new sirenum__Timesheet__c(Id = (Id)ar.get('sirenum__Timesheet__c'), 
                    sirenum__Non_Taxed_Expenses__c = 0, 
                    sirenum__Taxed_Expenses__c = 0, 
                    Non_Taxed_Charged_Expenses__c = 0, 
                    Taxed_Charged_Expenses__c = 0);
                timesheetsToUpdate.put(timesheet.Id, timesheet);
            }

            if ((Boolean) ar.get('isTaxed') == true) {
                timesheet.sirenum__Taxed_Expenses__c += (ar.get('totalExpensePay') == null) ? 0 : (Decimal)ar.get('totalExpensePay');
                timesheet.Taxed_Charged_Expenses__c += (ar.get('totalExpenseCharge') == null) ? 0 : (Decimal)ar.get('totalExpenseCharge');                
            } else {
                timesheet.sirenum__Non_Taxed_Expenses__c += (ar.get('totalExpensePay') == null) ? 0 : (Decimal)ar.get('totalExpensePay');
                timesheet.Non_Taxed_Charged_Expenses__c += (ar.get('totalExpenseCharge') == null) ? 0 : (Decimal)ar.get('totalExpenseCharge');
            }
            
        }

        if (!timesheetsToUpdate.isEmpty()) {
            update timesheetsToUpdate.values();
        } 
    }     
}