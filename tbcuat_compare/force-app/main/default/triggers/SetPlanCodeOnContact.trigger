trigger SetPlanCodeOnContact on Contact (before insert, before update) {
    /*if(trigger.isBefore && ((UserInfo.getUserId().substring(0, 15) == Label.Veritone_Site_Guest_User_Id) || test.isRunningTest()) && !SetPlanCodeOnContactHandler.hasRun){
        SetPlanCodeOnContactHandler.hasRun = false;
        if(trigger.isInsert || Trigger.isUpdate){
            SetPlanCodeOnContactHandler.onbeforeUpdate(trigger.new);
        } 
    }*/
}