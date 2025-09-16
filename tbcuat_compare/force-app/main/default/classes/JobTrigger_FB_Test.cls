@isTest
public class JobTrigger_FB_Test {

    @isTest
    public static void testSuccessJobTrigger() {
        Test.startTest();
        
        // Create and insert a Veritone Credentials record
        VRT__Veritone_Credentials__c cred = new VRT__Veritone_Credentials__c(
            VRT__Advert_Channels_Status__c = 'https://beanwidget.adcourier.com/distro/advert_status',
            VRT__Advert_Deleting_Endpoint__c = 'https://beanwidget.adcourier.com/distro/delete',
            VRT__Advert_Responses_URL__c = 'https://beanwidget.adcourier.com/candidates/responses',
            VRT__API_Key__c = '3814540674',
            VRT__Client_Id__c = 'healthcareaustraliauattest',
            VRT__Posting_Endpoint__c = 'https://beanwidget.adcourier.com/distro/dashboardpost',
            VRT__Secret_Key__c = 'fa93bbfdae25f532cbfb66ec82153fe4ad09bffb8649d5bc8370dfb755de913632'
        );
        insert cred;
        System.assertNotEquals(null, cred.Id, 'Veritone Credentials record should be inserted');

        // Create and insert an Account record
        Account acc = new Account(
            Name = 'Test',
            TR1__Status__c = 'Credit Alert',
            BillingCity = 'test',
            BillingCountry = 'United Kingdom',
            BillingPostalCode = '123123',
            BillingStreet = 'test'
        );
        insert acc;
        System.assertNotEquals(null, acc.Id, 'Account record should be inserted');

        // Create and insert a Contact record
        Contact con = new Contact(
            LastName = 'ACB',
            FirstName = 'XYZ',
            AccountId = acc.Id,
            Email = 'test@gmail.com'
        );
        insert con;
        System.assertNotEquals(null, con.Id, 'Contact record should be inserted');

        // Create and insert a TR1__Job__c record
        TR1__Job__c job = new TR1__Job__c(
            TR1__Contact__c = con.Id,
            Name = 'Test Dev',
            RecordTypeId = Schema.SObjectType.TR1__Job__c.getRecordTypeInfosByName().get('Shift Work').getRecordTypeId(),
            TR1__Account__c = acc.Id,
            TR1__Most_Advanced_Stage__c = null,
            Job_Posted__c = true,
            TR1__Status__c = 'Open',
            Advert_Deletion__c = 'DeleteWhenClosed',
            TR1__Fee_Percentage__c = 10
        );
        insert job;
        System.assertNotEquals(null, job.Id, 'Job record should be inserted');
        
        // Verify initial field values
        System.assertEquals('Open', job.TR1__Status__c, 'Job status should be Open');
        System.assertEquals(true, job.Job_Posted__c, 'Job should be marked as posted');
        System.assertEquals('DeleteWhenClosed', job.Advert_Deletion__c, 'Advert deletion should be DeleteWhenClosed');

        // Update the Job record
        job.TR1__Status__c = 'Closed';
        update job;
        
        Test.stopTest();

        // **Wait for Future Method to Complete**
        Boolean jobPostedUpdated = false;
        Integer retryCount = 0;
        Integer maxRetries = 5; // Limit retries to avoid infinite loop

        while (!jobPostedUpdated && retryCount < maxRetries) {
            // Re-query the job record
            TR1__Job__c updatedJob = [SELECT Job_Posted__c FROM TR1__Job__c WHERE Id = :job.Id];

            if (!updatedJob.Job_Posted__c) {
                jobPostedUpdated = true;
                System.assertEquals(false, updatedJob.Job_Posted__c, 'Job should be marked as false');
            } else {
                // Wait before retrying (simulate async delay)
                retryCount++;
            }
        }

        System.assert(jobPostedUpdated, 'Future method did not update Job_Posted__c in expected time.');
    }
}