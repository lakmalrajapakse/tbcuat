import { LightningElement, track, wire } from 'lwc';
import { debug } from 'c/debug';
import { handleException } from 'c/exceptions';
import Utils from './utils.js';
import moment from '@salesforce/resourceUrl/moment';
import momentTimezone from '@salesforce/resourceUrl/momentTimezone';
import { loadScript } from 'lightning/platformResourceLoader';
import getSetup from '@salesforce/apex/SIM_TimeApproval.getSetup';
import getData from '@salesforce/apex/SIM_TimeApproval.getData';
import { getRecord } from 'lightning/uiRecordApi';
import updateShifts from '@salesforce/apex/SIM_TimeApproval.updateShifts';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import SHIFT_OBJECT from '@salesforce/schema/sirenum__Shift__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import USER_ID from '@salesforce/user/Id';
import USER_TYPE from '@salesforce/schema/User.UserType';
import { showToast } from 'c/toasts';
// import TIME_TYPE_FIELD from '@salesforce/schema/sirenum__Shift__c.Time_Type__c';

export default class CandidateTimesheet extends NavigationMixin(LightningElement) {
    // for data set the payroll cycle id on contract 
    _DEFAULT_CURRENCY = null;
    _EVENT_FILTER_BUILT = 'event_filter_built';

    @track SHIFT_DESC;

    //All loaded records
    @track fullRecords = [];
    //Paginated Records
    @track records = [];

    @track showSaveResults = false;
    @track isLoading = false;
    @track hasRecords;
    @track isSaving = false;
    @track startDate;
    @track endDate;
    startDateFormatted;
    endDateFormatted;

    periods = {};
    formattedString;
    hasSignature = true;
    shiftSignatures;
    signatureLinks;
    jsonSignatures;
    timeTypeOptions = [];
    siteTimezones;
    direction=0;

    BOOL_TRUE = true;

    exportFile = '';
    linesInFile = '';
    isCommunityUser = false;

    // headers revised to reflect the shift import tool 
    //exportFileHeaders = 'Shift Id,Shift Name,Worker Name,Shift Date,Site Id,Site Name,Job Role Name,Scheduled Start Date,Scheduled End Date,Scheduled Start Time,Scheduled End Time,Actual Start Date,Actual End Date,Actual Start Time,Actual End Time,Approved Start Date,Approved End Date,Approved Start Time,Approved End Time,Total Approved Hours,Is Approved,Is Cancelled,Cancellation Reason,Query,WFM External Id,PO Number';
    exportFileHeaders = 'REFERENCE,WORKER,DATE,SITE,ROTA,JOB ROLE,START,END,REQUIRED SHIFTS,COMMENTS,CANCELLED,LOCATION,PO NUMBER,ACTUAL START DATE,ACTUAL START TIME,ACTUAL END DATE,ACTUAL END TIME,BILLABLE START DATE,BILLABLE START TIME,BILLABLE END DATE,BILLABLE END TIME,APPROVED';


    _CAN_SEE_PAY = false;
    _CAN_SEE_CHARGE = false;
    _CAN_ENTER_EXPENSES = false;
    _CAN_ENTER_ACTUAL = false;
    _CAN_ENTER_ABSOLUTE = false;
    _CAN_ENTER_BILLABLE = false;
    _CAN_ENTER_REPORTED = false;
    _CAN_REJECT_SHIFT = false;
    _CAN_SUBMIT = false;
    _CAN_APPROVE_PAY = false;
    _CAN_APPROVE_CHARGE = false;
    _CAN_SEE_APPROVE_PAY = false;
    _CAN_SEE_APPROVE_CHARGE = false;
    _LOCAL_STARTDATE = 'startDateId';
    _LOCAL_ENDDATE = 'endDateId';
    _LOCAL_FILTER = 'soqlFilter';
    _LOCAL_FILTER_BREADCRUMBS = 'filterBreadcrumbs';

    constructor() {
        super();
        this.addEventListener(this._EVENT_FILTER_BUILT, this.handleFilterChangeEvent.bind(this));
    }

    get _CAN_SEE_APPROVE_PAY_AND_CHARGE() {
        return this._CAN_SEE_APPROVE_CHARGE && this._CAN_SEE_APPROVE_PAY && this.hasRecords;
        
    }

    get _CAN_APPROVE_PAY_AND_CHARGE() {
        return this._CAN_APPROVE_CHARGE && this._CAN_APPROVE_PAY && this.hasRecords;
    }

