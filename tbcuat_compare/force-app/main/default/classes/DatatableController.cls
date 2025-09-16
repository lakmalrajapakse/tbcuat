/**
*   @description : Apex class to fetch the datatable 
**/
public with sharing class DatatableController {
    
    /**
    *   @description : Method to used to fetch the datatable attributes
    *   @param dataTableParams params for the datatable to fetch the data from open
    *   @return Map<String, Object> Map contains open data and field information for lightning datatable
    **/
    @AuraEnabled
    public static Map<String,Object> getDatatable(Map<String, Object> dataTableParams) {
        try{
            if(dataTableParams != null 
            && !dataTableParams.isEmpty()) {
                Type classType = Type.forName((String)dataTableParams.get('className'));
                if(classType == null || !iDataTable.class.isAssignableFrom(classType)) {
                    throw new DataTableException('Invalid Datatable');
                }
                iDataTable datatable = (iDataTable)Type.forName(
                    (String)dataTableParams.get('className')).newInstance();
                return datatable.getDatatableAttributes(dataTableParams);
            }
        }catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }   
        return new Map<String,Object>();
    }

    /**
    *   @description : Method to save the records
    *   @return Object created record.
    **/
    @AuraEnabled
    public static Object saveRecords(Map<String, Object> dataTableParams) {
        try{
            if(dataTableParams != null 
                && !dataTableParams.isEmpty()) {
                Type classType = Type.forName((String)dataTableParams.get('className'));
                if(classType == null || !iDataTable.class.isAssignableFrom(classType)) {
                    throw new DataTableException('Invalid Datatable');
                }
                iDataTable datatable = (iDataTable)Type.forName(
                    (String)dataTableParams.get('className')).newInstance();
                return datatable.saveRecords(dataTableParams);
            }
        }catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }   
        return null;
    }

    /**
    *   @description : Apex class for used for timesheet approval
    **/
    public class TimesheetApprovalController implements IDatatable {
        
        /**
        *   @description : Method to get the datatable attributes
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return Map<String, Object> Map contains open data and field information for lightning datatable
        **/
        public Map<String, Object> getDatatableAttributes(Map<String, Object> dataTableParams) {
            Map<String, Object> objectsMap = new Map<String, Object>();
            objectsMap.put('columns',getColumns());
            objectsMap.put('data',getData(dataTableParams));
            objectsMap.put('planCodes',DatatableHelper.getPlanCodes());
            return objectsMap;
        }

        /**
        *   @description : Method to get the datatable columns
        *   @return List<Map<String,Object>> List of columns to be displayed in the datatable
        **/
        public List<Map<String,Object>> getColumns() {
            List<Map<String,Object>> columnsList = new List<Map<String,Object>>();
            columnsList.add(new Map<String,Object> {
                'label' => 'Name',
                'fieldName' => 'timesheetUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'Name'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Worker',
                'fieldName' => 'workerUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'workerName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Placement',
                'fieldName' => 'placementUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'placementName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Week',
                'fieldName' => 'weekUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'weekName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Total Charge',
                'fieldName' => 'sirenum__Total_Charge__c', 
                'type' => 'currency'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Total Pay',
                'fieldName' => 'sirenum__Total_Pay__c', 
                'type' => 'currency'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Gross Margin',
                'fieldName' => 'sirenum__Profit__c', 
                'type' => 'currency'
            });
            return columnsList;
        }

         /**
        *   @description : Method to get the data from OPEN
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return List<Object> List of data from open
        **/
        public List<Object> getData(Map<String, Object> dataTableParams) {
            List<Object> objectsList = new List<Object>();
            List<String> filterStringList = new List<String>();
            if (dataTableParams.containsKey('filters')) {
                Set<String> planCodesList = new Set<String>();
                Map<String, Object> filtersMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(dataTableParams.get('filters')));
                if (filtersMap.containsKey('plancodes') && !String.isBlank(String.valueOf(filtersMap.get('plancodes')))) planCodesList.addAll(new List<String>(String.valueOf(filtersMap.get('plancodes')).replace('(','').replace(')','').deleteWhitespace().split(',')));
                if (filtersMap.containsKey('branches') && !String.isBlank(String.valueOf(filtersMap.get('branches'))))  planCodesList.addAll(DatatableHelper.getPlanCodesForBranches(new Set<String>(new List<String>(String.valueOf(filtersMap.get('branches')).replace('(','').replace(')','').deleteWhitespace().split(',')))));
                if (!planCodesList.isEmpty()) filterStringList.add('Plan_Code__c IN (\'' + String.join(new List<String>(planCodesList),'\',\'') + '\')');
                if (filtersMap.containsKey('accounts') && !String.isBlank(String.valueOf(filtersMap.get('accounts'))) && String.valueOf(filtersMap.get('accounts')) != '()') filterStringList.add('sirenum__Client__c IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('accounts')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
                if (filtersMap.containsKey('contacts') && !String.isBlank(String.valueOf(filtersMap.get('contacts'))) && String.valueOf(filtersMap.get('contacts')) != '()') filterStringList.add('sirenum__Worker__c IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('contacts')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
                if (filtersMap.containsKey('weeks') && !String.isBlank(String.valueOf(filtersMap.get('weeks'))) && String.valueOf(filtersMap.get('weeks')) != '()') filterStringList.add('sirenum__Week__c IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('weeks')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
            }
            String soqlQuery = 'SELECT Id, Name, sirenum__Worker__c, sirenum__Worker__r.Name, Placement__c, Placement__r.Name, '+
                'sirenum__Week__c, sirenum__Week__r.Name, sirenum__Total_Charge__c, sirenum__Total_Pay__c, sirenum__Profit__c FROM sirenum__Timesheet__c '+
                   'WHERE Status__c != \''+IntimeConstants.TIMESHEET_STATUS_APPROVED+'\' and Status__c != \''+IntimeConstants.TIMESHEET_STATUS_EXPORTED+'\' ' +(!filterStringList.isEmpty() ? 'AND '+String.join(filterStringList,' AND ') : '')+' ORDER BY Name LIMIT 50000';
            System.debug('Query is '+soqlQuery);
            List<sirenum__Timesheet__c> timesheetsList = (List<sirenum__Timesheet__c>)Database.query(soqlQuery);
            for (sirenum__Timesheet__c timesheet : timesheetsList) {
                Map<String, Object> objectsMap = new Map<String, Object>();
                objectsMap.putAll(timesheet.getPopulatedFieldsAsMap());
                objectsMap.put('workerUrl',timesheet.sirenum__Worker__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+timesheet.sirenum__Worker__c : '');
                objectsMap.put('workerName',timesheet.sirenum__Worker__r.Name);
                objectsMap.put('placementUrl',timesheet.Placement__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+timesheet.Placement__c : '');
                objectsMap.put('placementName',timesheet.Placement__r.Name);
                objectsMap.put('weekUrl',timesheet.sirenum__Week__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+timesheet.sirenum__Week__c : '');
                objectsMap.put('weekName',timesheet.sirenum__Week__r.Name);
                objectsMap.put('timesheetUrl',URL.getOrgDomainURL().toExternalForm()+'/'+timesheet.Id);
                objectsList.add(objectsMap);
            }
            return objectsList;
        }

        /** 
        * @description : Method to create a new note in open
        * @param openDataParams open data params
        **/ 
        public Object saveRecords(Map<String, Object> dataTableParams) {
            List<sirenum__Timesheet__c> timeSheetsToUpdate = new List<sirenum__Timesheet__c>();
            List<Id> timesheetIdsList = (List<Id>)JSON.deserialize(String.valueOf(dataTableParams.get('timesheetIds')),List<Id>.class);
            for (Id timesheetId : timesheetIdsList) {
                timeSheetsToUpdate.add(new sirenum__Timesheet__c(
                    Id = timesheetId,
                    Status__c = IntimeConstants.TIMESHEET_STATUS_APPROVED
                ));
            }
            if (!timeSheetsToUpdate.isEmpty()) update timeSheetsToUpdate;
            return true;
        }
    }

     /**
    *   @description : Apex class for used for timesheet approval
    **/
    public class HolidayApprovalController implements IDatatable {
        
        /**
        *   @description : Method to get the datatable attributes
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return Map<String, Object> Map contains open data and field information for lightning datatable
        **/
        public Map<String, Object> getDatatableAttributes(Map<String, Object> dataTableParams) {
            Map<String, Object> objectsMap = new Map<String, Object>();
            objectsMap.put('columns',getColumns());
            objectsMap.put('data',getData(dataTableParams));
            objectsMap.put('planCodes',DatatableHelper.getPlanCodes());
            return objectsMap;
        }

        /**
        *   @description : Method to get the datatable columns
        *   @return List<Map<String,Object>> List of columns to be displayed in the datatable
        **/
        public List<Map<String,Object>> getColumns() {
            List<Map<String,Object>> columnsList = new List<Map<String,Object>>();
            columnsList.add(new Map<String,Object> {
                'label' => 'Name',
                'fieldName' => 'employeeRequestUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'Name'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Worker',
                'fieldName' => 'workerUrl', 
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'workerName'
                    }
                },
                'target' => '_blank'
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Start Time',
                'fieldName' => 'sirenum__Start_Time__c', 
                'type' => 'date',
                'typeAttributes' => new Map<String, Object>{
                    'year' => 'numeric',
                    'month' =>  '2-digit',
                    'day' => '2-digit',
                    'hour' => '2-digit',
                    'minute' => '2-digit'
                }
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'End Time',
                'fieldName' => 'sirenum__End_Time__c', 
                'type' => 'date',
                'typeAttributes' => new Map<String, Object>{
                    'year' => 'numeric',
                    'month' =>  '2-digit',
                    'day' => '2-digit',
                    'hour' => '2-digit',
                    'minute' => '2-digit'
                }
            });
            columnsList.add(new Map<String,Object> {
                'label' => 'Description',
                'fieldName' => 'sirenum__Description__c', 
                'type' => 'text'
            });
            return columnsList;
        }

         /**
        *   @description : Method to get the data from OPEN
        *   @param dataTableParams params for the datatable to fetch the data from open
        *   @return List<Object> List of data from open
        **/
        public List<Object> getData(Map<String, Object> dataTableParams) {
            List<Object> objectsList = new List<Object>();
            List<String> filterStringList = new List<String>();
            if (dataTableParams.containsKey('filters')) {
                Set<String> planCodesList = new Set<String>();
                Map<String, Object> filtersMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(dataTableParams.get('filters')));
                if (filtersMap.containsKey('plancodes') && !String.isBlank(String.valueOf(filtersMap.get('plancodes')))) planCodesList.addAll(new List<String>(String.valueOf(filtersMap.get('plancodes')).replace('(','').replace(')','').deleteWhitespace().split(',')));
                if (filtersMap.containsKey('branches') && !String.isBlank(String.valueOf(filtersMap.get('branches'))))  planCodesList.addAll(DatatableHelper.getPlanCodesForBranches(new Set<String>(new List<String>(String.valueOf(filtersMap.get('branches')).replace('(','').replace(')','').deleteWhitespace().split(',')))));
                if (!planCodesList.isEmpty()) filterStringList.add('sirenum__Contact__r.Plan_Code__r.Name IN (\'' + String.join(new List<String>(planCodesList),'\',\'') + '\')');
                if (filtersMap.containsKey('startDate') && !String.isBlank(String.valueOf(filtersMap.get('startDate'))) && String.valueOf(filtersMap.get('startDate')) != '()') filterStringList.add('sirenum__Date__c >= '+String.valueOf(filtersMap.get('startDate')));
                if (filtersMap.containsKey('endDate') && !String.isBlank(String.valueOf(filtersMap.get('endDate'))) && String.valueOf(filtersMap.get('endDate')) != '()') filterStringList.add('sirenum__Date__c <= '+String.valueOf(filtersMap.get('endDate'))); 
                if (filtersMap.containsKey('contacts') && !String.isBlank(String.valueOf(filtersMap.get('contacts'))) && String.valueOf(filtersMap.get('contacts')) != '()') filterStringList.add('sirenum__Contact__c IN (\'' + String.join(new List<String>(String.valueOf(filtersMap.get('contacts')).replace('(','').replace(')','').deleteWhitespace().split(',')),'\',\'') + '\')');
            }
            String soqlQuery = 'SELECT Id, Name, sirenum__Description__c, sirenum__Start_Time__c, sirenum__End_Time__c, sirenum__Contact__c, sirenum__Contact__r.Name'+
                ' FROM sirenum__Employee_Request__c WHERE sirenum__Type__c = \'Holiday\' AND SendToIntime__c = false AND sirenum__Approved__c = true '+(!filterStringList.isEmpty() ? 'AND '+String.join(filterStringList,' AND ') : '')+' ORDER BY sirenum__Start_Time__c';
            System.debug('Soql is '+soqlQuery);
            List<sirenum__Employee_Request__c> employeeRequestsList = (List<sirenum__Employee_Request__c>)Database.query(soqlQuery);
            for (sirenum__Employee_Request__c employeeRequest : employeeRequestsList) {
                Map<String, Object> objectsMap = new Map<String, Object>();
                objectsMap.putAll(employeeRequest.getPopulatedFieldsAsMap());
                objectsMap.put('workerUrl',employeeRequest.sirenum__Contact__c != null ? URL.getOrgDomainURL().toExternalForm()+'/'+employeeRequest.sirenum__Contact__c : '');
                objectsMap.put('workerName',employeeRequest.sirenum__Contact__r.Name);
                objectsMap.put('employeeRequestUrl',URL.getOrgDomainURL().toExternalForm()+'/'+employeeRequest.Id);
                objectsList.add(objectsMap);
            }
            return objectsList;
        }

        /** 
        * @description : Method to create a new note in open
        * @param openDataParams open data params
        **/ 
        public Object saveRecords(Map<String, Object> dataTableParams) {
            List<sirenum__Employee_Request__c> employeeRequestsToUpdate = new List<sirenum__Employee_Request__c>();
            List<Id> employeeRequestIdsList = (List<Id>)JSON.deserialize(String.valueOf(dataTableParams.get('employeeRequestIds')),List<Id>.class);
            for (Id employeeRequestId : employeeRequestIdsList) {
                employeeRequestsToUpdate.add(new sirenum__Employee_Request__c(
                    Id = employeeRequestId,
                    SendToIntime__c = true
                ));
            }
            if (!employeeRequestsToUpdate.isEmpty()) update employeeRequestsToUpdate;
            return true;
        }
    }

    // Exception 
    public class DataTableException extends Exception {}
}