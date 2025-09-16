public class SetPlanCodeOnApplicantHandler {
    
    
    public static void onbeforeUpdate(List<TR1__Application_V2__c> newList){
        UpdateApplicant(newList);
    }
    
    public static void UpdateApplicant(List<TR1__Application_V2__c> newlist){ 
        List<Contact> lstContact = new List<Contact>();
        
        Map<String, String> mapOfLookingFor = new Map<String, String>();
        mapOfLookingFor.put('IND', 'Industrial');
        mapOfLookingFor.put('HGV', 'Driving');
        mapOfLookingFor.put('RES', 'Care');
        mapOfLookingFor.put('COM', 'Commercial');
        
        for(TR1__Application_V2__c app : [SELECT Id, TR1__Applicant__c, TR1__Applicant__r.Plan_Code__c, TR1__Applicant__r.Branches__c, TR1__Job__c, TR1__Job__r.Plan_Code__c,
                                                 TR1__Job__r.Plan_Code__r.Branch_Name__c, TR1__Job__r.Plan_Code__r.Division_Code__c, TR1__Applicant__r.Created_From_Veritone__c,
                                                 TR1__Applicant__r.TR1__Candidate_Status__c, TR1__Applicant__r.Updated_By_Veritone__c, TR1__Applicant__r.Registration_Suitability__c
                                                 FROM TR1__Application_V2__c 
                                                 WHERE Id IN : newlist]){
            if(app.TR1__Applicant__c != null && app.TR1__Job__c != null){
                Contact con = new Contact();
                con.Id = app.TR1__Applicant__c;

                if (app.TR1__Applicant__r.Created_From_Veritone__c || ((app.TR1__Applicant__r.TR1__Candidate_Status__c == 'Offboarded' || app.TR1__Applicant__r.TR1__Candidate_Status__c == 'Rejected') && app.TR1__Applicant__r.Registration_Suitability__c == 'Suitable')) {
                    con.Plan_Code__c = app.TR1__Job__r.Plan_Code__c;
                    con.Branches__c =  app.TR1__Job__r.Plan_Code__r.Branch_Name__c;
                    if(mapOfLookingFor.containsKey(app.TR1__Job__r.Plan_Code__r.Division_Code__c)){
                        con.What_kind_of_work_are_you_looking_for__c = mapOfLookingFor.get(app.TR1__Job__r.Plan_Code__r.Division_Code__c);
                    }
                }

                if (!app.TR1__Applicant__r.Created_From_Veritone__c) {
                    con.Updated_By_Veritone__c = true;
                }
                
                lstContact.add(con);
            }
        }
        
        if(lstContact.size() > 0){
            update lstContact;
        }
    }
    
}