    get _CAN_SUBMIT_ALL() {
        return this._CAN_SUBMIT && this.hasRecords;
    }

    @track selectedCycle = null;
    @track selectedPeriod = null;

    // @track updatedRecords = new Map();
    // @track updatedRecords = [];
    get hasChanges() {
        // return this.updatedRecords.length > 0
        return this.records.filter(record => record.isChanged).length > 0;
    }

    @wire(getRecord, { recordId: USER_ID, fields: [USER_TYPE] })
    wiredUser({ error, data }) {
        if (data) {
            this.isCommunityUser = data.fields.UserType.value === 'PowerCustomerSuccess';
            console.log('this is the communityuser: ',this.isCommunityUser );
        } else if (error) {
            console.error('Error fetching user data', error);
        }
    }

    /**
     * First phase of initialization
     * 
     **/
    connectedCallback() {
        this.initComponent();
        this.populateInputFields();
        
    }

    populateInputFields(){
        const checkboxes = this.template.querySelectorAll('lightning-input[type="checkbox-button"]');
        console.log('checkboxes: ',checkboxes);
        // Loop through the NodeList
        checkboxes.forEach((checkbox) => {
                console.log('checkbox: ',checkbox.disabled);
                console.log('checkbox value: ',checkbox.value);
                // Create and dispatch a change event to trigger the onchange handler
                const changeEvent = new Event('change', {
                    bubbles: true,
                    composed: true
                });
                checkbox.dispatchEvent(changeEvent);
           // }
        });


    }


    

    /**
 * Load Additional Resources
 * 
 * - Moment JS - library to help formatting times
 * - Luxon JS - modern library to help formatting times and determining week length aka intervals
 */
    @track isRendered = false;
    async renderedCallback() {
        if (this.isRendered)
            return;
        await Promise.all([
            loadScript(this, moment + '/moment.js'),
            loadScript(this, momentTimezone + '/moment-timezone-with-data.js')
        ]).then(() => {
            debug('Loaded Moment and Moment-timezone Libraries Successfully');
            this.isRendered = true;
        })
            .catch(err => {
                handleException(this, err, true);
            });
    }

    disconnectedCallback() {
        //this.remove(this._EVENT_FILTER_BUILT);
    }

    initComponent() {
        this.loadSetup();
    }

    /**
     * Cycle period selection handler
     */
    handleCyclePeriodChange(event) {
        this.selectedCycle = event.detail.selectedCycle;
        this.selectedPeriod = event.detail.selectedPeriod;
    }

    handleStartDateChange(event) {
        console.log(`start date selected ${event.currentTarget.value}`);
        this.weekStart = this.convertFormat(event.currentTarget.value);
    }

    handleEndDateChange(event) {
        console.log(`end date selected ${event.currentTarget.value}`);
        this.weekEnd = this.convertFormat(event.currentTarget.value);
    }


    /**
     * handles obtaining results from filtering records
     * 
     * @param {*} event
     */
    @track shiftsSOQLfilter = null;
    @track filterBreadcrumbs = null;
    handleFilterChangeEvent(event) {
        debug('handleFilterChangeEvent', event.detail);
        this.shiftsSOQLfilter = event.detail.soqlFilter;
        this.filterBreadcrumbs = {
            crossGroupOperator: event.detail.crossGroupOperator,
            groups: event.detail.groups
        };

        this.setFiltersCache();
        this.filterToggle(false);
        this.refresh();
    }

    get totalResultsCount() {
        return this.fullRecords ? this.fullRecords.length : 0;
    }

    /**
     * save filters to local storage
     */
    setFiltersCache() {
        localStorage.setItem(this._LOCAL_STARTDATE, (this.startDate !== undefined && this.startDate !== null && this.startDate !== '' ? this.startDate : null));
        localStorage.setItem(this._LOCAL_ENDDATE, (this.endDate !== undefined && this.endDate !== null && this.endDate !== '' ? this.endDate : null));
        localStorage.setItem(this._LOCAL_FILTER, (this.shiftsSOQLfilter && this.shiftsSOQLfilter.length > 0 ? this.shiftsSOQLfilter : null));
        localStorage.setItem(this._LOCAL_FILTER_BREADCRUMBS, (this.filterBreadcrumbs ? JSON.stringify(this.filterBreadcrumbs) : null));
    }

