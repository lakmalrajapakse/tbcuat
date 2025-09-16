/**
* @description Test Class for Inpay callout mock
**/
global with sharing class InpayCalloutMock implements HttpCalloutMock {
    
    /**
    * @description Implement respond interface
    **/
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(getBody(getEndpoint(request)));
        response.setStatusCode(200);
        return response;
    }

    /**
    * @description Method to get Body
    **/
    private String getBody(String endpoint){
        String responseBody = '';
        if (endpoint.contains('token')) {
            responseBody = '{ "access_token": "aHbxEuAGNLTTDQ7Qu_m_gj4OhA5N4HR_Tl8xTP_QU-83sarY1l_gqUpxVCSLI_d27GK2z-fG2Ojrn2sb1qoW8K_7040q6rPNtUuVQvUPnRjF1M0J9YLsHC3ugjtW0-RzD-qiL8sbJlzvn4ZXsQSCXHSl7kQP3ojGKoLxmXmXWf0qp3JZ-RDuBVPDznex_57Kx8GO8NZBRNBGhlPzjLQs8SVMTaf5xHodDdU-G97IaKyC1ujop8sRx9EpIH2s7a66TrXTb5gJERi-mCvF-SfXY8Cq_ekJUNyyv2v8dlg29SE", "token_type": "bearer", "expires_in": 1199 }';
        } else if (endpoint.contains('HolidayScheme')) {
            responseBody = '[ { "SchemeName": "Holiday Scheme", "RolledOverDays": 10.000000000, "EffectiveDate": "2024-10-22T00:00:00", "AccrueDaysOverride": null, "AccruedYTD": 0.00000000, "TakenYTD": 0.0000000000000, "AverageRate": 0.0000, "AllowNegative": false, "EndDate": null, "AverageRateOverride": null } ]';
        }
        return responseBody;
    }

    /**
    * @description Method to get Method name
    **/
    private String getEndpoint(HTTPRequest request){
        return request.getEndpoint();
    }
}