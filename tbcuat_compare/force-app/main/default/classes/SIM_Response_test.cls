/**
 * @description       : 
 * @author            : James Ridge
 * @group             : 
 * @last modified on  : 11-27-2020
 * @last modified by  : James Ridge
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   11-27-2020   James Ridge   Initial Version
**/
@IsTest
public class SIM_Response_test {
    @Istest
    private static void  testResponses() {
        SIM_Response.Response r1 =  new SIM_Response.SuccessResponse();
        String resp = 'Test Response';
        //Success Response
        r1 =  new SIM_Response.SuccessResponse((Object) resp, resp);
        system.assertEquals(true, r1.success);
        r1 =  new SIM_Response.SuccessResponse((Object) resp);
        system.assertEquals(true, r1.success);
        r1 =  new SIM_Response.SuccessResponse(resp);
        system.assertEquals(true, r1.success);
        //Error Response
        r1 =  new SIM_Response.ErrorResponse(resp);
        system.assertEquals(false, r1.success);
        r1 =  new SIM_Response.ErrorResponse((Object) resp, resp);
        system.assertEquals(false, r1.success);
        r1 =  new SIM_Response.ErrorResponse((Object) resp);                
        system.assertEquals(false, r1.success);
    }
}