    // @track showFiltersModal = false;
    filterToggle(state) {
        if (state !== undefined && (typeof variable === 'boolean')) {
            this.showFiltersModal = state;
        } else {
            this.showFiltersModal = !this.showFiltersModal;
        }

        this.populateFiltersModal();
    }

    @track filterComponentValue = null;
    populateFiltersModal() {
        let compValue = null;
        if (this.filterBreadcrumbs && this.filterBreadcrumbs != null) {
            compValue = {
                crossGroupOperator: JSON.parse(JSON.stringify(this.filterBreadcrumbs.crossGroupOperator)),
                groups: JSON.parse(JSON.stringify(this.filterBreadcrumbs.groups))
            }
        }
        this.filterComponentValue = compValue;
        debug('this.filterComponentValue', this.filterComponentValue);
    }

    /** Get SOQL Filter **/
    applyFilter() {
        this.template.querySelector('c-filter-component').getFilter();
    }

    @track showingFilters = false;
    toggleFiltersPanel(forceAction) {
        if (forceAction === undefined || forceAction === null || typeof forceAction !== "boolean") {
            //Toggle previous state
            this.showingFilters = !this.showingFilters;
        } else {
            //Requested specific state
            this.showingFilters = !!forceAction;
        }

        let panel = this.template.querySelector('.slds-panel');
        if (this.showingFilters == true) {
            panel.classList.add('slds-is-open');
        } else {
            panel.classList.remove('slds-is-open');
        }
    }

    /** 
     * When invoked, we will open the fieters editor
     */
    @track showFiltersModal = false;
    openFiltersModal() {
        this.showFiltersModal = true;
    }
    closeFiltersModal() {
        this.showFiltersModal = false;
    }


    @track filterComponentValue = null;
    populateFiltersModal() {
        let compValue = null;
        if (this.filterBreadcrumbs && this.filterBreadcrumbs != null) {
            compValue = {
                crossGroupOperator: JSON.parse(JSON.stringify(this.filterBreadcrumbs.crossGroupOperator)),
                groups: JSON.parse(JSON.stringify(this.filterBreadcrumbs.groups))
            }
        }
        this.filterComponentValue = compValue;
    }

    currentPage = 1;
    itemsPerPage = 25;
    handlePaginationChange(event) {
        this.resetState();

        this.currentPage = event.detail.currentPage;
        this.itemsPerPage = event.detail.itemsPerPage;
        this.isLoading = true;
        this.records = [];

        this.updatePagination(event.detail.currentPage, event.detail.itemsPerPage, this.fullRecords).then((subsetRecords) => {
            this.records = [...subsetRecords];
        }).catch(err => {
            handleException(this, err, true);
        }).finally(() => {
            this.isLoading = false;
            this.hasRecords = this.records?.length > 0;
        })
    }

    updatePagination(currentPage = 1, itemsPerPage = 25, records = []) {
        this.isLoading = true;
        return new Promise((resolve, reject) => {
            try {
                if (records && records.length > 0) {
                    for (let record of records) {
                        if (record.hasOwnProperty('isChanged')) {
                            delete record.isChanged;
                        }
                    }
                    let maxIndex = (currentPage * itemsPerPage);
                    let minIndex = (maxIndex - itemsPerPage);
                    let subsetRecords = records.slice(minIndex, maxIndex);
                    // resolve(subsetRecords);
                    setTimeout(() => { resolve(JSON.parse(JSON.stringify(subsetRecords))) }, 10);
                }

                // resolve([]);
                setTimeout(() => { resolve([]) }, 10);
            } catch (err) {
                reject(err.message);
            } finally {
                this.isLoading = false;
                this.hasRecords = this.records?.length > 0;
            }
        });
    }

    /**
     * Wire shift object Describe
     * 
     * - Used to get field labels
     * @param {*} param0 
     */
    @wire(getObjectInfo, { objectApiName: SHIFT_OBJECT })
    shiftInfo({ data, error }) {
        if (error) {
            console.error(error);
        }

        if (data) {
            this.SHIFT_DESC = data;
        }
    }

    /**
     * Refresh function - when called, 
     * this will cause a full shift data load with any
     * cached filters
     */
    refresh() {
        console.log('refresh parent');
        if (!this.checkValidity()) {
            return;
        }
        //Remove Genral Error Popover
        this.hasGeneralError = false;
        this.showGeneralError = false;
        this.exportFile = '';
        this.updatePagination();
        this.resetState();

        this.loadData();
    }

