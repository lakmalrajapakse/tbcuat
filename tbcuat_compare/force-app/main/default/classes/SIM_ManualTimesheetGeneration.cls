public with sharing class SIM_ManualTimesheetGeneration {
    public final static String UPLOAD_SUCCESS_STATUS= 'Completed';
    public final static String UPLOAD_DATAERROR_STATUS= 'Completed With Errors';
    public final static String UPLOAD_DATAWARN_STATUS= 'Completed With Warnings';
    public final static String UPLOAD_FAIL_STATUS= 'Failed';
    public final static String UPLOAD_LOADING_STATUS= 'Processing';
   
    static final Manual_Timesheet_Generation_Settings__c SETTINGS = Manual_Timesheet_Generation_Settings__c.getInstance();
    static final Integer Batch_Size = (SETTINGS?.Batch_Size__c == null) ? 200 : Integer.valueOf(SETTINGS.Batch_Size__c);
    
    Template template;

    Manual_Timesheet_Generation__c mtg;    

    List<String> errors = new List<String>();
    List<String> warnings = new List<String>();
    Boolean isHeaderProcessed = false;
    Boolean hasLineErrors = false;    
    

    public SIM_ManualTimesheetGeneration(String fileName, String template, String periodId, Integer hrow, Integer drow) {
        this.mtg = new Manual_Timesheet_Generation__c (
            Filename__c = fileName,
            Template_Name__c = template,
            Header_Row__c = hrow,
            First_Data_Row__c = drow,
            Payroll_Period__c = periodId,
            Status__c = SIM_ShiftUploader.UPLOAD_LOADING_STATUS
        );
        insert mtg;

        getHeaderMappings(this.mtg.Template_Name__c);
    }

    public SIM_ManualTimesheetGeneration(Id manualTimesheetGenerationId) {
        this.mtg = [select Id, Template_Name__c, Filename__c, Header_Row__c, First_Data_Row__c, Status__c, Job_Id__c, Payroll_Period__c
                    from Manual_Timesheet_Generation__c
                    where id = :manualTimesheetGenerationId];

        getHeaderMappings(this.mtg.Template_Name__c);
    }

    public Manual_Timesheet_Generation__c getManualTimesheetGenerationRecord() {
        return this.mtg;
    }

    private sirenum__Week__c getPayrollPeriod() {
        if (this.mtg.Payroll_Period__c == null) {
            return null;
        }
        
        return [select id, sirenum__Start_Date__c, sirenum__Week_Ending__c from sirenum__Week__c where id = :this.mtg.Payroll_Period__c];
    }

    public SIM_Response.Response loadSheetRows(List<Object> sheetRows) {                
        if (this.errors.size() > 0) {
            return new SIM_Response.SuccessResponse('Fatal error encountered. Not processing any further');
        }

        if (sheetRows.size() == 0) {
           return new SIM_Response.SuccessResponse('No rows to load.');  
        }

        if (!isHeaderProcessed && !isValidHeaders(((Map<String, Object>) sheetRows[0]).keyset())) {
            updateLoadStatus(UPLOAD_FAIL_STATUS);
            System.debug(errors);
            return new SIM_Response.ErrorResponse(errors, 'Errors while validating header.');   
        }

        List<ShiftRow> srows = new List<ShiftRow>();

        Set<Id> shiftIds = new Set<Id>();

        for (Object row: sheetRows) {            
            ShiftRow sr = new ShiftRow(template, mtg, (Map<String,Object>) row);
            srows.add(sr);

            if (sr.ignore || !sr.errors.isEmpty()) {
                continue;
            }
            
            shiftIds.add(sr.shiftIdStr);
        }

        Map<String, sirenum__Timesheet__c> timesheets = getExistingTimesheets();
        Map<Id, sirenum__Shift__c> shifts = getShifts(shiftIds);
        sirenum__Week__c periodInfo = getPayrollPeriod();

        Boolean hasErrors = false;
        List<sirenum__Timesheet__c> timesheetsToInsert = new List<sirenum__Timesheet__c>();
        List<sirenum__Timesheet_Line__c> timesheetLinesToInsert = new List<sirenum__Timesheet_Line__c>();
        Map<id, sirenum__Shift__c> shiftsToUpdate = new Map<id, sirenum__Shift__c>();
        for (ShiftRow row : srows) {
            if (row.ignore) {
                continue;
            }            

            hasErrors = hasErrors || !row.errors.isEmpty();
            if (!row.errors.isEmpty() || !row.warnings.isEmpty()) {
                continue;
            }

            sirenum__Shift__c shift = shifts.get(row.shiftIdStr);
            if (shift == null) {
                row.warnings.add('Shift with id ' + row.shiftIdStr + ' not found or is not eligible for timesheet generation.');
                continue;
            }

            if (periodInfo.sirenum__Start_Date__c > shift.sirenum__Scheduled_Local_Start_Date__c ||  periodInfo.sirenum__Week_Ending__c < shift.sirenum__Scheduled_Local_Start_Date__c) {
                row.errors.add('Shift date is outside the period start and end date.');
                hasErrors = true;
                continue;
            }            

            Map<String, Object> splitKey = new Map<String, Object>();
            for (String field : this.template.timesheetMap.timesheet.splitByFields) {
                FieldMapDTO fieldMap = this.template.getFieldMapByTargetFieldName('timesheet', field);
                if (fieldMap.source == 'file') {
                    splitKey.put(field, row.fileFields.get(fieldMap.srcFieldName));
                } else {
                    splitKey.put(field, shift.get(fieldMap.srcFieldName));
                }
            }

            String splitKeyStr = JSON.serialize(splitKey);
            sirenum__Timesheet__c timesheet = timesheets.get(splitKeyStr);
            
            if (timesheet == null) {
                timesheet = new sirenum__Timesheet__c(                    
                    Manual_Timesheet_Generation__c = this.mtg.id,
                    sirenum__Week__c = periodInfo.id,
                    sirenum__Worked_Period__c = periodInfo.id,
                    sirenum__Week_Ending__c = periodInfo.sirenum__Week_Ending__c
                );

                for (FieldMapDTO fieldMap : this.template.timesheetMap.timesheet.fieldMap) {                    
                    if (fieldMap.source == 'file') {
                        timesheet.put(fieldMap.targetFieldName, row.fileFields.get(fieldMap.srcFieldName));
                    } else {
                        timesheet.put(fieldMap.targetFieldName, shift.get(fieldMap.srcFieldName));
                    }                                        
                }                     
                timesheets.put(splitKeyStr, timesheet);
                timesheetsToInsert.add(timesheet);
            } 

            row.timesheet = timesheet;

            sirenum__Timesheet_Line__c timesheetLine = new sirenum__Timesheet_Line__c(                 
                sirenum__Shift__c = shift.id
            );

            for (FieldMapDTO fieldMap : this.template.timesheetMap.timesheetLine.fieldMap) {
                if (fieldMap.source == 'file') {
                    timesheetLine.put(fieldMap.targetFieldName, row.fileFields.get(fieldMap.srcFieldName));
                } else {
                    timesheetLine.put(fieldMap.targetFieldName, shift.get(fieldMap.srcFieldName));
                }                                        
            }

            row.timesheetLine = timesheetLine;            
        }
    
        if (hasErrors) {
            handleErrors(srows);
        } else {
            if (!timesheetsToInsert.isEmpty()) {
                insert timesheetsToInsert;             
            }

            if (!timesheetLinesToInsert.isEmpty()) {
                insert timesheetLinesToInsert;
            }

            for (ShiftRow row : srows) {                
                if (row.ignore || !row.warnings.isEmpty()) {
                    continue;
                }

                timesheetLinesToInsert.add(row.timesheetLine);
                row.timesheetLine.sirenum__Timesheet__c = row.timesheet.id;

                shiftsToUpdate.put (row.shiftIdStr, new sirenum__Shift__c(
                    id = row.shiftIdStr,
                    sirenum__Timesheet_summaries__c = row.timesheet.id
                ));
            }

            if (!shiftsToUpdate.isEmpty()) {
                insert timesheetLinesToInsert;
                update shiftsToUpdate.values();
            }  
        }
            

        return new SIM_Response.SuccessResponse('Success');
    }    

    private Map<id, sirenum__Shift__c> getShifts(Set<Id> shiftIds) { 
        Id mtgId = this.mtg.id;       
        String soqlStr = 'select ' + String.join(this.template.shiftFields, ',') + ' from sirenum__Shift__c where id in :shiftIds '
                                   + 'and sirenum__Contract__r.Manual_Timesheet_Generation__c = true '
                                   + 'and Approved__c = true '
                                   + 'AND sirenum__Contact__c != null '
                                   + 'AND (sirenum__Timesheet_summaries__c = null or sirenum__Timesheet_summaries__r.Manual_Timesheet_Generation__c = :mtgId)';
        
        return new Map<id, sirenum__Shift__c>((List<sirenum__Shift__c>)Database.query(soqlStr));    
    }

    private Map<String, sirenum__Timesheet__c> getExistingTimesheets() {           
        Id mtgId = this.mtg.id;
        String soqlStr = 'select id, ' + String.join(this.template.timesheetMap.timesheet.splitByFields, ',') + ' from sirenum__Timesheet__c where id = :mtgId ';                                   

        List<sirenum__Timesheet__c> timesheets = Database.query(soqlStr);
        Map<String, sirenum__Timesheet__c> timesheetMap = new Map<String, sirenum__Timesheet__c>();
        for (sirenum__Timesheet__c ts : timesheets) {            
            Map<String, Object> splitValues = new Map<String, Object>();
            for (String field : this.template.timesheetMap.timesheet.splitByFields) {
                splitValues.put(field, ts.get(field));
            }
            timesheetMap.put(JSON.serialize(splitValues), ts);
        }
        
        return timesheetMap;
    }

    public String submitBatch(String jsonString) {
        SIM_ManualTimesheetGenerationBatch batchJob = new SIM_ManualTimesheetGenerationBatch(this, jsonString);
        String batchProcessId = Database.executeBatch(batchJob, Batch_Size);
        
        this.mtg.Job_Id__c = batchProcessId;
        update this.mtg;

        return this.mtg.id;
    }

    public void finalizeLoadBatch(Id jobId) {
        AsyncApexJob aSyncProgress = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, ExtendedStatus
                                      FROM AsyncApexJob 
                                      WHERE ID =:jobId
                                      LIMIT 1];

        if (aSyncProgress.NumberOfErrors > 0) {
            this.errors.add(aSyncProgress.ExtendedStatus);
            updateLoadStatus(UPLOAD_FAIL_STATUS);
        } else {
            updateLoadStatus((this.hasLineErrors)? UPLOAD_DATAERROR_STATUS : ((this.errors.size() > 0) ? UPLOAD_FAIL_STATUS : UPLOAD_SUCCESS_STATUS));
        }
    }

    private void handleErrors(List<ShiftRow> srows) {
        List<Manual_Timesheet_Generation_Error__c> errors = new List<Manual_Timesheet_Generation_Error__c>();

        for (ShiftRow row: srows) {            
            if (row.errors.isEmpty()) {
                continue;
            }

            for (String error : row.errors) {
                errors.add(
                    new Manual_Timesheet_Generation_Error__c(
                        error_message__c = error,
                        Row_Number__c = row.rowNumber,
                        Shift_ID__c = row.shiftIdStr,
                        Manual_Timesheet_Generation__c = this.mtg.id
                    )
                );
            }

            this.hasLineErrors = true;
        }

        if (!errors.isEmpty()) {
            insert errors;
        }
    }

    private boolean isValidHeaders(Set<String> headers) {     
        if (this.template.templateRecord.Shift_Id__c != null && !headers.contains(this.template.templateRecord.Shift_Id__c)) {
            this.errors.add('Shift Id heading not found. Heading name expected = ' + this.template.templateRecord.Shift_Id__c);
        }

        if (this.template.templateRecord.Rate_Type__c != null && !headers.contains(this.template.templateRecord.Rate_Type__c)) {
            this.errors.add('Rate Type heading not found. Heading name expected = ' + this.template.templateRecord.Rate_Type__c);
        }

        if (this.template.templateRecord.inTime_Pay_Element__c != null && !headers.contains(this.template.templateRecord.inTime_Pay_Element__c)) {
            this.errors.add('inTime Pay Element heading not found. Heading name expected = ' + this.template.templateRecord.inTime_Pay_Element__c);
        }

        if (this.template.templateRecord.Pay_Rate__c != null && !headers.contains(this.template.templateRecord.Pay_Rate__c)) {
            this.errors.add('Pay Rate heading not found. Heading name expected = ' + this.template.templateRecord.Pay_Rate__c);
        }

        if (this.template.templateRecord.Charge_Rate__c != null && !headers.contains(this.template.templateRecord.Charge_Rate__c)) {
            this.errors.add('Charge_Rate__c heading not found. Heading name expected = ' + this.template.templateRecord.Charge_Rate__c);
        }        

        if (this.template.templateRecord.Hours__c != null && !headers.contains(this.template.templateRecord.Hours__c)) {
            this.errors.add('Hours heading not found. Heading name expected = ' + this.template.templateRecord.Hours__c);
        }        

        return (this.errors.size() == 0);
    }    

    public void setFailStatus(String error) {
        this.errors.add(error);
        updateLoadStatus(UPLOAD_FAIL_STATUS);        
    }

    public void updateLoadStatus(String status) {
        this.mtg.Status__c = status;
        this.mtg.Error_Message__c  = String.join(errors, '. ');
        System.debug(errors);
        System.debug(status);
        update mtg;
    }

    private void getHeaderMappings(String templateName) {
        List<Manual_Timesheet_Generation_Templates__mdt> mapping = [select Charge_Rate__c, Hours__c, inTime_Pay_Element__c, Pay_Rate__c, Rate_Type__c, Shift_Id__c, Timesheet_Map__c
                                                    from Manual_Timesheet_Generation_Templates__mdt where DeveloperName = :templateName];
        System.debug(mapping);
        if (mapping.size() == 0) {
            throw new StringException('Error: Manual Timesheet Generation Template, ' + templateName + ' not found.');  
        }
   
        this.template = new Template(mapping[0]);
        processTimesheetMappings();

    }

    @testVisible
    private void setHeaderMappings(Manual_Timesheet_Generation_Templates__mdt template) {
        this.template = new Template(template);        
        processTimesheetMappings();
    } 

    private void processTimesheetMappings() {
        this.template.timesheetMap = (TimesheetMapDTO) JSON.deserialize(this.template.templateRecord.Timesheet_Map__c, TimesheetMapDTO.class);
        this.template.processFields();        
    }

    class Template {
        public Manual_Timesheet_Generation_Templates__mdt templateRecord;
        public TimesheetMapDTO timesheetMap;         
        public Set<String> shiftFields = new Set<String> {'id', 'sirenum__Scheduled_Local_Start_Date__c'};                
        Map<String, FieldMapDTO> srcfields = new Map<String, FieldMapDTO>();
        Map<String, FieldMapDTO> tgtfields = new Map<String, FieldMapDTO>();
        
        public Template(Manual_Timesheet_Generation_Templates__mdt templateRecord) {
            this.templateRecord = templateRecord;
        }

        public FieldMapDTO getFieldMapBySourceFieldName(String obj, String source, String fieldName) {
            return srcfields.get(JSON.serialize(new Map<String, String> {'object' => obj, 'source' => source, 'srcFieldName' => fieldName}));
        }

        public FieldMapDTO getFieldMapByTargetFieldName(String obj, String fieldName) {
            return tgtfields.get(JSON.serialize(new Map<String, String> {'object' => obj, 'tgtFieldName' => fieldName}));
        }

        public void processFields() {
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> tsFieldsMap = schemaMap.get('sirenum__Timesheet__c').getDescribe().fields.getMap();
            Map<String, Schema.SObjectField> tslFieldsMap = schemaMap.get('sirenum__Timesheet_Line__c').getDescribe().fields.getMap();

            for (FieldMapDTO fieldMap : this.timesheetMap.timesheet.fieldMap) {
                if (fieldMap.type == 'PICKLIST') {
                    Schema.DescribeFieldResult fieldDescribe = tsFieldsMap.get(fieldMap.targetFieldName).getDescribe();
                    if (fieldDescribe.getType() == Schema.DisplayType.Picklist) {
                        fieldMap.validValues = new List<String>();
                        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                            fieldMap.validValues.add(entry.getValue());
                        }
                    }
                }
                if (fieldMap.source == 'shift') {
                    this.shiftFields.add(fieldMap.srcFieldName);                    
                }
                
                this.srcfields.put(JSON.serialize(new Map<String, String> {'object' => 'timesheet', 'source' => fieldMap.source, 'srcFieldName' => fieldMap.srcFieldName}), fieldMap);
                this.tgtfields.put(JSON.serialize(new Map<String, String> {'object' => 'timesheet', 'tgtFieldName' => fieldMap.targetFieldName}), fieldMap);
            }

            for (FieldMapDTO fieldMap : this.timesheetMap.timesheetLine.fieldMap) {
                if (fieldMap.type == 'PICKLIST') {
                    Schema.DescribeFieldResult fieldDescribe = tslFieldsMap.get(fieldMap.targetFieldName).getDescribe();
                    if (fieldDescribe.getType() == Schema.DisplayType.Picklist) {
                        fieldMap.validValues = new List<String>();
                        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                            fieldMap.validValues.add(entry.getValue());
                        }
                    }
                }
                if (fieldMap.source == 'shift') {
                    this.shiftFields.add(fieldMap.srcFieldName);
                }

                this.srcfields.put(JSON.serialize(new Map<String, String> {'object' => 'timesheetLine', 'source' => fieldMap.source, 'srcFieldName' => fieldMap.srcFieldName}), fieldMap);
                this.tgtfields.put(JSON.serialize(new Map<String, String> {'object' => 'timesheetLine', 'tgtFieldName' => fieldMap.targetFieldName}), fieldMap);
            }            
        }
    }

    class TimesheetMapDTO {
        public TimesheetDTO timesheet;
        public TimesheetLineDTO timesheetLine;
    }
    class TimesheetLineDTO {        
        public List<FieldMapDTO> fieldMap = new List<FieldMapDTO>();
    }

    class TimesheetDTO {
        public List<String> splitByFields;    
        public List<fieldMapDTO> fieldMap = new List<FieldMapDTO>();
    }

    class FieldMapDTO {
        public String source;
        public String srcFieldName;        
        public String targetFieldName;
        public String type;
        public List<ValueMapDTO> valueMap;
        public List<String> validValues;
    }

    class ValueMapDTO {
        public String srcValue;
        public String tgtValue;                
    }

    class ShiftRow {        
        integer rowNumber;
        
        sirenum__Timesheet__c timesheet;
        sirenum__Timesheet_Line__c timesheetLine;
        
        boolean ignore = false;

        String shiftIdStr;
        Map<String, Object> fileFields = new Map<String, Object>();

        List<String> errors = new List<String>();        
        List<String> warnings = new List<String>();        

        ShiftRow(Template template, Manual_Timesheet_Generation__c mtg, Map<String,Object> row) {           
            this.rowNumber = Integer.valueOf(row.get('__ROW_NUMBER__'));
            if (this.rowNumber == null || this.rowNumber < Integer.valueOf(mtg.First_Data_Row__c)) {
                this.ignore = true;
                return; 
            }

            FieldMapDTO fieldDef = template.getFieldMapBySourceFieldName('timesheetLine', 'file', 'Hours__c');
            Decimal billableHours = (Decimal) processFileFields((String) row.get(template.templateRecord.Hours__c), fieldDef, template.templateRecord.Hours__c);
            
            if (!this.errors.isEmpty()) {
                return;
            }

            if (billableHours == null || billableHours == 0) {
                this.ignore = true;
                return;
            }            
        
            shiftIdStr = (String) row.get(template.templateRecord.Shift_Id__c);
            if ( String.isBlank(this.shiftIdStr)) {
                this.errors.add('Shift Id cannot be blank.');
            }

            try {
                this.shiftIdStr = Id.valueOf(this.shiftIdStr);
            } catch(Exception e) {
                this.errors.add('The specified Shift Id is not a valid (Shift Id = ' + this.shiftIdStr + ').');
            }                        
            

            fieldDef = template.getFieldMapBySourceFieldName('timesheetLine', 'file', 'Pay_Rate__c');
            Decimal payRate = (Decimal) processFileFields((String) row.get(template.templateRecord.Pay_Rate__c), fieldDef, template.templateRecord.Pay_Rate__c);

            if (payRate == null) {                
                fileFields.put('Pay_Rate__c', 0);    
            }


            fieldDef = template.getFieldMapBySourceFieldName('timesheetLine', 'file', 'Charge_Rate__c');
            Decimal chargeRate = (Decimal) processFileFields((String) row.get(template.templateRecord.Charge_Rate__c), fieldDef, template.templateRecord.Charge_Rate__c);

            if (payRate == null) {                
                fileFields.put(template.templateRecord.Charge_Rate__c, 0);    
            }
            
            
            fieldDef = template.getFieldMapBySourceFieldName('timesheetLine', 'file', 'Rate_Type__c');
            if (fieldDef != null && template.templateRecord.Rate_Type__c != null) {
                processFileFields((String) row.get(template.templateRecord.Rate_Type__c), fieldDef, template.templateRecord.Rate_Type__c);                
            }
            
            
            fieldDef = template.getFieldMapBySourceFieldName('timesheetLine', 'file', 'inTime_Pay_Element__c');
            if (fieldDef != null && template.templateRecord.inTime_Pay_Element__c != null) {
                processFileFields((String) row.get(template.templateRecord.inTime_Pay_Element__c), fieldDef, template.templateRecord.inTime_Pay_Element__c);                
            }            
        }
         
 
        Object processFileFields(String value, FieldMapDTO fieldMap, String fileColumnName) {
            if (fieldMap.type == 'PICKLIST') {
                if (fieldMap.validValues != null && !fieldMap.validValues.isEmpty() && !fieldMap.validValues.contains(value)) {
                    this.errors.add('The specified value for ' + fileColumnName + ' is not a valid picklist value (Value = ' + value + ').');
                    return null;
                }

                this.fileFields.put(fieldMap.srcFieldName, value);                    
                return value;
            }

            if (fieldMap.type == 'DECIMAL') {
                Decimal decValue = null;

                if (!String.isBlank(value)) {
                    try { 
                        decValue = Decimal.valueOf(value);
                        this.fileFields.put(fieldMap.srcFieldName, decValue);                    
                    } catch (Exception e) {
                        this.errors.add('The specified ' + fileColumnName + ' is not a valid value (Value = ' + value + ').');
                    }
                }

                return decValue;
            }
            
            if (fieldMap.type == 'MAP') {    
                String mapValue = null;           
                if (!String.isBlank(value)) {                    
                    if (fieldMap.valueMap != null && !fieldMap.valueMap.isEmpty()) {
                        boolean found = false;
                        for (ValueMapDTO vm : fieldMap.valueMap) {
                            if (vm.srcValue == value) {
                                mapValue = vm.tgtValue;
                                this.fileFields.put(fieldMap.srcFieldName, mapValue);
                                found = true;
                                break;
                            }
                        }
                        
                        if (!found) {
                            this.errors.add('The specified ' + fileColumnName + ' is not a valid value (Value = ' + value + ').');
                        } 
                    }                    
                }

                return mapValue;
            }

            this.fileFields.put(fieldMap.srcFieldName, value);
            return value;
        }        
    }    
}