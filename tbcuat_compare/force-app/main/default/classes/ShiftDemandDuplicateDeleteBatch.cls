public with sharing class ShiftDemandDuplicateDeleteBatch implements Database.Batchable<sObject> {
    Datetime fromDate;
    String extraFilter;
    Boolean doDelete;

    public ShiftDemandDuplicateDeleteBatch(Datetime fromDate, String extraFilter, Boolean doDelete) {
        this.fromDate = fromDate;
        this.extraFilter = extraFilter;
        this.doDelete = doDelete;
    }
    

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime fromDate = this.fromDate;

        String sql = 'SELECT id, s5m__BH4SFJob__c, sirenum__Shift_Date__c from sirenum__Shift__c '
                     + 'where s5m__BH4SFJob__c != null '
                     + 'and sirenum__Contact__c = null '
                     + 'and CreatedDate > :fromDate '                      
                     + ((!Test.isRunningTest()) ? 'and CreatedBy.UserType = \'automatedprocess\' ' : '')
                     + ((this.extraFilter != null) ? this.extraFilter : '');    

        return Database.getQueryLocator(sql);
    }

    public void execute(Database.BatchableContext bc, List<sirenum__Shift__c> scope) {        
        Set<id> jobIds = new Set<id>();        
        Set<Date> dates = new Set<Date>();
        Map<String, sirenum__Shift__c> jobToShifts = new Map<String, sirenum__Shift__c>();

        for (sirenum__Shift__c shift : scope) {
            jobIds.add(shift.s5m__BH4SFJob__c);
            dates.add(shift.sirenum__Shift_Date__c);
            jobToShifts.put(JSON.serialize(new Map<String, Object> {'jobId'=> shift.s5m__BH4SFJob__c, 'date'=> shift.sirenum__Shift_Date__c}), shift);
        }
        
        
        Set<Id> demandsToDelete = new Set<Id>();
        for (String key : getShiftDemands(jobIds, dates)) {
            if (jobToShifts.containsKey(key)) {
                demandsToDelete.add(jobToShifts.get(key).id);
            }
        }
        
        if (demandsToDelete.isEmpty()) {
            return;
        }

        List<sirenum__Shift__c> shiftsToDelete = [select id from sirenum__Shift__c where sirenum__ShiftDemand__c in :demandsToDelete];
        if (this.doDelete) {
            delete shiftsToDelete;
        } 

        List<sirenum__Shift__c> shiftsDemandToDelete = new List<sirenum__Shift__c>();
        for (Id demandId : demandsToDelete) {
            shiftsDemandToDelete.add(new sirenum__Shift__c(id = demandId));
            System.debug('Deleting shift ' + demandId);
        }

        if (this.doDelete) {
            delete shiftsDemandToDelete;
        }        
    }


    private  Set<String>  getShiftDemands (Set<id> jobIds, Set<Date> dates) {
        Set<String> demandKeys = new Set<String>();
        
        for (sirenum__Shift__c shift : [SELECT id, s5m__BH4SFJob__c, sirenum__Shift_Date__c from sirenum__Shift__c 
                                       where  sirenum__Contact__c = null
                                       and sirenum__Shift_Date__c in :dates
                                       and s5m__BH4SFJob__c in :jobIds
                                       and CreatedBy.UserType != 'automatedprocess'
                                       ]) {
            demandKeys.add(JSON.serialize(new Map<String, Object> {'jobId'=> shift.s5m__BH4SFJob__c, 'date'=> shift.sirenum__Shift_Date__c}));
        }

        return demandKeys;
    }

    
    public void finish(Database.BatchableContext bc) {
        //test
    }
}