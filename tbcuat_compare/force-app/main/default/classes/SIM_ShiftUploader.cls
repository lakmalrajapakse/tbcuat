public with sharing class SIM_ShiftUploader {
    public final static String UPLOAD_SUCCESS_STATUS= 'Completed';
    public final static String UPLOAD_DATAERROR_STATUS= 'Completed With Errors';
    public final static String UPLOAD_FAIL_STATUS= 'Failed';
    public final static String UPLOAD_LOADING_STATUS= 'Processing';
   
    static final Bulk_Shift_Uploader_Settings__c SETTINGS = Bulk_Shift_Uploader_Settings__c.getInstance();
    static final Integer Batch_Size = (SETTINGS?.Upload_Batch_Size__c == null) ? 200 : Integer.valueOf(SETTINGS.Upload_Batch_Size__c);
    
    Shift_Upload_Template__mdt template;

    Bulk_Shift_Upload__c bsu;    

    List<String> errors = new List<String>();
    Boolean isHeaderProcessed = false;
    Boolean hasLineErrors = false;

    List<sirenum__Shift__c> shiftsToUpdate;
    List<ShiftRow> shiftRowsToUpdate;
    
    List<ShiftRow> srows;

    public SIM_ShiftUploader(String fileName, String template, Integer hrow, Integer drow) {
        this.bsu = new Bulk_Shift_Upload__c (
            Filename__c = fileName,
            Template_Name__c = template,
            Header_Row__c = hrow,
            First_Data_Row__c = drow,
            Status__c = SIM_ShiftUploader.UPLOAD_LOADING_STATUS
        );
        insert bsu;

        getHeaderMappings(this.bsu.Template_Name__c);
    }

    public SIM_ShiftUploader(Id bulkShiftUploadId) {
        this.bsu = [select Id, Template_Name__c, Filename__c, Header_Row__c, First_Data_Row__c, Status__c, Job_Id__c
                    from Bulk_Shift_Upload__c
                    where id = :bulkShiftUploadId];

        getHeaderMappings(this.bsu.Template_Name__c);
    }

    public Bulk_Shift_Upload__c getBulkShiftUploadRecord() {
        return this.bsu;
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

        initializeVariables();
        Set<String> jobRoleNames = new Set<String>();
        Set<String> siteNames = new Set<String>();
        Set<String> payrollIds = new Set<String>();
        Set<Date> shiftDates = new Set<Date>();

        Set<Id> jobRoleIds = new Set<Id>();
        Set<Id> siteIds = new Set<Id>();
        Set<Id> candidateIds = new Set<Id>();
        Set<Id> shiftIds = new Set<Id>();

        for (Object row: sheetRows) {            
            ShiftRow sr = new ShiftRow(template, bsu, (Map<String,Object>) row);
            this.srows.add(sr);

            if (sr.ignore || !sr.errors.isEmpty()) {
                continue;
            }
            
            if (this.template.RecordID__c != null) {
                shiftIds.add(sr.shifts[0].id);
            } else {
                if (this.template.Job_Role_Id__c != null) {
                    jobRoleIds.add(sr.jobRoleId);
                } else {
                    jobRoleNames.add(sr.jobRoleName);
                }

                if (this.template.Site_Id__c != null) {
                    siteIds.add(sr.siteId);
                } else {  
                    if (this.template.Site__c != null) { 
                        siteNames.add(sr.siteName);
                    }  
                    
                }

                payrollIds.add(sr.payrollId);
                shiftDates.add(sr.shiftDate);                
            }            
        }

        SIM_SObjResults jobRoles;
        SIM_SObjResults sites;
        SIM_SObjResults candidates;

        if (!jobRoleNames.isEmpty()) {
            jobRoles = getJobRolesByName(jobRoleNames);
        }
        
        if (!siteNames.isEmpty()) {
            sites = getSitesByName(siteNames);
        }                

        if (!payrollIds.isEmpty()) {
            candidates = getCandidatesByPayrollID(payrollIds);
        }

        SIM_SObjResults shifts;
        if (this.template.RecordID__c == null)  {
            for (ShiftRow row : this.srows) {
                if (row.ignore || !row.errors.isEmpty()) {
                    continue;
                }
                
                if (this.template.Job_Role_Id__c == null && this.template.Job_Role__c != null) {
                    List<SObject> mJobRoles = jobRoles.getResultRow((jobRoles.getKey(new List<Object> {row.jobRoleName})));
                    if (mJobRoles == null || mJobRoles.size() == 0) {
                        row.errors.add('Job Role (' + row.jobRoleName + ') not found.');
                    } else if (mJobRoles.size() > 1) {
                        row.errors.add('More than one job roles found with the same name (' + row.jobRoleName + ')');
                    } else {
                        row.jobRoleId = ((sirenum__Team__c) (mJobRoles[0])).Id;
                        jobRoleIds.add(row.jobRoleId);           
                    }
                }
                
                if (this.template.Site_Id__c == null && this.template.Site__c != null) {
                    List<SObject> mSites = sites.getResultRow((sites.getKey(new List<Object> {row.siteName})));
                    if (mSites == null || mSites.size() == 0) {
                        row.errors.add('Site (' + row.siteName + ') not found.');
                    } else if (mSites.size() > 1) {
                        row.errors.add('More than one sites found with the same name (' + row.siteName + ')');
                    } else {
                        row.siteId = ((sirenum__Site__c) (mSites[0])).Id;                
                        siteIds.add(row.siteId);
                    }
                }


                if (this.template.Payroll_ID__c != null) {
                    List<SObject> mCandidates = candidates.getResultRow((candidates.getKey(new List<Object> {row.payrollId})));
                    if (mCandidates == null || mCandidates.size() == 0) {
                        row.errors.add('Payroll Id (' + row.payrollId + ') not found.');
                    } else if (mCandidates.size() > 1) {
                        row.errors.add('More than one candidate associated with the same payroll Id (' + row.payrollId + ')');
                    } else {
                        row.candidateId = ((Contact) (mCandidates[0])).Id;
                        candidateIds.add(row.candidateId);
                    }
                }
            }

            if (!jobRoleIds.isEmpty() && !candidateIds.isEmpty()) {
                shifts = getShifts(jobRoleIds, siteIds, candidateIds, shiftDates);
                System.debug(shifts);
            }

            for (ShiftRow row : this.srows) {
                if (row.ignore || !row.errors.isEmpty()) {
                    continue;
                }

                if (shifts == null) {
                    row.errors.add('No published shift can be found for Payroll Id, Job Role, Site and Shift Date');
                    continue;
                }

                List<Object> key = new List<Object>{row.jobRoleId, row.candidateId, row.shiftDate};
                if (this.template.Site_Id__c != null || this.template.Site__c != null) {
                    key.add(row.siteId);
                }

                List<SObject> mShifts = shifts.getResultRow(shifts.getKey(key));
                if (mShifts != null) {
                    for (SObject shift : mShifts) {
                        row.shifts.add((sirenum__Shift__c) shift);
                    }                    
                } else {
                    row.errors.add('No published shift can be found for Payroll Id, Job Role, Site and Shift Date');
                }
                
            }
        } else if (!shiftIds.isEmpty()) {
            Map<id, sirenum__Shift__c> shiftMap = this.getShiftsById(shiftIds);
            for (ShiftRow row : this.srows) {
                if (row.ignore || !row.errors.isEmpty()) {
                    continue;
                }

                sirenum__Shift__c shift = shiftMap.get(row.shifts[0].id);
                if (shift == null) {
                    row.errors.add('No published shift can be found for the specified id.');
                } else {
                    row.shifts[0] = shift;
                }
            }
        }    
    

        processShifts();        
        handleErrors();

        return new SIM_Response.SuccessResponse('Success');
    }    

    private Map<id, sirenum__Shift__c> getShiftsById(Set<Id> shiftIds) {        
        return new Map<id, sirenum__Shift__c> ([select id, sirenum__Scheduled_Start_Time__c,  
                                                       sirenum__Allow_charge__c, sirenum__Allow_pay__c, sirenum__Billable_Start_Time__c, sirenum__Billable_End_Time__c, sirenum__Scheduled_Local_Start_Date__c, sirenum__Scheduled_End_Time__c,
                                                       PO_Number__c, sirenum__Actual_Start_Time__c, sirenum__Actual_End_Time__c, sirenum__Billable_Shift_Length_Decimal__c, sirenum__Contract__r.Manual_Timesheet_Generation__c
                                                from sirenum__Shift__c
                                                where id in :shiftIds
                                                AND sirenum__Cancelled__c = false
                                                AND sirenum__Published__c = true
                                                AND sirenum__Contact__c != null
                                                AND sirenum__Timesheet_summaries__c = null]);        
    }

    private SIM_SObjResults getShifts(Set<Id> jobRoleIds, Set<Id> siteIds, Set<Id> candidateIds, Set<Date> shiftDates) {

        String strSOQL = 'select id, sirenum__Scheduled_Start_Time__c,  sirenum__Site__c, sirenum__Team__c, sirenum__Scheduled_Local_Start_Date__c, sirenum__Contact__c, sirenum__Contract__r.Manual_Timesheet_Generation__c,';
        strSOQL += ' sirenum__Allow_charge__c, sirenum__Allow_pay__c, sirenum__Billable_Start_Time__c, sirenum__Billable_End_Time__c, sirenum__Scheduled_End_Time__c, PO_Number__c, sirenum__Actual_Start_Time__c, sirenum__Actual_End_Time__c, sirenum__Billable_Shift_Length_Decimal__c';
        strSOQL += ' from sirenum__Shift__c';
        strSOQL += ' where sirenum__Team__c in :jobRoleIds';        
        strSOQL += ' AND sirenum__Cancelled__c = false';
        strSOQL += ' AND sirenum__Published__c = true';
        strSOQL += ' AND sirenum__Contact__c in :candidateIds';
        strSOQL += ' AND sirenum__Timesheet_summaries__c = null';
        strSOQL += ' AND sirenum__Scheduled_Local_Start_Date__c in :shiftDates';

        List<String> key = new List<String>{'sirenum__Team__c', 'sirenum__Contact__c', 'sirenum__Scheduled_Local_Start_Date__c'};

        if (siteIds != null && !siteIds.isEmpty()) {
            strSOQL += ' and sirenum__Site__c in :siteIds';
            key.add('sirenum__Site__c');
        }

        strSOQL += ' order by sirenum__Scheduled_Start_Time__c';
        
        system.debug(jobRoleIds);
        system.debug(siteIds);
        system.debug(candidateIds);
        system.debug(shiftDates);
        system.debug(strSOQL);


        return new SIM_SObjResults(key, Database.query(strSOQL));        
    }

    private SIM_SObjResults getSitesByName(Set<String> siteNames) {
        List<sirenum__Site__c> sites = [
                                     Select id, name from sirenum__Site__c
                                     where name in :siteNames                                     
                                   ];

        return new SIM_SObjResults(new List<String>{'name'}, sites);        
    }

    private SIM_SObjResults getJobRolesByName(Set<String> jobRoleNames) {
        List<sirenum__Team__c> jobRoles = [
                                     Select id, name from sirenum__Team__c
                                     where name in :jobRoleNames
                                   ];

        return new SIM_SObjResults(new List<String>{'name'}, jobRoles);        
    }

    private SIM_SObjResults getCandidatesByPayrollID(Set<String> payrollIds) {
        List<Contact> contacts = [
                                     Select id, InTimeExternalId__c
                                     from Contact
                                     where InTimeExternalId__c in :payrollIds
                                   ];

        return new SIM_SObjResults(new List<String>{'InTimeExternalId__c'}, contacts);
    }

    private void processShifts(){    
        Set<Id> shiftIds = new Set<Id>();

        for (ShiftRow row: this.srows) {            
            if (row.ignore || !row.errors.isEmpty()) {
                continue;
            }
            
            if ((row.billableDate != null || row.billableStartTime != null) && row.shifts.size() > 1) {
                row.errors.add('Billable date or time cannot be specified for rows that match to multiple shifts.');
                continue;                
            }
            

            if (row.billableDate != null || row.billableStartTime != null) {
                sirenum__Shift__c shift = row.shifts[0];

                shift.sirenum__Billable_Start_Time__c = Datetime.newInstance(((row.billableDate != null)? row.billableDate: shift.sirenum__Scheduled_Local_Start_Date__c), row.billableStartTime);
    
                if (row.billableEndTime != null) {
                    if (row.billableEndTime > row.billableStartTime) {
                        shift.sirenum__Billable_End_Time__c = Datetime.newInstance(row.billableDate, row.billableEndTime);
                    } else {
                        shift.sirenum__Billable_End_Time__c = Datetime.newInstance(row.billableDate.addDays(1), row.billableEndTime);
                    }
                } else {
                    Integer minutes=Math.round(row.billableHours*60);                    
                    shift.sirenum__Billable_End_Time__c = Datetime.newInstance(row.billableDate, row.billableStartTime).addMinutes(minutes);
                }
            } 

            if (row.actualStartTime != null) {
                sirenum__Shift__c shift = row.shifts[0];

                row.actualDate = (row.actualDate != null) ? row.actualDate : shift.sirenum__Scheduled_Local_Start_Date__c;
                shift.sirenum__Actual_Start_Time__c = Datetime.newInstance(row.actualDate, row.actualStartTime);
    
                if (row.actualEndTime != null) {
                    if (row.actualEndTime > row.actualStartTime) {
                        shift.sirenum__Actual_End_Time__c = Datetime.newInstance(row.actualDate, row.actualEndTime);
                    } else {
                        shift.sirenum__Actual_End_Time__c = Datetime.newInstance(row.actualDate.addDays(1), row.actualEndTime);
                    }
                } 
            } 

            DateTime prevEndTime;
            Integer minutes=(row.billableHours != null) ? Math.round(row.billableHours*60) : null;

            for (integer i=0; i < row.shifts.size(); i++) {
                sirenum__Shift__c shift = row.shifts[i];
                shiftIds.add(shift.id);
                
                if (row.poNumber != null) {
                    shift.PO_Number__c = row.poNumber;
                }
                                
                if (!String.isBlank(row.approvedShiftStr) && row.approvedShift) {
                    if (shift.sirenum__Contract__r.Manual_Timesheet_Generation__c){
                        shift.Approved__c = true;
                    } else {
                        shift.sirenum__Allow_charge__c = true;
                        shift.sirenum__Allow_pay__c = true;
                    }
                } else if (!String.isBlank(row.approvedShiftStr)) {
                    if (shift.sirenum__Contract__r.Manual_Timesheet_Generation__c){
                        shift.Approved__c = false;
                    } else {
                        shift.sirenum__Allow_charge__c = false;
                        shift.sirenum__Allow_pay__c = false;
                    }
                }

                if (row.billableDate == null && row.billableStartTime == null && row.billableHours != null && !(row.shifts.size() == 1 && row.billableHours == shift.sirenum__Billable_Shift_Length_Decimal__c)) {
                    shift.sirenum__Billable_Start_Time__c = (prevEndTime >= shift.sirenum__Scheduled_Start_Time__c) ? prevEndTime : shift.sirenum__Scheduled_Start_Time__c;
                    Integer scheduledMinutes = Math.round((shift.sirenum__Scheduled_End_Time__c.getTime()  - shift.sirenum__Scheduled_Start_Time__c.getTime())/60000);
                    Integer actualMinutes = (scheduledMinutes > minutes ||  row.shifts.size() == i+1) ? minutes : scheduledMinutes;
                    

                    shift.sirenum__Billable_End_Time__c = shift.sirenum__Billable_Start_Time__c.addMinutes(actualMinutes);
                    minutes = minutes - actualMinutes;
                    prevEndTime = shift.sirenum__Billable_End_Time__c;
                }

                this.shiftsToUpdate.add(shift);
                this.shiftRowsToUpdate.add(row);    
            }        
        }

        persistChangesToDB();
    }

    private void persistChangesToDB() {       
        if (!this.shiftsToUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.Update(this.shiftsToUpdate, false);

            for(integer i = 0; i < results.size(); i++){
                if(!results[i].isSuccess()){
                    for(Database.Error error : results[i].getErrors()){
                        shiftRowsToUpdate[i].errors.add(error.getMessage());
                    }                    
                } 
            }           
        }
    }    

    public String submitBatch(String jsonString) {
        SIM_ShiftUploadBatch batchJob = new SIM_ShiftUploadBatch(this, jsonString);
        String batchProcessId = Database.executeBatch(batchJob, Batch_Size);
        
        this.bsu.Job_Id__c = batchProcessId;
        update this.bsu;

        return this.bsu.id;
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

    private void handleErrors() {
        List<Bulk_Shift_Upload_Error__c> errors = new List<Bulk_Shift_Upload_Error__c>();

        for (ShiftRow row: this.srows) {            
            if (row.errors.isEmpty()) {
                continue;
            }

            for (String error : row.errors) {
                errors.add(
                    new Bulk_Shift_Upload_Error__c(
                        error_message__c = error,
                        Row_Number__c = row.rowNumber,
                        Shift_ID__c = row.shiftIdStr,
                        Bulk_Shift_Upload__c = bsu.id
                    )
                );
            }

            this.hasLineErrors = true;
        }

        if (!errors.isEmpty()) {
            insert errors;
        }
    }

    private void initializeVariables() {               
        shiftsToUpdate = new List<sirenum__Shift__c>();        
        srows = new List<ShiftRow>();
        shiftRowsToUpdate = new List<ShiftRow>();        
    }

    private boolean isValidHeaders(Set<String> headers) {     
        System.debug(headers);   
        System.debug(this.template);            
        
        if (this.template.recordId__c != null && !headers.contains(this.template.recordId__c)) {
            this.errors.add('Shift Id heading not found. Heading name expected = ' + this.template.recordId__c);
        }

        if (this.template.Is_Approved__c != null && !headers.contains(this.template.Is_Approved__c)) {
            this.errors.add('Is Approved heading not found. Heading name expected = ' + this.template.Is_Approved__c);
        }
        
        if (this.template.PO_Number__c != null && !headers.contains(this.template.PO_Number__c)) {
            this.errors.add('PO Number heading not found. Heading name expected = ' + this.template.PO_Number__c);
        }

        if (this.template.Billable_Start_Date__c != null && !headers.contains(this.template.Billable_Start_Date__c)) {
            this.errors.add('Billable Start Date heading not found. Heading name expected = ' + this.template.Billable_Start_Date__c);
        }

        if (this.template.Billable_Start_Time__c != null && !headers.contains(this.template.Billable_Start_Time__c)) {
            this.errors.add('Billable Start Time heading not found. Heading name expected = ' + this.template.Billable_Start_Time__c);
        }

        if (this.template.Billable_End_Time__c != null && !headers.contains(this.template.Billable_End_Time__c)) {
            this.errors.add('Billable End Time heading not found. Heading name expected = ' + this.template.Billable_End_Time__c);
        }

        if (this.template.Billable_Hours__c != null && !headers.contains(this.template.Billable_Hours__c)) {
            this.errors.add('Billable Hours heading not found. Heading name expected = ' + this.template.Billable_Hours__c);
        }

        if (this.template.Job_Role__c != null && !headers.contains(this.template.Job_Role__c)) {
            this.errors.add('Job Role heading not found. Heading name expected = ' + this.template.Job_Role__c);
        }

        if (this.template.Site__c != null && !headers.contains(this.template.Site__c)) {
            this.errors.add('Site heading not found. Heading name expected = ' + this.template.Site__c);
        }

        if (this.template.Payroll_ID__c != null && !headers.contains(this.template.Payroll_ID__c)) {
            this.errors.add('Payroll Id heading not found. Heading name expected = ' + this.template.Payroll_ID__c);
        }

        if (this.template.Shift_Date__c != null && !headers.contains(this.template.Shift_Date__c)) {
            this.errors.add('Shift Date heading not found. Heading name expected = ' + this.template.Shift_Date__c);
        }

        if (this.template.Job_Role_Id__c != null && !headers.contains(this.template.Job_Role_Id__c)) {
            this.errors.add('Job Role Id heading not found. Heading name expected = ' + this.template.Job_Role_Id__c);
        }

        if (this.template.Site_Id__c != null && !headers.contains(this.template.Site_Id__c)) {
            this.errors.add('Site Id heading not found. Heading name expected = ' + this.template.Site_Id__c);
        }
        
        if (this.template.Actual_Start_Time__c != null && !headers.contains(this.template.Actual_Start_Time__c)) {
            this.errors.add('Actual Start Time heading not found. Heading name expected = ' + this.template.Actual_Start_Time__c);
        }

        if (this.template.Actual_End_Time__c != null && !headers.contains(this.template.Actual_End_Time__c)) {
            this.errors.add('Actual End Time heading not found. Heading name expected = ' + this.template.Actual_End_Time__c);
        }

        return (this.errors.size() == 0);
    }    

    public void setFailStatus(String error) {
        this.errors.add(error);
        updateLoadStatus(UPLOAD_FAIL_STATUS);        
    }

    public void updateLoadStatus(String status) {
        this.bsu.Status__c = status;
        this.bsu.Error_Message__c  = String.join(errors, '. ');
        System.debug(errors);
        System.debug(status);
        update bsu;
    }

    public void getHeaderMappings(String templateName) {
        List<Shift_Upload_Template__mdt> mapping = [select RecordID__c, Billable_Hours__c, Billable_Start_Date__c, 
                                                    Billable_Start_Time__c, Billable_End_Time__c, Date_Format__c,
                                                    Is_Approved__c,
                                                    Job_Role__c, Payroll_ID__c, PO_Number__c, Site__c,
                                                    Shift_Date__c, Job_Role_Id__c, 
                                                    Site_Id__c, Actual_Start_Time__c, Actual_End_Time__c, Actual_Start_Date__c
                                                    from Shift_Upload_Template__mdt where DeveloperName = :templateName];
        System.debug(mapping);
        if (mapping.size() == 0) {
            throw new StringException('Error: Timesheet Template, ' + templateName + ' not found.');  
        }
   
        this.template = mapping[0];
    }

    @testVisible
    private void setHeaderMappings(Shift_Upload_Template__mdt template) {
        this.template = template;
    } 

    class ShiftRow {        
        integer rowNumber;
 
        List<sirenum__Shift__c> shifts = new List<sirenum__Shift__c>();

        String shiftIdStr;
        String jobRoleName;
        String siteName;
        String shiftDateStr;
        String payrollId;
        
        Id jobRoleId;
        Id siteId;
        Id candidateId;

        String billableDateStr;
        String billableStartTimeStr;
        String billableEndTimeStr;
        String billableHoursStr;       
        String actualDateStr;
        String actualEndTimeStr;
        String actualStartTimeStr;
        

        String approvedShiftStr;
        String poNumber;

        Boolean approvedShift;
        
        Date shiftDate;

        Decimal billableHours;
        Date billableDate;
        Time billableStartTime;
        Time billableEndTime;
        Date actualDate;
        Time actualEndTime;
        Time actualStartTime;

        boolean ignore = false;

        List<String> errors = new List<String>();
        String timePattern ='^([0-1]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9].*)?';
        String defaultDatePattern =  '^([2-3][0-9]{3})-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$';

        ShiftRow(Shift_Upload_Template__mdt template, Bulk_Shift_Upload__c bsu, Map<String,Object> row) {           
            this.rowNumber = Integer.valueOf(row.get('__ROW_NUMBER__'));
            if (this.rowNumber == null || this.rowNumber < Integer.valueOf(bsu.First_Data_Row__c)) {
                this.ignore = true;
                return; 
            }

            if (template.RecordID__c != null) {
                this.shiftIdStr = (String) row.get(template.RecordID__c);

                if ( String.isBlank(this.shiftIdStr)) {
                    this.errors.add('Shift Id cannot be blank.');
                }

                try {
                    this.shifts.add(new sirenum__Shift__c(id = Id.valueOf(this.shiftIdStr)));
                } catch(Exception e) {
                    this.errors.add('The specified Shift Id is not a valid (Shift Id = ' + this.shiftIdStr + ').');
                }                        
            }

            if (template.RecordID__c == null && template.Job_Role_Id__c != null) {
                String jobRoleIdStr = (String) row.get(template.Job_Role_Id__c);
                
                if ( String.isBlank(jobRoleIdStr)) {
                    this.errors.add('Job Role Id cannot be blank.');
                }
                
                try {
                    this.jobRoleId = Id.valueOf(jobRoleIdStr);
                } catch(Exception e) {
                    this.errors.add('The specified Job Role Id is not a valid (Job Role Id = ' + jobRoleIdStr + ').');
                }
            } else if (template.RecordID__c == null && template.Job_Role__c != null) {
                this.jobRoleName = (String) row.get(template.Job_Role__c);

                if (String.isBlank(this.jobRoleName)) {
                    this.errors.add('Job Role cannot be blank.');
                }                
            }

            if (template.RecordID__c == null && template.Site_Id__c != null) {
                String siteIdStr = (String) row.get(template.Site_Id__c);
                
                if ( String.isBlank(siteIdStr)) {
                    this.errors.add('Site Id cannot be blank.');
                }
                
                try {
                    this.siteId = Id.valueOf(siteIdStr);
                } catch(Exception e) {
                    this.errors.add('The specified Site Id is not a valid (Site Id = ' + siteIdStr + ').');
                }
            } else if (template.RecordID__c == null && template.Site__c != null) {
                this.siteName = (String) row.get(template.Site__c);

                if (String.isBlank(this.siteName)) {
                    this.errors.add('Site cannot be blank.');
                }                
            }

            if (template.RecordID__c == null && template.Payroll_ID__c != null) {
                this.payrollId = (String) row.get(template.Payroll_ID__c);

                if (String.isBlank(this.payrollId)) {
                    this.errors.add('Payroll ID cannot be blank.');
                }                
            }

            if (template.RecordID__c == null && template.Shift_Date__c != null) {
                this.shiftDateStr = (String) row.get(template.Shift_Date__c);

                if (String.isBlank(shiftDateStr)) {
                    this.errors.add('Shift Date cannot be blank.');
                } else {
                    try { 
                        this.shiftDate = stringToDate(this.shiftDateStr, template.Date_Format__c);
                    } catch (Exception e) {
                        this.errors.add('The specified shift date is not a valid date  (Shift Date = ' + this.shiftDateStr + ').');
                    }    
                }
            }


            if (template.PO_Number__c != null  && !String.isBlank((String) row.get(template.PO_Number__c))) {
                this.poNumber= (String) row.get(template.PO_Number__c);                
            }
            
            if (template.Is_Approved__c != null) {
                this.approvedShiftStr= (String)  row.get(template.Is_Approved__c);
                if (!String.isBlank(this.approvedShiftStr)) {                    
                    try { 
                        this.approvedShift = Boolean.valueOf(this.approvedShiftStr);
                    } catch (Exception e) {
                        this.errors.add('The specified Is Approved is not a boolean value (Is Approved = ' + this.approvedShiftStr + ').');
                    }
                }
            }

            if (template.Billable_Hours__c != null) {
                this.billableHoursStr= (String) row.get(template.Billable_Hours__c);
                if (!String.isBlank(this.billableHoursStr)) {
                    try { 
                        this.billableHours = Decimal.valueOf(this.billableHoursStr);
                    } catch (Exception e) {
                        this.errors.add('The specified billable hours is not a valid value (Billable Hours = ' + this.billableHoursStr + ').');
                    }
                }
            }
            
            if (this.billableHours > 23) {
                this.errors.add('The specified billable hours are too large (Billable Hours = ' + this.billableHoursStr + ').');
            }
            
            if (template.Billable_Start_Date__c != null) {
                this.billableDateStr= (String) row.get(template.Billable_Start_Date__c);
                if (!String.isBlank(this.billableDateStr)) {
                    try { 
                        this.billableDate = stringToDate(this.billableDateStr, template.Date_Format__c);
                    } catch (Exception e) {
                        this.errors.add('The specified billable date is not a valid date  (Billable Date = ' + this.billableDateStr + ').');
                    }

                    if (this.billableDate == null) {
                        this.errors.add('The specified billable date is not a valid date  (Billable Date = ' + this.billableDateStr + ').');
                    }
                }
            }


            if (template.Billable_Start_Time__c != null) {
                this.billableStartTimeStr= (String) row.get(template.Billable_Start_Time__c);
                if (!String.isBlank(this.billableStartTimeStr)) {               
                    this.billableStartTime = formatTime(this.billableStartTimeStr);
                    if (this.billableStartTime == null) {
                        this.errors.add('The specified billable start time is not a valid time (Billable Start Time = ' + this.billableStartTimeStr + ').');
                    }
                }
            }     

            if (template.Billable_End_Time__c != null) {
                this.billableEndTimeStr= (String) row.get(template.Billable_End_Time__c);
                if (!String.isBlank(this.billableEndTimeStr)) {               
                    this.billableEndTime = formatTime(this.billableEndTimeStr);
                    if (this.billableEndTime == null) {
                        this.errors.add('The specified billable end time is not a valid time (Billable End Time = ' + this.billableEndTimeStr + ').');
                    }
                }
            }

            if (template.Actual_Start_Date__c != null) {
                this.actualDateStr= (String) row.get(template.Actual_Start_Date__c);
                if (!String.isBlank(this.actualDateStr)) {
                    try { 
                        this.actualDate = stringToDate(this.actualDateStr, template.Date_Format__c);
                    } catch (Exception e) {
                        this.errors.add('The specified actual date is not a valid date  (Actual Date = ' + this.actualDateStr + ').');
                    }

                    if (this.actualDate == null) {
                        this.errors.add('The specified actual date is not a valid date  (Actual Date = ' + this.actualDateStr + ').');
                    }
                }
            }
            
            if (template.Actual_End_Time__c != null) {
                this.actualEndTimeStr= (String) row.get(template.Actual_End_Time__c);
                if (!String.isBlank(this.actualEndTimeStr)) {               
                    this.actualEndTime = formatTime(this.actualEndTimeStr);
                    if (this.actualEndTime == null) {
                        this.errors.add('The specified actual end time is not a valid time (Actual End Time = ' + this.actualEndTimeStr + ').');
                    }
                }
            }

            if (template.Actual_Start_Time__c != null) {
                this.actualStartTimeStr= (String) row.get(template.Actual_Start_Time__c);
                if (!String.isBlank(this.actualStartTimeStr)) {               
                    this.actualStartTime = formatTime(this.actualStartTimeStr);
                    if (this.actualStartTime == null) {
                        this.errors.add('The specified actual start time is not a valid time (Actual Start Time = ' + this.actualStartTimeStr + ').');
                    }
                }
            }

            if (this.errors.size() == 0 && this.billableDate != null && (this.billableStartTime == null || (this.billableStartTime == null && this.billableHours == null))) {
                this.errors.add('If the  billable date is specified then the billable start time and either the billable end time or the billable hours must be specified.');
            } else if (this.errors.size() == 0 && this.billableStartTime != null && this.billableEndTime == null && this.billableHours == null) {
                this.errors.add('If the billable start time  is specified then either the billable end time or the billable hours must be specified.');
            }                        
        }
         
                
        Date stringToDate(String dateString, String dateFormat) {
            Date retDate;            
            if (String.isNotBlank(dateString)) {                   
                if (Pattern.matches(defaultDatePattern, dateString)) {
                    retDate = Date.valueOf(dateString);
                } else if (String.isNotBlank(dateFormat)) {                    
                    retDate = (new Moment(dateString, dateFormat)).toDate();
                }                
            }      
            
            return retDate;
        }
    
        Time formatTime(String timeStr) {        
            if (!Pattern.matches(timePattern, timeStr)) {
                return null;
            }
    
            List<String> tcs = timeStr.split(':');
    
            return Time.newInstance(Integer.valueOf(tcs[0]), Integer.valueOf(tcs[1]), 0,0);        
        }
    }    
}