    resetState() {
        // this.updatedRecords = new Map();
        // this.updatedRecords = [];
        // this.hasChanges = false;
        this.lastLoadedRecordId = null;
        this.currentPage = 1;
    }

    loadSetup() {
        getSetup({ usrID: USER_ID }).then(results => {
            let response = JSON.parse(results);
            console.log('***getSetup Response', response);

            this._DEFAULT_CURRENCY = response.responseObject.currency;
            this._CAN_SEE_PAY = response.responseObject.canSeePay;
            this._CAN_SEE_CHARGE = response.responseObject.canSeeCharge;
            this._USE_TIME_TYPE_ON_SHIFT = true;
            this._CAN_ENTER_EXPENSES = response.responseObject.canEnterExpenses;
            this._CAN_ENTER_ACTUAL = response.responseObject.canEnterActual;
            this._CAN_ENTER_BILLABLE = response.responseObject.canEnterBillable;
            this._CAN_ENTER_ABSOLUTE = response.responseObject.canEnterAbsolute;
            this._CAN_ENTER_REPORTED = response.responseObject.canEnterReported;
            this._CAN_REJECT_SHIFT = response.responseObject.canRejectShift;
            this._CAN_APPROVE_PAY = response.responseObject.canApprovePay;
            this._CAN_SUBMIT = response.responseObject.canSubmit;
            this._CAN_SEE_SUBMIT = response.responseObject.canSeeSubmit;
            this._CAN_APPROVE_CHARGE = response.responseObject.canApproveCharge;
            this._CAN_PROCESS_PREVIOUS = response.responseObject.canProcessPrevious;
            this._CAN_SEE_APPROVE_PAY = response.responseObject.canSeeApprovePay;
            this._CAN_SEE_APPROVE_CHARGE = response.responseObject.canSeeApproveCharge;
            this.userContactId = response.responseObject.userContactId;

        }).catch(err => {
            handleException(this, err, true);
        }).finally(fin => {
            this.loadData();
        });

    }


    loadData() {
        this.isLoading = true;
        this.fullRecords = [];
        this.records = [];

        this.fetchRecords().then(() => {
            console.log('we now have records with a magical quanitity of : '  +this.records.length);     
            this.hasGeneralError = false;
            this.showGeneralError = false;
            //Re-set any previous changes
            // this.updatedRecords = new Map();
            // this.updatedRecords = [];
            // this.hasChanges = false;
            this.showSaveResults = false;
        }).catch(err => {
            handleException(this, err, true);
        }).finally(() => {
            console.log('final record count in .finally=' + this.records.length);
            this.isLoading = false;
            this.hasRecords = this.records?.length > 0;
        });
    }

    lastLoadedRecordId = null;

    fetchRecords() {

            let { startOfWeek, endOfWeek } = this.getWeekStartAndEnd(new Date());
            this.weekStart = startOfWeek;
            this.weekEnd = endOfWeek;
            this.startDate = this.convertToDatePickerFormat(startOfWeek);
            this.endDate = this.convertToDatePickerFormat(endOfWeek);
            console.log('this.weekStart: ',this.weekStart);
            console.log('this.weekend: ',this.weekEnd);

        return new Promise((resolve, reject) => {
            getData({
                soqlFilter: this.shiftsSOQLfilter,
                // periodId: this.selectedPeriod,
                weekStart: this.weekStart,
                weekEnd: this.weekEnd,
                filterSites: this.filterSites,
                filterContacts: this.filterContacts,
                filterPlacements: this.filterPlacements,
                resumeFromId: this.lastLoadedRecordId,
                filterBranches: this.filterBranches,
            }).then(results => {
                let response = JSON.parse(results);
                console.log('***loadData Response', response);

                if (response.success) {
                    this.siteTimezones = response.responseObject.siteTimezones;
                    this.defaultTimeZone = '';
                    if(response.responseObject.defaultTimeZone) this.defaultTimeZone = response.responseObject.defaultTimeZone;
                    this.CustomExternalIDForShiftRecords = response.responseObject.CustomExternalIDForShiftRecords;
                    console.log(`site time zones: ${this.siteTimezones}`);
                    console.log(`custom field for matching: ${this.CustomExternalIDForShiftRecords}`);
                    
                    this.signatureLinks = response.responseObject.signatureLinks;
                    let newRecords = Utils.convertShifts(response.responseObject.records, this.siteTimezones, this.signatureLinks,this.CustomExternalIDForShiftRecords,this.defaultTimeZone);
                    console.log('Loaded Batch Records: ', newRecords);
                    console.log('newrecords=' + newRecords.length);
                    Array.prototype.push.apply(this.fullRecords, newRecords);

                    if (this.fullRecords && this.fullRecords.length > 0) {
                        this.lastLoadedRecordId = this.fullRecords[this.fullRecords.length - 1].Id;
                    }

                    if (newRecords.length > 0) {
                        //Recursively load more records
                        setTimeout(() => { return resolve(this.fetchRecords()) }, 0);
                    }
                    else {
                        //No more records to load in operation

                        //Sort records by conditions
                        Utils.sortRecords(this.fullRecords);
                        
                        //Apply pagination
                        this.updatePagination(1, this.itemsPerPage, this.fullRecords).then((subsetRecords) => {
                            this.records = [...subsetRecords];
                            console.log('subset code : ' + this.records.length);
                            return resolve();
                        }).catch(err => {
                            reject(err)
                        }).finally(() => {
                        });
                    }
                } else {
                    //Well Managed Error
                    reject(response.message);
                }
            }).catch(err => {
                //Un-Managed Error
                reject(err);
            });
        });
    }

