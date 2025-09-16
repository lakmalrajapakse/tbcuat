trigger ContactTrigger on Contact (before update) {

    if (Trigger.isBefore && Trigger.isUpdate) {
        // Collect IDs for each job type
        List<Contact> checkDrivingLicenseIds = new List<Contact>();
        List<Contact> sendDriverDetails = new List<Contact>();
        List<Contact> disableDrivers = new List<Contact>();
        Set<Id> contactIds = new Set<Id>();

        //collect contact is to form map of timesheets approved
        for (Contact con:Trigger.new){
            contactIds.add(con.Id);
        }

        for (Contact con : Trigger.new) {
            Contact oldCon = Trigger.oldMap.get(con.Id);

            // Condition 2: Collect IDs for SendDriverDetailsQueueable
            if (oldCon.Davis_Id__c == null && con.DVLA_License_Check__c == true && con.TR1__Candidate_Status__c == 'Registered' && 
                (oldCon.DVLA_License_Check__c != true)) {
                    sendDriverDetails.add(con); //add status to consent requested
            }

             // Condition 3: Collect IDs if they been enabled/disabled //change for registered
             if (oldCon.TR1__Candidate_Status__c != 'Offboarded' && oldCon.Davis_Id__c!=null &&
             con.TR1__Candidate_Status__c == 'Offboarded' && (oldCon.Davis_Status__c == 'Active' || oldCon.Davis_Status__c=='Consent Requested')) {
                disableDrivers.add(con);
            }
        }

        // Enqueue a single job for SendDriverDetailsQueueable
        if (!sendDriverDetails.isEmpty()) {
            DAVIS_ContactHandler.SendDriverDetails(sendDriverDetails);
        }
   
        // Enqueue a single job for SendDriverDetailsQueueable
        if (!disableDrivers.isEmpty()) {
            DAVIS_ContactHandler.DisableDrivers(disableDrivers);
           // System.enqueueJob(new DAVIS_ContactHandler.DisableOrEnableDriverQueueableBulk(disableDrivers));
        }
    }
}