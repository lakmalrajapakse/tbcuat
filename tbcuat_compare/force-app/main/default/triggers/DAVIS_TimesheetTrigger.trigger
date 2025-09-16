trigger DAVIS_TimesheetTrigger on Sirenum__Timesheet__c (after insert, after update) {
    Set<Id> timesheetIdsToCheck = new Set<Id>();

    for (Sirenum__Timesheet__c ts : Trigger.new) {
        Boolean isApprovedNow = ts.Status__c == 'Approved';
        Boolean wasApprovedBefore = Trigger.isUpdate ? Trigger.oldMap.get(ts.Id).Status__c == 'Approved' : false;

        if ((Trigger.isInsert && isApprovedNow) ||
            (Trigger.isUpdate && isApprovedNow && !wasApprovedBefore)) {
            timesheetIdsToCheck.add(ts.Id);
        }
    }

    if (timesheetIdsToCheck.isEmpty()) return;

    // Query related data including Sirenum__Team__c
    List<Sirenum__Timesheet__c> relevantTimesheets = [
        SELECT Id, Sirenum__Worker__c,
               Sirenum__Team__r.Job_Role_is_Driver__c
        FROM Sirenum__Timesheet__c
        WHERE Id IN :timesheetIdsToCheck
          AND Sirenum__Worker__r.DVLA_License_Check__c = false
          AND Sirenum__Team__r.Job_Role_is_Driver__c = true
    ];

    Map<Id,Contact> contactIdsToUpdate = new Map<Id,Contact>();
    for (Sirenum__Timesheet__c ts : relevantTimesheets) {
        contactIdsToUpdate.put(ts.Sirenum__Worker__c,new Contact(
            Id = ts.Sirenum__Worker__c,
            DVLA_License_Check__c = true
        ));
    }

    if (contactIdsToUpdate.isEmpty()) return;
    
    update contactIdsToUpdate.values();
}