    changeWeek(event) {

        if(event.target.dataset.direction=='next')
            this.direction=this.direction+7;
        else
        if(event.target.dataset.direction=='prev')
            this.direction=this.direction-7;

        this.refresh();
    }

    // @track hasChanges = false;
    @track showGeneralError = false;
    @track hasGeneralError = false;
    @track generalErrorMessage;
    saveChanges() {
        this.isSaving = true;
        this.hasGeneralError = false;
        this.showGeneralError = false;

        const fieldsToDelete = ['Name', 'attributes'];
        let copyOfRecords = JSON.parse(JSON.stringify(this.records));
        let updatedRecords = copyOfRecords.filter(record => record.isChanged).map(record => {
            for (let field of fieldsToDelete) {
                delete record.shift[field];
            }
            for (const fieldName in record.shift) {
                if (fieldName.indexOf('__r') > 0) {
                    delete record.shift[fieldName];
                }
            }
            return record.shift;
        });


        debug('Saving...', updatedRecords);
        console.log('SIMON updatedRecords ', JSON.stringify(updatedRecords));
        updateShifts({
            jsonData: JSON.stringify(updatedRecords)
        }).then(results => {
            let response = JSON.parse(results);
            console.log('***updateShifts Response', response);

            if (response.success) {
                //All shifts saved successfully
                this.refresh();
            } else {
                this.processSaveErrors(response.responseObject);
            }
        }).catch(err => {
            handleException(this, err, true);
            this.hasGeneralError = true;
            this.showGeneralError = true;
            this.generalErrorMessage = unmngErr;
        }).finally(fin => {
            this.isSaving = false;
        });
    }

    processSaveErrors(saveResultItems) {
        debug('saveResultItems', saveResultItems);
        let shiftSaveResults = new Map();

        for (let i = 0; i < saveResultItems.length; i++) {
            shiftSaveResults.set(saveResultItems[i].recId, saveResultItems[i]);
        }

        for (let i = 0; i < this.records.length; i++) {
            if (!shiftSaveResults.has(this.records[i].Id)) {
                continue;
            }
            let shiftSaveResult = shiftSaveResults.get(this.records[i].Id)

            this.records[i]['saveSuccess'] = shiftSaveResult.success;
            this.records[i]['saveError'] = !shiftSaveResult.success;
            //Hide popover with results by defualt
            this.records[i]['showPopover'] = false;
            //Populate error messages for the record
            this.records[i]['errorMessages'] = shiftSaveResult.errors;

        }
        //Show Save Results
        this.showSaveResults = true;

        this.hasGeneralError = true;
        this.showGeneralError = true;
        this.generalErrorMessage = 'Some shifts failed to save. Please review the errors.';
    }

    updateRecords(shiftId, props) {
       
        let hasMatch = false;

        this.records.map(record => {
            if (record.Id == shiftId) {
                for (let prop of props) {
                    record.shift[prop.name] = prop.value;
                }
                record.isChanged = true;
            }
        })

    }

