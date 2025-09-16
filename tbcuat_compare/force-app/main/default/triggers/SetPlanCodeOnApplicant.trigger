trigger SetPlanCodeOnApplicant on TR1__Application_V2__c (After insert) {
if(trigger.isAfter && ((UserInfo.getUserId().substring(0, 15) == Label.Veritone_Site_Guest_User_Id) || test.isRunningTest())){
        if(trigger.isInsert || Trigger.isUpdate){
            SetPlanCodeOnApplicantHandler.onbeforeUpdate(trigger.new);
        } 
    }
}