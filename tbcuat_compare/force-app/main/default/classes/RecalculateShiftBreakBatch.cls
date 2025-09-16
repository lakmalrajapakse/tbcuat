public class RecalculateShiftBreakBatch implements Database.Batchable<SObject>, Database.Stateful {    
    private Map<String, sirenum__Break_definition__c> breakDefinitionMap;
    String adaptiveBatchName;

    private RecalculateShiftBreakBatch(List<sirenum__Break_definition__c> breakDefinitions, String adaptiveBatchName) {
        this.breakDefinitionMap = new Map<String, sirenum__Break_definition__c>();
        for (sirenum__Break_definition__c breakDef : breakDefinitions) {
            if (breakDef.WFM_Contract__c == null && breakDef.sirenum__Team__c == null && breakDef.sirenum__Site__c == null) {
                continue; // Skip if no criteria to match
            }

            String key = JSON.serialize(new Map<String, String>{'WFM_Contract__c'=> breakDef.WFM_Contract__c, 'sirenum__Team__c'=> breakDef.sirenum__Team__c, 'sirenum__Site__c' => breakDef.sirenum__Site__c});
            this.breakDefinitionMap.put(key, breakDef);                        
        }        
        this.adaptiveBatchName = adaptiveBatchName;
    }

    public Boolean hasBreakDefinitionToProcess() {
        return !this.breakDefinitionMap.isEmpty();
    }

    public static void submitBatch( List<sirenum__Break_definition__c> breakDefinitions) {        
        if (breakDefinitions.isEmpty()) {
            return;
        }

        List<sirenum__AdaptiveBatchSettings__c> breakJobs = [select name, sirenum__ChunkSize__c from sirenum__AdaptiveBatchSettings__c where sirenum__Classname__c = 'sirenum.ShiftBreakProcessing' and sirenum__Enabled__c = true limit 1];

        if (breakJobs.isEmpty()) {
            return;
        }

        RecalculateShiftBreakBatch batch = new RecalculateShiftBreakBatch(breakDefinitions, breakJobs[0].Name);
        
        if (batch.hasBreakDefinitionToProcess()) {            
            Database.executeBatch(batch, (breakJobs[0].sirenum__ChunkSize__c != null) ? Integer.valueOf(breakJobs[0].sirenum__ChunkSize__c) : 20);
        }
    }
    
    private Boolean isInBreakDefinition(sirenum__Shift__c shift) {
       return 
          this.breakDefinitionMap.containsKey(JSON.serialize(new Map<String, String>{'WFM_Contract__c'=> shift.sirenum__Contract__c, 'sirenum__Team__c'=> shift.sirenum__Team__c, 'sirenum__Site__c' => shift.sirenum__Site__c}))
          || this.breakDefinitionMap.containsKey(JSON.serialize(new Map<String, String>{'WFM_Contract__c'=> shift.sirenum__Contract__c, 'sirenum__Team__c'=> shift.sirenum__Team__c, 'sirenum__Site__c' => null}))
          || this.breakDefinitionMap.containsKey(JSON.serialize(new Map<String, String>{'WFM_Contract__c'=> shift.sirenum__Contract__c, 'sirenum__Team__c'=> null, 'sirenum__Site__c' => shift.sirenum__Site__c}))
          || this.breakDefinitionMap.containsKey(JSON.serialize(new Map<String, String>{'WFM_Contract__c'=> shift.sirenum__Contract__c, 'sirenum__Team__c' => null, 'sirenum__Site__c' => null}))
          || this.breakDefinitionMap.containsKey(JSON.serialize(new Map<String, String>{'WFM_Contract__c'=> null, 'sirenum__Team__c' => shift.sirenum__Team__c, 'sirenum__Site__c' => shift.sirenum__Site__c}))
          || this.breakDefinitionMap.containsKey(JSON.serialize(new Map<String, String>{'WFM_Contract__c'=> null, 'sirenum__Team__c' => shift.sirenum__Team__c, 'sirenum__Site__c' => null}))
          || this.breakDefinitionMap.containsKey(JSON.serialize(new Map<String, String>{'WFM_Contract__c'=> null, 'sirenum__Team__c' => null, 'sirenum__Site__c' => shift.sirenum__Site__c}))
          ;        
    }
     
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> contractIds = new Set<Id>();
        Set<Id> teamIds = new Set<Id>();
        Set<Id> siteIds = new Set<Id>();
        
        for (sirenum__Break_definition__c br : this.breakDefinitionMap.values()) {
            if (br.WFM_Contract__c != null) 
                contractIds.add(br.WFM_Contract__c);

                if (br.sirenum__Team__c != null) 
                teamIds.add(br.sirenum__Team__c);

            if (br.sirenum__Site__c != null) 
                siteIds.add(br.sirenum__Site__c);
        }

        return Database.getQueryLocator([
            SELECT Id, sirenum__BreakProcessingLastPerformed__c,sirenum__Contract__c,sirenum__Team__c,sirenum__Site__c
            FROM sirenum__Shift__c
            WHERE (sirenum__Contract__c IN :contractIds OR sirenum__Site__c IN :siteIds OR sirenum__Team__c IN : teamIds )
                AND sirenum__Allow_charge__c = false
                AND sirenum__Allow_pay__c = false
                AND Approved__c = false
                AND sirenum__Cancelled__c = false  
                AND sirenum__Contact__c != null                          
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {        
        List<sirenum__Shift__c> shifts = (List<sirenum__Shift__c>)scope;
        List<sirenum__Shift__c> shiftToUpdate = new List<sirenum__Shift__c>();
        for (sirenum__Shift__c shift : shifts) {
            if (isInBreakDefinition(shift)) {
                shift.sirenum__BreakProcessingLastPerformed__c = null;
                shiftToUpdate.add(shift);
            }            
        }

        if (!shiftToUpdate.isEmpty()) {
            update shiftToUpdate;
        }
    }

    
    public void finish(Database.BatchableContext bc) {
        sirenum.AdaptiveInvoker.invokeBatch(this.adaptiveBatchName);
    }
}