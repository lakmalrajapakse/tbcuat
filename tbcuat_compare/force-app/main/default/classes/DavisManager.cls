public class DavisManager {
    private Davis_Integration_Settings__c integrationSettings;

    public DavisManager() {
        // Fetch integration settings once and store in the instance variable
        this.integrationSettings =  Davis_Integration_Settings__c.getInstance();
    }

    public Davis_Error_Log__c createErrorLog(String contactId,String message,String comments){

        Davis_Error_Log__c errorLog = new Davis_Error_Log__c();
        errorLog.message__c = message+= '\r\n'+comments;
        errorLog.date__c = Datetime.now();
        errorLog.driver__c = contactId;
        return errorLog;
        
    }

    public DriverWrapper deleteDriver(Contact contact) {
        Contact updatedContact;
        List<sirenum__Ticket__c> tickets = new List<sirenum__Ticket__c>();
        Davis_Error_Log__c errorLog;
    
        try {
            if (String.isBlank(contact.Davis_Id__c)) {
                System.debug('Skipping contact without Davis_Id__c: ' + contact.Id);
                return new DriverWrapper(null, tickets,null);
            }
    
            Map<String, Object> requestBody = new Map<String, Object>{
                'CompanyCode' => integrationSettings.Company_Code__c,
                'DriverId' => contact.Davis_Id__c
            };
    
            HttpRequest req = new HttpRequest();
            req.setEndpoint(integrationSettings.Endpoint__c + integrationSettings.Check_Drivers_endpoint__c);
            req.setMethod('DELETE');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-api-Key', this.integrationSettings.API_KEY__c);
            req.setHeader('Authorization', this.integrationSettings.Authorization__c);
            req.setBody(JSON.serialize(requestBody));
            req.setTimeout(120000);
    
            Http http = new Http();
            HttpResponse res = http.send(req);
    
            //System.debug('Request: ' + requestBody);
            //System.debug('Response: ' + res);
    
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                //System.debug('ResponseMap: ' + responseMap);
    
                if (responseMap.containsKey('Status')) {
                    Map<String, Object> statusDetails = (Map<String, Object>) responseMap.get('Status');
                    if (statusDetails.containsKey('Success') && (Boolean) statusDetails.get('Success')) {
                        contact.Davis_Status__c = 'Inactive';
                        contact.Davis_Id__c = null;
                        contact.DVLA_License_Check__c = false;
                        updatedContact = contact;
                    }
                }
            } else {
                String error;
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (responseMap.containsKey('Status')) {
                    Map<String, Object> errorDetails = (Map<String, Object>) responseMap.get('Driver');
                    error = (String) errorDetails.get('Details');
                }
                errorLog = createErrorLog(contact.id,res.getStatus(),error);
            }
    
        } catch (Exception e) {
            errorLog = createErrorLog(contact.id,'',e.getMessage());
        }
    
        return new DriverWrapper(updatedContact, tickets,errorLog);
    }
    

    public DriverWrapper checkDrivingLicense(Contact contact, Boolean hardCheck,List<sirenum__Ticket__c> existingTickets) {
        Contact updatedContact;
        List<sirenum__Ticket__c> tickets = new List<sirenum__Ticket__c>();
        Davis_Error_Log__c errorLog;
    
        try {
            if (String.isBlank(contact.Davis_Id__c)) {
                System.debug('Skipping contact without Davis_Id__c: ' + contact.Id);
                return new DriverWrapper(null, tickets,null);
            }
    
            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-api-Key', integrationSettings.API_KEY__c);
            req.setHeader('Authorization', integrationSettings.Authorization__c);
    
            if (!hardCheck) {
                req.setEndpoint(integrationSettings.Endpoint__c + integrationSettings.Check_Drivers_Licence__c + contact.Davis_Id__c);
                req.setMethod('GET');
            } else {
                req.setEndpoint(integrationSettings.Endpoint__c + integrationSettings.Full_Check_Drivers_Licence__c);
                req.setMethod('POST');
                Map<String, Object> requestBody = new Map<String, Object>{
                    'DriverId' => contact.Davis_Id__c,
                    'CompanyCode' => integrationSettings.Company_Code__c
                };
                req.setBody(JSON.serialize(requestBody));
            }
    
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);
    
            System.debug('Response in checkdirvigln: ' + res);
    
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('ResponseMap checkdriving: ' + responseMap);

                String codeValue;

                if (responseMap.containsKey('Status')) {
                    Map<String, Object> status = (Map<String, Object>) responseMap.get('Status');
                 
                    if (status.containsKey('Success') && !((Boolean) status.get('Success'))) {                        
                        system.debug('Driver check failed');
                        String errorMessage = (String) status.get('Details');
                        errorLog = createErrorLog(contact.id, res.getStatus(), errorMessage);
                        return new DriverWrapper(null, tickets,errorLog);
                    }
                
                    system.debug('status is: '+status);
                    if (status!=null && status.containsKey('Code')) {
                        codeValue = (String) status.get('Code');
                    }
                }
                system.debug('codevalue: '+codevalue);
                if(codeValue=='716'){
                    system.debug('code is 716');
                    contact.Davis_Status__c = 'Consent Requested';
                    updatedContact = contact;
                } 
                else
                if(codeValue!='716') 
                {
                    system.debug('code is not 716');
                    if (responseMap.containsKey('NextCheckDate')) {
                        DateTime nextCheckDate = DateConverter((String) responseMap.get('NextCheckDate'));
                        contact.Next_Check_Date__c = nextCheckDate;
                        contact.Davis_Status__c = 'Active';
                    }
        
                    updatedContact = contact;
                    system.debug('contact is: '+contact);
        
                    Set<String> existingTicketKeys = new Set<String>();
                    
                    if (existingTickets != null) {
                        for (sirenum__Ticket__c ticket : existingTickets) {
                            String key;
                            if(ticket.sirenum__TicketType__r.Offence_Code__c!=null ){
                                key = ticket.sirenum__Valid_from__c + '|' + ticket.sirenum__TicketType__r.Offence_Code__c +  '|' + ticket.sirenum__Owner__c;
                            }
                            else
                            if(ticket.Commenced_date__c!=null){
                                key = ticket.sirenum__Valid_from__c + '|' + ticket.sirenum__TicketType__r.Name +  '|' + ticket.sirenum__Owner__c;
                            }

                            system.debug('key 1: '+key);
                            if(!String.isBlank(key)){
                                existingTicketKeys.add(key);
                            }
                        }
                    }

                    tickets = processResponse(contact, responseMap, existingTicketKeys);
                    system.debug('tickets is: '+tickets);

                    List<Sirenum__Ticket__c> entitlements = processEntitlements(contact,responseMap,existingTicketKeys);
                    system.debug('entitelmentes: '+entitlements);
                    tickets.addAll(entitlements);
                }

            } else {
                String error;
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (responseMap.containsKey('Status')) {
                    Map<String, Object> errorDetails = (Map<String, Object>) responseMap.get('Driver');
                    error = (String) errorDetails.get('Details');
                }
                errorLog = createErrorLog(contact.id,res.getStatus(),error);
            }
    
        } catch (Exception e) {
            errorLog = createErrorLog(contact.id,'',e.getMessage());
        }
    
        return new DriverWrapper(updatedContact, tickets,errorLog);
    }

    private List<sirenum__Ticket__c> processEntitlements(Contact contact, Map<String, Object> responseMap,Set<String> existingTicketKeys) {
        List<sirenum__Ticket__c> tickets = new List<sirenum__Ticket__c>();

        if (responseMap.containsKey('Entitlements')) {
            Object entitlementsObj = responseMap.get('Entitlements');

            if (entitlementsObj instanceof List<Object>) {
                List<Object> entitlementsList = (List<Object>) entitlementsObj;
                Set<String> categories = new Set<String>();

                for (Object entitlementObj : entitlementsList) {
                    if (entitlementObj instanceof Map<String, Object>) {
                        Map<String, Object> entitlement = (Map<String, Object>) entitlementObj;

                        // Create ticket from entitlement details
                        sirenum__Ticket__c ticket = createTicketFromEntitlement(contact, entitlement);
                        if (ticket != null) {
                            String key = ticket.sirenum__Valid_from__c + '|' + ticket.sirenum__Comments__c +  '|' + ticket.sirenum__Owner__c;

                            if (existingTicketKeys!=null && !existingTicketKeys.contains(key)) {
                                tickets.add(ticket);
                                categories.add(ticket.sirenum__Comments__c);
                            }
                        }
                    }
                }
                // Assign ticket types based on categories
                assignTicketTypesByCategory(tickets, categories);
            }
        }
        return tickets;
    }

     // Helper method to create a ticket from an entitlement
     private sirenum__Ticket__c createTicketFromEntitlement(Contact contact, Map<String, Object> entitlement) {
        if (!entitlement.containsKey('Category') || !entitlement.containsKey('Status') || ((String) entitlement.get('Status')) != 'Full') {
            return null;
        }
     
        String category = (String) entitlement.get('Category');
        String commenceDateString = (String) entitlement.get('CommencedDate');
        DateTime commencedDate = DateConverter(commenceDateString);
        String expiryDateString = (String) entitlement.get('ExpiryDate');
        DateTime expiryDate = DateConverter(expiryDateString);
        

        sirenum__Ticket__c ticket = new sirenum__Ticket__c();
        ticket.sirenum__Status__c = 'Confirmed';
        ticket.sirenum__Comments__c = 'Category '+category.trim()+' - Licence';
        ticket.Commenced_date__c = commencedDate;
        ticket.sirenum__Owner__c = contact.Id;
        ticket.sirenum__Revoked__c = false;

        if (commencedDate != null) {
            ticket.sirenum__Valid_from__c = commencedDate.date();
        }

        if (expiryDate != null) {
            ticket.sirenum__Valid_until__c = expiryDate.date();
        }

        system.debug('ticket before creation');
        return ticket;
    }

     // Helper method to assign ticket types based on categories
     private void assignTicketTypesByCategory(List<sirenum__Ticket__c> tickets, Set<String> categories) {
        if (categories.isEmpty()) return;

        Map<String, Id> categoryToTicketTypeIdMap = new Map<String, Id>();
        List<sirenum__TicketType__c> ticketTypes = [SELECT Id,Name,Competency_Category__c FROM sirenum__TicketType__c WHERE Name IN :categories];
        for (sirenum__TicketType__c ticketType : ticketTypes) {
            categoryToTicketTypeIdMap.put(ticketType.Name, ticketType.Id);
        }

        for (sirenum__Ticket__c ticket : tickets) {
            ticket.sirenum__TicketType__c = categoryToTicketTypeIdMap.get(ticket.sirenum__Comments__c);
        }
    }
    
    // Helper method to process response and generate tickets
    private List<sirenum__Ticket__c> processResponse(Contact contact, Map<String, Object> responseMap, Set<String> existingTicketKeys) {
        List<sirenum__Ticket__c> tickets = new List<sirenum__Ticket__c>();

        if (responseMap.containsKey('Endorsements')) {
            Object endorsementsObj = responseMap.get('Endorsements');

            if (endorsementsObj instanceof List<Object>) {
                List<Object> endorsementsList = (List<Object>) endorsementsObj;
                Set<String> offenceCodes = new Set<String>();

                for (Object endorsementObj : endorsementsList) {
                    if (endorsementObj instanceof Map<String, Object>) {
                        Map<String, Object> endorsement = (Map<String, Object>) endorsementObj;

                        sirenum__Ticket__c ticket = createTicketFromEndorsement(contact, endorsement);
                        if (ticket != null) {
                            String key = ticket.sirenum__Valid_from__c  + '|' + ticket.sirenum__Comments__c + '|' + ticket.sirenum__Owner__c;
                            if (existingTicketKeys!=null && !existingTicketKeys.contains(key)) {
                                tickets.add(ticket);
                                offenceCodes.add(ticket.sirenum__Comments__c);
                                existingTicketKeys.add(key);
                            }
                        }
                    }
                }

                assignTicketTypes(tickets, offenceCodes);
            }
        }
        return tickets;
    }

    // Helper method to create a ticket from an endorsement
    private sirenum__Ticket__c createTicketFromEndorsement(Contact contact, Map<String, Object> endorsement) {
        if (!endorsement.containsKey('OffenceDate') || !endorsement.containsKey('Points') || !endorsement.containsKey('OffenceCode')) {
            return null;
        }

        DateTime convictionDateTime;
        if (endorsement.get('ConvictionDate') != null) {    
            String convictionDateString = (String) endorsement.get('ConvictionDate');
            convictionDateTime = DateConverter(convictionDateString);
        }
        
        DateTime sentenceDateTime;
        if (endorsement.get('SentenceDate') != null) {
            String sentenceDateString = (String) endorsement.get('SentenceDate');
            sentenceDateTime = DateConverter(sentenceDateString);
        } 

        DateTime disqualifiedDateTime;
        if (endorsement.get('DisqualifiedEndDate') != null) {
            String disqualifiedEndDateString = (String) endorsement.get('DisqualifiedEndDate');
            disqualifiedDateTime = DateConverter(disqualifiedEndDateString);
        }
        
        String offenceDateString = (String) endorsement.get('OffenceDate');
        DateTime offenceDateTime = DateConverter(offenceDateString);

        String endTime = (String) endorsement.get('EndDate');
        DateTime endDateTime = DateConverter(endTime);
        
        Integer points = (Integer) endorsement.get('Points');
        String offenceCode = (String) endorsement.get('OffenceCode');

        Boolean isDisqualified = false;
        if (endorsement.containsKey('IsDisqualified')) {
            isDisqualified = (Boolean) endorsement.get('IsDisqualified');
        }   

        sirenum__Ticket__c ticket = new sirenum__Ticket__c();
        ticket.sirenum__Status__c = 'Confirmed';
        ticket.sirenum__Comments__c = offenceCode.trim();
        ticket.Offence_Date__c = offenceDateTime;
        ticket.Conviction_Date__c = convictionDateTime;
        ticket.Sentence_Date__c = sentenceDateTime;
        ticket.Disqualified_end_date__c = disqualifiedDateTime;
        ticket.Points__c = points;
        ticket.disqualified__c = isDisqualified;
        ticket.sirenum__Owner__c = contact.Id;
        ticket.sirenum__Revoked__c = false;

        if (offenceDateTime != null || convictionDateTime != null || sentenceDateTime != null) {
            ticket.sirenum__Valid_from__c = (offenceDateTime != null) ? offenceDateTime.date() : 
                                              (convictionDateTime != null) ? convictionDateTime.date() : 
                                              (sentenceDateTime != null) ? sentenceDateTime.date() : null;
        }

        if (endDateTime != null) {
            ticket.sirenum__Valid_until__c = endDateTime.date();
        }

        return ticket;
    }

    // Helper method to assign ticket types
    private void assignTicketTypes(List<sirenum__Ticket__c> tickets, Set<String> offenceCodes) {
        if (offenceCodes.isEmpty()) return;

        Map<String, Id> offenceCodeToTicketTypeIdMap = new Map<String, Id>();
        List<sirenum__TicketType__c> ticketTypes = [
            SELECT Id, Offence_Code__c, Competency_Category__c, Name 
            FROM sirenum__TicketType__c 
            WHERE Offence_Code__c IN :offenceCodes
        ];
        
        for (sirenum__TicketType__c ticketType : ticketTypes) {
            offenceCodeToTicketTypeIdMap.put(ticketType.Offence_Code__c, ticketType.Id);
        }

        for (sirenum__Ticket__c ticket : tickets) {
            ticket.sirenum__TicketType__c = offenceCodeToTicketTypeIdMap.get(ticket.sirenum__Comments__c);
        }
    }

    public DriverWrapper SendDriverDetails(Contact contact,
                                           //List<sirenum__Ticket__c> driverTypeTickets,
                                           Picklist_Library__c picklist ) {
        Contact updatedContact;
        List<sirenum__Ticket__c> tickets = new List<sirenum__Ticket__c>();
        Davis_Error_Log__c errorLog;
    
        try {
            if (contact == null) {
                return new DriverWrapper(null, tickets,null);
            }

            /*
            if(driverTypeTickets==null || driverTypeTickets.isEmpty()){
                errorLog = createErrorLog(contact.id,'','No Driver tickets type found');
                return new DriverWrapper(null, tickets,errorLog);
            }
    
            List<String> driverTypes = new List<String>();
            for (sirenum__Ticket__c ticket : driverTypeTickets) {
                driverTypes.add(ticket.sirenum__TicketType__r.external_Id__c);
            }
            */
    
            // Prepare request body
            Map<String, Object> requestBody = new Map<String, Object>{
                'FirstName' => contact.FirstName,
                'Middlename' => contact.MiddleName,
                'Surname' => contact.LastName,
                'DepartmentId' => picklist.Davis_Deparment_Id__c,
                'DriverTypes' => new List<String>{this.integrationSettings.Driver_Types__c},
                'CompanyCode' => integrationSettings.Company_Code__c,
                'EmailAddress' => contact.Email,
                'Reference' => contact.Id,
                'DateOfBirth' => contact.Birthdate,
                'Gender' => contact.Sex_at_Birth__c,
                'DriverNumber' => contact.TR1__Drivers_License__c,
                'Address1' => contact.MailingStreet,
                'Address2' => contact.MailingCity,
                'PostalTown' => contact.MailingCity,
                'PostalCode' => contact.MailingPostalCode,
                'LocationId' => picklist.Branch__r.Davis_Location_Id__c,
                'EmailDriverOnCreation' => true
            };
    
            HttpRequest req = new HttpRequest();
            req.setEndpoint(integrationSettings.Endpoint__c + integrationSettings.Check_Drivers_endpoint__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-api-Key', integrationSettings.API_KEY__c);
            req.setHeader('Authorization', integrationSettings.Authorization__c);            
            req.setBody(JSON.serialize(requestBody));
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);
    
            System.debug('Request Sent: ' + JSON.serialize(requestBody));
    
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                //System.debug('Response: ' + responseMap);
    
                if (responseMap.containsKey('Status')) {
                    Map<String, Object> statusDetails = (Map<String, Object>) responseMap.get('Status');
                    if (statusDetails.containsKey('Success') && !((Boolean) statusDetails.get('Success'))) {                        
                        system.debug('Driver creation failed');
                        String errorMessage = (String) statusDetails.get('Details');
                        errorLog = createErrorLog(contact.id, res.getStatus(), errorMessage);
                        return new DriverWrapper(null, tickets,errorLog);
                    }
                }
                
                if (responseMap.containsKey('Driver')) {
                    system.debug('contains driver');
                    Map<String, Object> driverDetails = (Map<String, Object>) responseMap.get('Driver');
                    system.debug('driverdetails: '+driverDetails);
                    if (driverDetails.containsKey('DriverId')) {                     
                        contact.Davis_Id__c = (String) driverDetails.get('DriverId');
                        contact.Davis_Status__c = 'Consent Requested';
    
                        updatedContact = contact;
                    }
                }
            } else {

                String error;
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (responseMap.containsKey('Status')) {
                    Map<String, Object> errorDetails = (Map<String, Object>) responseMap.get('Driver');
                    error = (String) errorDetails.get('Details');
                }
                errorLog = createErrorLog(contact.id,res.getStatus(),error);
            }
    
        } catch (Exception e) {

            errorLog = createErrorLog(contact.id,'',e.getMessage());
           
        }
    
        return new DriverWrapper(updatedContact, tickets,errorLog);
    }
    
    private Datetime DateConverter(String jsonDate) {
        if (String.isBlank(jsonDate)) {
            return null;
        }
        
        String timestampStr = jsonDate.replace('/Date(', '').replace('-0000)/', '');
        Long timestampMillis = Long.valueOf(timestampStr);

        if (timestampMillis < 0) {
            return null;
        }

        return Datetime.newInstance(timestampMillis);
    }

    public class DriverWrapper {
        public Contact driverContact;
        public List<sirenum__Ticket__c> tickets;
        public Davis_Error_Log__c errorLog;
    
        public DriverWrapper(Contact driverContact, List<sirenum__Ticket__c> tickets,Davis_Error_Log__c errorLog) {
            this.driverContact = driverContact;
            this.tickets = tickets;
            this.errorLog = errorLog;
        }
    }

}