    recalculateTotalLength(shiftId, start, end) {
        console.log('recalculating');
        let hasMatch = false;

        this.records.map(record => {
            if (record.Id == shiftId) {
                const { hoursDecimal, hours, minutes, formattedString } = Utils.calculateLength(start, end, record);
                this.formattedString = formattedString;
                record.shiftTotalColumn = formattedString;
                record.decimalLength = hoursDecimal;
                record.Hours = hours;
                record.Minutes = minutes;
            }
        });

        const totalColumn = this.template.querySelector(`div[data-total="${shiftId}"]`);
        totalColumn.textContent = this.formattedString;
    }

    /**
     * This function handles the change in state
     * for non-checkbox fields (time fields) and updates
     * the respective shift record with the new value
     * of the change regiestered
     * 
     * @param {*} event 
     */
    handleTimesChange(event) {
       console.log('handletimeschange shiftapprovalmanager');
        let writeToStartFieldName = event.currentTarget.dataset.writeToStart;
        let writeToEndFieldName = event.currentTarget.dataset.writeToEnd;

        let shiftId = event.detail.uId;
        let apiStartValue = event.detail.value.startDT;
        let apiEndValue = event.detail.value.endDT;

        this.updateRecords(shiftId, [
            { name: writeToStartFieldName, value: apiStartValue },
            { name: writeToEndFieldName, value: apiEndValue }
        ]);

        if (writeToStartFieldName === 'sirenum__Actual_Start_Time__c' && writeToEndFieldName === 'sirenum__Actual_End_Time__c') {
            this.recalculateTotalLength(shiftId, apiStartValue, apiEndValue);
        }
    }

    handleTimeTypeChange(event) {
        console.log('handletimetypechange');
        let writeToFieldName = event.currentTarget.dataset.writeTo;

        let shiftId = event.currentTarget.dataset.recordId;
        let newValue = event.detail.value;

        this.updateRecords(shiftId, [
            { name: writeToFieldName, value: newValue }
        ]);


        for (let record of this.records) {
            if (record.Id == shiftId) {
                debug(`Found Record ${record.Id}`, newValue);
                record.portalHoursEntry = (newValue == 'Hours');
                break;
            }
        }
    }

    handleTextInputChange(event) {
        console.log('handletextinputchange');
        let writeToFieldName = event.currentTarget.dataset.writeTo;

        let shiftId = event.currentTarget.dataset.recordId;
        let newValue = event.detail.value;

        this.updateRecords(shiftId, [
            { name: writeToFieldName, value: newValue }
        ]);
    }

    getWeekStartAndEnd(currentDate) {
        currentDate.setDate(currentDate.getDate());
        // australia counts monday as first day of week js uses sunday so add one to each day
        const startDate = new Date(currentDate);
        if (startDate.getDay() !== 1) {
            startDate.setDate(currentDate.getDate() - currentDate.getDay());
            startDate.setDate(startDate.getDate() + 1);
        }

        startDate.setDate(startDate.getDate() + this.direction);

        const endDate = new Date(startDate);
        endDate.setDate(startDate.getDate() + (7 - startDate.getDay()));

        // get in dd/mm/yyyy format
        let startOfWeek = this.formatDate(startDate,true);
        let endOfWeek = this.formatDate(endDate,true);

        this.startDateFormatted = this.formatDate(startDate,false);
        this.endDateFormatted = this.formatDate(endDate,false);
        
        return {
            startOfWeek,
            endOfWeek
        };
    }

    convertToDatePickerFormat(dateString) {
        let date = dateString.split('/');
        // yyyy-mm-dd
        return `${date[2]}-${date[0]}-${date[1]}`;
    }

    formatDate(date,monthFirst) {
        let day = date.getDate();
        let month = date.getMonth() + 1;
        let year = date.getFullYear();

        day = day < 10 ? '0' + day : day;
        month = month < 10 ? '0' + month : month;

        if(monthFirst) 
        return `${month}/${day}/${year}`;
        else
        return `${day}/${month}/${year}`;
        
    }

    convertFormat(dateString) {
        let date = dateString.split('-');
        // mm/dd/yyyy
        return `${date[1]}/${date[2]}/${date[0]}`;
    }

    handleDateChange(event) {
        this.weekStart = event.detail.startDate;
        this.weekEnd = event.detail.endDate;
    }


