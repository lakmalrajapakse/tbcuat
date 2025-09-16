/**
*  @description Apex class to manage intime webservice
**/
public with sharing class IntimeWebservice {

    /**
    *  @description Method to get record from intime
    **/
    public static HttpResponse getRecord(IntimeObjectPayload__mdt intimeObjectPayload, List<String> recordValuesList) {
        HttpResponse httpResponse = HttpClient.sendRequest(
            String.format(intimeObjectPayload.Payload__c,recordValuesList),
            new Map<String,String>{
                'Content-Type' => 'text/xml; charset=utf-8',
                'SOAPAction' => intimeObjectPayload.MethodName__c
            }
        );
        return httpResponse;
    }

    /**
    *  @description Method to post record in intime
    **/
    public static HttpResponse createOrUpdateRecord(IntimeObjectPayload__mdt intimeObjectPayload, List<String> recordValuesList) {
        HttpResponse httpResponse = HttpClient.sendRequest(
            String.format(intimeObjectPayload.Payload__c,recordValuesList),
            new Map<String,String>{
                'Content-Type' => 'text/xml; charset=utf-8',
                'SOAPAction' => intimeObjectPayload.MethodName__c
            }
        );
        return httpResponse;
    }

    /**
    *  @description Method to get modified items from intime
    **/
    public static HttpResponse getModifiedItems(List<String> recordValuesList) {
        String payload = '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'+
                            '<soap:Body>'+
                                '<ns:getModifiedItemsWithRefCodeByType xmlns:ns="http://v3_12.webservices.intime.ipfour.com/xsd">'+
                                    '<ns:token>{0}</ns:token>'+
                                    '<ns:since>{1}</ns:since>'+
                                    '<ns:types>{2}</ns:types>'+
                                '</ns:getModifiedItemsWithRefCodeByType>'+
                            '</soap:Body>'+
                        '</soap:Envelope>';
        HttpResponse httpResponse = HttpClient.sendRequest(
            String.format(payload,recordValuesList),
            new Map<String,String>{
                'Content-Type' => 'text/xml; charset=utf-8',
                'SOAPAction' => 'urn:getModifiedItemsWithRefCodeByType'
            }
        );
        return httpResponse;
    }

    /**
    *  @description Method to fetch contractor payslips
    **/
    public static HttpResponse getContractorPayslip(String intimeWorkerId) {
        String payload = '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'+
                            '<soap:Body>'+
                                '<ns:getURLForContractorsPayslip xmlns:ns="http://v3_12.webservices.intime.ipfour.com/xsd">'+
                                    '<ns:token>'+IntimeSyncHelper.getToken()+'</ns:token>'+
                                    '<ns:userId>'+intimeWorkerId+'</ns:userId>'+
                                    '<ns:daily>false</ns:daily>'+
                                '</ns:getURLForContractorsPayslip>'+
                            '</soap:Body>'+
                        '</soap:Envelope>';
        HttpResponse httpResponse = HttpClient.sendRequest(
            payload,
            new Map<String,String>{
                'Content-Type' => 'text/xml; charset=utf-8',
                'SOAPAction' => 'urn:getURLForContractorsPayslip'
            }
        );
        return httpResponse;
    }

    /**
    *  @description Method to get make leaver by id in intime
    **/
    public static HttpResponse makeLeaverById(String payload) {
        HttpResponse httpResponse = HttpClient.sendRequest(
            payload,
            new Map<String,String>{
                'Content-Type' => 'text/xml; charset=utf-8',
                'SOAPAction' => 'urn:makeLeaverById'
            }
        );
        return httpResponse;
    }

    /**
    *  @description Method to get search holiday claims
    **/
    public static HttpResponse searchHolidayClaims(String payload) {
        HttpResponse httpResponse = HttpClient.sendRequest(
            payload,
            new Map<String,String>{
                'Content-Type' => 'text/xml; charset=utf-8',
                'SOAPAction' => 'urn:searchHolidayClaimRefCodes'
            }
        );
        return httpResponse;
    }

    /**
    *  @description Method to get search holiday claims
    **/
    public static HttpResponse getHolidayClaimsByRefs(String payload) {
        HttpResponse httpResponse = HttpClient.sendRequest(
            payload,
            new Map<String,String>{
                'Content-Type' => 'text/xml; charset=utf-8',
                'SOAPAction' => 'urn:getHolidayClaimsByRefCodes'
            }
        );
        return httpResponse;
    }

}