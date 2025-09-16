public class SetPlanCodeOnContactHandler {
    public static Boolean hasRun = false;
    
    public static void onbeforeUpdate(List<Contact> newList){
        UpdateContact(newList);
    }
    
    public static void UpdateContact(List<Contact> newlist){  
        
        Set<Id> ownerIds = new Set<Id>();       
        
        for(Contact con : newlist){
            if(con.OwnerId != Null){
                ownerIds.add(con.OwnerId);
            }
            
        }
        
        Map<Id, TR1__Job__c> jobMap = new Map<Id, TR1__Job__c>();
        if (!ownerIds.isEmpty()){
            system.debug('============================= ownerIds : '+ownerIds);
            system.debug('============================= job : '+[SELECT Id, Plan_Code__c, Plan_Code__r.Branch_Name__c, Plan_Code__r.Division_Code__c, OwnerId FROM TR1__Job__c]);
            for (TR1__Job__c job : [SELECT Id, Plan_Code__c, Plan_Code__r.Branch_Name__c, Plan_Code__r.Division_Code__c, OwnerId FROM TR1__Job__c WHERE OwnerId IN :ownerIds]) {
                if (job.Plan_Code__c != null) {
                    jobMap.put(job.OwnerId, job);
                    
                }
            }
        }
        Map<String, String> mapOfLookingFor = new Map<String, String>();
        mapOfLookingFor.put('IND', 'Industrial');
        mapOfLookingFor.put('HGV', 'Driving');
        mapOfLookingFor.put('RES', 'Care');
        mapOfLookingFor.put('COM', 'Commercial');
        
        for (Contact con : newlist) {
            if (con.OwnerId != null && jobMap.containsKey(con.OwnerId)){
                con.Plan_Code__c = jobMap.get(con.OwnerId).plan_code__c;
                con.Branches__c = jobMap.get(con.OwnerId).Plan_Code__r.Branch_Name__c;
                if(mapOfLookingFor.containsKey(jobMap.get(con.OwnerId).Plan_Code__r.Division_Code__c)){
                    con.What_kind_of_work_are_you_looking_for__c = mapOfLookingFor.get(jobMap.get(con.OwnerId).Plan_Code__r.Division_Code__c);
                }
            }
        }
        
    }
    
}