    /**
     * Invoked by an onclick event on an element with the
     * attributes "shift" and "break"
     * 
     * - Shift attribute is the shift's ID that we are editing
     * - Break attribute is the break's ID that we are editing
     * 
     * @param {*} event 
     */
    handleBreakEdit(event) {
        let shiftId = event.currentTarget.dataset.shift;
        let breakId = event.currentTarget.dataset.break;
        let isEdit = event.currentTarget.dataset.isEdit;
        let editEndTime = event.currentTarget.dataset.endTime;
        let editStartTime = event.currentTarget.dataset.startTime;
        let date;
        let breakTime;

        if (!isEdit) {
            date = event.currentTarget.dataset.date;
            breakTime = this.convertToLWCDateTimeFormat(date, 14);
        }
        let startTime = editStartTime !== undefined ? editStartTime : breakTime;
        let endTime = editEndTime !== undefined ? editEndTime : breakTime;
        this.template.querySelector('c-shift-break-editor').openModal(shiftId, breakId, startTime, endTime);
    }

    convertToLWCDateTimeFormat(breakDate, hour) {
        let date = breakDate.split('/');
        let day = date[1].length === 2 ? date[1] : `0${date[1]}`;
        let month = date[0].length === 2 ? date[0] : `0${date[0]}`;
        return `${date[2]}-${month}-${day}T${hour}:00:00Z`;
    }

    get getExpressionBuilderWrapperClass() {
        return this.showFiltersModal ? '' : 'slds-hide';
    }

    /**
     * This function shows/hides the general error
     * pop-up
     */
    toggleGeneralError() {
        this.showGeneralError = !this.showGeneralError;
    }

    /**
     * This shows the errors popover 
     * 
     * - This is invoked from an onclick event where
     * the element that called this function must have attribute "shift"
     * - Shift attribute is the shift id for which we want to render the erros
     * popover
     * 
     * @param {*} event 
     */
    showErrorPopover(event) {
        let shiftId = event.currentTarget.dataset.shift;
        // for(let i = 0; i < this.fullRecords.length; i++){
        //     if(this.fullRecords[i].Id == shiftId){
        //         this.fullRecords[i]['showPopover'] = true;
        //     }else{
        //         //close any open popovers
        //         this.fullRecords[i]['showPopover'] = false;
        //     }
        // }

        this.closeErrorPopover();

        this.records.filter(record => {
            return record.Id == shiftId
        }).map(record => {
            record['showPopover'] = true;
        });
    }

    /**
     * This closes the errors popover
     */
    closeErrorPopover() {
        this.records.map(record => {
            record['showPopover'] = false;
        });
    }

    handleAddExpense(event){
        let shiftId = event.currentTarget.dataset.shift;
        let contactId = event.currentTarget.dataset.contact;
        let contractId = event.currentTarget.dataset.contract;
        let shiftDate = event.currentTarget.dataset.shiftDate;
        let expenseId = null;
        console.log('let contactId = event.currentTarget.dataset.contact: ',event.currentTarget.dataset);
        console.log('this.contactid in parent: ',this.contactId);
        this.template.querySelector('c-expense-editor').openModal(shiftId, contactId, contractId, shiftDate, expenseId);


    }


    handleExpenseEdit(event) {
        let shiftId = event.currentTarget.dataset.shift;
        let contactId = event.currentTarget.dataset.contact;
        let contractId = event.currentTarget.dataset.contract;
        let shiftDate = event.currentTarget.dataset.shiftDate;
        let expenseId = event.currentTarget.dataset.expense;
        this.template.querySelector('c-expense-editor').openModal(shiftId, contactId, contractId, shiftDate, expenseId);
    }

    /** 
     * Navigate to Record
     */
    handleNavigateClick(event) {
        console.log('navigating to record');
        let recID = event.currentTarget.dataset.record;
        let objType = event.currentTarget.dataset.object;
        this.navigateToRecordViewPage(recID, objType);
    }
    /** 
     * Navigate to Record
     */
    navigateToRecordViewPage(recID, objType) {
        // View a custom object record.
        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: recID,
                objectApiName: objType,
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }


    get hasRecords() {
        return this.records?.length > 0;
    }

    checkValidity() {
        return this.reportValidity();
    }

    reportValidity() {
        const allInputsAreValid = [...this.template.querySelectorAll('[data-validated-component=true]')]
            .reduce((validSoFar, inputCmp) => {
                //Get Validity
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        return allInputsAreValid;
    }

}