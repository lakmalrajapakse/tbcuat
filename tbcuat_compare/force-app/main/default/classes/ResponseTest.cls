@isTest
public class ResponseTest {

    @isTest
    static void testSuccessResponse() {
        // Create test records for Mass_Message_Manager__c object
        Mass_Message_Manager__c managerRecord = new Mass_Message_Manager__c(
            Email_Leaves_Activity__c = false,
            Enable_Email__c = true,
            Enable_Push__c = true,
            Enable_SMS__c = true,
            Reply_To__c = 'test@gmail.com',
            Subject__c = 'New Message'
        );

        // Insert the record
        insert managerRecord;

        // Create an instance of SuccessResponse with the managerRecord
        Response.SuccessResponse successResponse = new Response.SuccessResponse(managerRecord);

        // Now we can write assertions to test the successResponse object
        System.assertEquals(200, successResponse.statusCode);
        System.assertEquals(true, successResponse.success);
        System.assertEquals(managerRecord, successResponse.responseObject);
        // Add more assertions as needed
    }

    @isTest
    static void testErrorResponse() {
        // Create test records for our custom objects as needed
        Mass_Message_Manager__c managerRecord = new Mass_Message_Manager__c(
            Email_Leaves_Activity__c = false,
            Enable_Email__c = true,
            Enable_Push__c = true,
            Enable_SMS__c = true,
            Reply_To__c = 'test@gmail.com',
            Subject__c = 'New Message'
        );

        // Insert the record
        insert managerRecord;

        // Create an instance of ErrorResponse with the records
        Response.ErrorResponse errorResponse1 = new Response.ErrorResponse('Error Message');
        Response.ErrorResponse errorResponse2 = new Response.ErrorResponse(managerRecord, 'Custom Error Message');

        // Now we can write assertions to test the errorResponse objects
        System.assertEquals(400, errorResponse1.statusCode);
        System.assertEquals(false, errorResponse1.success);
        System.assertEquals('Error Message', errorResponse1.message);

        // Add more assertions as needed for errorResponse2 and other scenarios
    }

 
    @isTest
    static void testSuccessResponseWithObjectAndString() {
        // Create test records for our custom objects as needed
        // Replace placeholders with actual API names and field values

        // Create a test Mass_Message_Manager__c record
        Mass_Message_Manager__c managerRecord = new Mass_Message_Manager__c(
            Email_Leaves_Activity__c = false,
            Enable_Email__c = true,
            Enable_Push__c = true,
            Enable_SMS__c = true,
            Reply_To__c = 'test@gmail.com',
            Subject__c = 'New Message'
        );
        insert managerRecord;

        // Create an instance of SuccessResponse with Object and String parameters
        Response.SuccessResponse successResponse = new Response.SuccessResponse(managerRecord, 'Custom Message');

        // Now we can write assertions to test the successResponse object
        System.assertEquals(200, successResponse.statusCode);
        System.assertEquals(true, successResponse.success);
        System.assertEquals('Custom Message', successResponse.message);
        System.assertEquals(managerRecord, successResponse.responseObject);
        // Add more assertions as needed
    }

    @isTest
    static void testErrorResponseWithObject() {
        // Create test records for our custom objects as needed
        // Replace placeholders with actual API names and field values

        // Create a test Mass_Message__c record
        Mass_Message__c messageRecord = new Mass_Message__c(
            // Set field values based on our object structure
        );
        insert messageRecord;

        // Create an instance of ErrorResponse with Object parameter
        Response.ErrorResponse errorResponse = new Response.ErrorResponse(messageRecord);

        // Now we can write assertions to test the errorResponse object
        System.assertEquals(400, errorResponse.statusCode);
        System.assertEquals(false, errorResponse.success);
        System.assertEquals(null, errorResponse.message); // Message should be null when not provided
        System.assertEquals(messageRecord, errorResponse.responseObject);
        // Add more assertions as needed
    }



    // Additional test methods for Response and other scenarios

}