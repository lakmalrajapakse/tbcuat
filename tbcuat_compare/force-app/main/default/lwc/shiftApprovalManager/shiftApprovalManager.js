import { LightningElement, track, wire } from "lwc";
import { debug } from "c/debug";
import { handleException } from "c/exceptions";
import Utils from "./utils.js";
import moment from "@salesforce/resourceUrl/moment";
import momentTimezone from "@salesforce/resourceUrl/momentTimezone";
import { loadScript } from "lightning/platformResourceLoader";
import getSetup from "@salesforce/apex/SIM_TimeApproval.getSetup";
import getData from "@salesforce/apex/SIM_TimeApproval.getData";
import getManualRates from "@salesforce/apex/SIM_TimeApproval.getManualRates";
import { getRecord } from "lightning/uiRecordApi";
import updateShifts from "@salesforce/apex/SIM_TimeApproval.updateShifts";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { NavigationMixin } from "lightning/navigation";
import SHIFT_OBJECT from "@salesforce/schema/sirenum__Shift__c";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import USER_ID from "@salesforce/user/Id";
import USER_TYPE from "@salesforce/schema/User.UserType";
import { showToast } from "c/toasts";
import { handleTransactionError } from "c/utils";
import { CurrentPageReference } from 'lightning/navigation';
import getBreaks from '@salesforce/apex/SIM_TimeApproval.getBreaks';

// import TIME_TYPE_FIELD from '@salesforce/schema/sirenum__Shift__c.Time_Type__c';

import processPay from "@salesforce/apex/SIM_TimeApproval.processPay";

export default class ShiftApprovalManager extends NavigationMixin(LightningElement) {
    // for data set the payroll cycle id on contract
    _DEFAULT_CURRENCY = null;
    _EVENT_FILTER_BUILT = "event_filter_built";

    @track SHIFT_DESC;

    //All loaded records
    @track fullRecords = [];
    //Paginated Records
    @track records = [];

    @track record = {};
    @track dummyToggle = false;

    @track showSaveResults = false;
    @track hasRecords;
    @track isSaving = false;
    @track startDate;
    @track endDate;

    periods = {};
    formattedString;
    hasSignature = true;
    shiftSignatures;
    signatureLinks;
    jsonSignatures;
    timeTypeOptions = [];
    siteTimezones;
    selectedPayrollCycle = null;
    includeAdhoc = false;
    approvedShiftFilter = this.approvedFilters[0].value;
    timesheetGenerationFilter = this.timesheetGenerationFilters[0].value;


    BOOL_TRUE = true;

    exportFile = "";
    linesInFile = "";
    isCommunityUser = false;

    _processingPay = false;
    _loadingData = false;
    _updatingPagination = false;
    _filterLoading = false;
    _isExporting = false;
    _isCommunity = false;

    get approvedFilters() {
        return [
            { label: 'View All Shifts', value: 'View All Shifts' },
            { label: 'Approved Shifts', value: 'Approved Shifts' },
            { label: 'Unapproved Shifts', value: 'Unapproved Shifts' },
        ];
    }

    get timesheetGenerationFilters() {
        return [
            { label: 'All', value: 'All' },
            { label: 'Automatic', value: 'Automatic' },
            { label: 'Manual', value: 'Manual' },
        ];
    }

    // headers revised to reflect the shift import tool
    //exportFileHeaders = 'Shift Id,Shift Name,Worker Name,Shift Date,Site Id,Site Name,Job Role Name,Scheduled Start Date,Scheduled End Date,Scheduled Start Time,Scheduled End Time,Actual Start Date,Actual End Date,Actual Start Time,Actual End Time,Approved Start Date,Approved End Date,Approved Start Time,Approved End Time,Total Approved Hours,Is Approved,Is Cancelled,Cancellation Reason,Query,WFM External Id,PO Number';
    exportFileHeaders =
        "Shift Name,Shift ID,Worker,Payroll Id,Client Reference Number,Client Code,Scheduled Date,Site ,Job Role,Job Name,Scheduled Start Time,Scheduled End Time,Actual Start Date,Actual Start Time,Actual End Time,Approved Hours,Rota,Location,Approved";
    exportManualTimesheetGenerationHeaders =
        "Shift Name,Shift ID,Worker,Payroll Id,Client Reference Number,Client Code,Scheduled Date,Site ,Job Role,Job Name,Rota,Location,Start Time,End Time,Rate Type,inTime Pay Element,Hours,Pay Rate,Charge Rate";
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
    _LOCAL_STARTDATE = "startDateId";
    _LOCAL_ENDDATE = "endDateId";
    _LOCAL_FILTER = "soqlFilter";
    _LOCAL_FILTER_BREADCRUMBS = "filterBreadcrumbs";

    appliedFilters = {};

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
    @track periodLocked = false;

    /**
     * @description Wire method to get the record id
     **/
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this._isCommunity = currentPageReference.type == 'comm__namedPage';
        }
    }

    // @track updatedRecords = new Map();
    // @track updatedRecords = [];
    get hasChanges() {
        // return this.updatedRecords.length > 0
        return this.records.filter((record) => record.isChanged).length > 0;
    }

    @wire(getRecord, { recordId: USER_ID, fields: [USER_TYPE] })
    wiredUser({ error, data }) {
        if (data) {
            this.isCommunityUser = data.fields.UserType.value === "PowerCustomerSuccess";
            console.log("this is the communityuser: ", this.isCommunityUser);
        } else if (error) {
            console.error("Error fetching user data", error);
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

    populateInputFields() {
        const checkboxes = this.template.querySelectorAll('lightning-input[type="checkbox-button"]');
        console.log("checkboxes: ", checkboxes);
        // Loop through the NodeList
        checkboxes.forEach((checkbox) => {
            //if (!checkbox.disabled) {
            //checkbox.checked = true; // Set the checked property to true
            console.log("checkbox: ", checkbox.disabled);
            console.log("checkbox value: ", checkbox.value);
            // Create and dispatch a change event to trigger the onchange handler
            const changeEvent = new Event("change", {
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
        if (this.isRendered) return;

        try {
            await loadScript(this, moment + "/moment.js");
            await loadScript(this, momentTimezone + "/moment-timezone-with-data.js");
            this.isRendered = true;
            // ✅ Check if moment is loaded
            if (window.moment) {
                this.momentInitialized = true;
                console.log('Moment loaded:', window.moment().format());
            } else {
                console.error('Moment failed to load.');
            }
        } catch (error) {
            handleException(this, err, true);
        }
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
        // console.log(`start date selected ${event.currentTarget.value}`);
        this.weekStart = this.convertFormat(event.currentTarget.value);
    }

    handleEndDateChange(event) {
        // console.log(`end date selected ${event.currentTarget.value}`);
        this.weekEnd = this.convertFormat(event.currentTarget.value);
    }

    handleExportManualTimesheetGeneration(event) {
        this._isExporting = true;

        console.log("In handleExportManualTimesheetGeneration");
        this.exportManualTimesheetGeneration()
            .then(() => {
            })
            .catch((err) => {
                handleException(this, err, true);
            })
            .finally(() => {
                console.log("In handleExportManualTimesheetGeneration finallly");
                this._isExporting = false;
            });

        console.log("Out of handleExportManualTimesheetGeneration");

    }

    exportManualTimesheetGeneration() {
        //"Shift Name,Shift ID,Worker,Payroll Id,Client Reference Number,Client Code,Scheduled Date,Site ,Job Role,Job Name,Rota,Location,Start Time,End Time,Rate_Type,inTime PayElement,Hours,Pay Rate,Charge Rate";
        console.log("In exportManualTimesheetGeneration");
        let data = this.fullRecords ?? [];
        data = data
            .filter((record) => {
                return record.shift.Approved__c && record.shift.sirenum__Contract__r.Manual_Timesheet_Generation__c && !record.hasTimesheet
            });

        console.log("In exportManualTimesheetGeneration data", data);

        if (data.length === 0) {
            showToast(this, "No records found for manual timesheet generation.", "warning");
            return Promise.resolve([]);
        }


        const jobRoles = data.map((record) => { return record.shift.sirenum__Team__c; })
        const jobRoleSet = new Set(jobRoles);

        return new Promise((resolve, reject) => {
            getManualRates({ jobRoles: [...jobRoleSet] }).then((results) => {
                let response = JSON.parse(results);
                console.log("***loadData Response", results);

                if (response.success) {
                    const manualRatesMap = new Map();
                    response.responseObject.records.forEach((rec) => {
                        if (!manualRatesMap.has(rec.Job_Role__c)) {
                            manualRatesMap.set(rec.Job_Role__c, []);
                        }
                        manualRatesMap.get(rec.Job_Role__c).push(rec)
                    });

                    this.linesInFile = "";
                    this.exportFile.trim();

                    let lines = data.reduce((a, record) => {
                        const manualRates = manualRatesMap.get(record.shift.sirenum__Team__c);

                        const normalIndex = manualRates ? manualRates.findIndex((x) => x.Rate_Type__c === "Normal") : -1;

                        a.push(
                            [
                                record.shiftName,
                                record.Id,
                                record.workerName,
                                record.shift.sirenum__Contact__r?.InTimeExternalId__c,
                                record.shift.sirenum__Contact__r?.Client_Reference_Number__c,
                                record.shift.sirenum__Team__r?.sirenum__Account__r?.sirenum__Client__r?.Client_Code__c,

                                Utils.getLocalDate(record.schedStart, record.timezone),
                                record.siteName,
                                record.jobRole,
                                record.shift.s5m__BH4SFJob__r?.Name,
                                record.shift.sirenum__Rota__r?.Name,
                                record.shift.sirenum__Location__r?.Name,

                                Utils.getLocalTime(record.approvedStart, record.timezone),
                                Utils.getLocalTime(record.approvedEnd, record.timezone),
                                'Normal',
                                (normalIndex >= 0) ? manualRates[normalIndex].inTime_Pay_Element__c : "",
                                record.decimalLength,
                                (normalIndex >= 0) ? manualRates[normalIndex].Pay_Rate__c : "",
                                (normalIndex >= 0) ? manualRates[normalIndex].Charge_Rate__c : ""
                            ]
                        );

                        if (manualRates && manualRates.length > 0) {
                            for (let i = 0; i < manualRates.length; i++) {
                                if (i === normalIndex) continue; // Skip the normal rate as it is already added

                                a.push(
                                    [
                                        record.shiftName,
                                        record.Id,
                                        record.workerName,
                                        record.shift.sirenum__Contact__r?.InTimeExternalId__c,
                                        record.shift.sirenum__Contact__r?.Client_Reference_Number__c,
                                        record.shift.sirenum__Team__r?.sirenum__Account__r?.sirenum__Client__r?.Client_Code__c,

                                        Utils.getLocalDate(record.schedStart, record.timezone),
                                        record.siteName,
                                        record.jobRole,
                                        record.shift.s5m__BH4SFJob__r?.Name,
                                        record.shift.sirenum__Rota__r?.Name,
                                        record.shift.sirenum__Location__r?.Name,

                                        Utils.getLocalTime(record.approvedStart, record.timezone),
                                        Utils.getLocalTime(record.approvedEnd, record.timezone),
                                        manualRates[i].Rate_Type__c,
                                        manualRates[i].inTime_Pay_Element__c,
                                        0,
                                        manualRates[i].Pay_Rate__c,
                                        manualRates[i].Charge_Rate__c
                                    ]
                                );
                            }
                        }
                        return a;
                    }, []);

                    if (lines && lines.length) {
                        for (let line of lines) {
                            this.linesInFile += line.join(",") + "\n";
                        }
                    }

                    this.exportFile = this.linesInFile;
                    if (this.exportFile.length > 0) {
                        this.exportFile = this.exportFile;
                        let downloadElement = document.createElement("a");
                        downloadElement.href = `data:text/csv;charset=utf-8,${encodeURI(this.exportManualTimesheetGenerationHeaders + "\n" + this.exportFile)}`;
                        downloadElement.target = "_self";
                        downloadElement.download = `${new Date().toLocaleDateString() + "-manualTimesheetGeneration"}.csv`;
                        document.body.appendChild(downloadElement);
                        downloadElement.click();
                        showToast(this, "You shifts have been exported in CSV format.", "success");
                        document.body.removeChild(downloadElement);
                    }

                    resolve([]);
                } else {
                    //Well Managed Error
                    reject(response.message);
                }
            })
                .catch((err) => {
                    //Un-Managed Error
                    reject(err);
                });
        });
    }

    handleExport(event) {
        this.linesInFile = "";
        this.exportFile.trim();
        //let data = this.fullRecords ?? [];
        let data = this.records ?? [];

        let lines = data.map((record) => {
            return [
                record.shiftName,
                record.Id,
                record.workerName,
                record.shift.sirenum__Contact__r?.InTimeExternalId__c,
                record.shift.sirenum__Contact__r?.Client_Reference_Number__c,
                record.shift.sirenum__Team__r?.sirenum__Account__r?.sirenum__Client__r?.Client_Code__c,

                Utils.getLocalDate(record.schedStart, record.timezone),
                record.siteName,
                record.jobRole,
                record.shift.s5m__BH4SFJob__r?.Name,

                Utils.getLocalTime(record.schedStart, record.timezone),
                Utils.getLocalTime(record.schedEnd, record.timezone),
                Utils.getLocalDate(record.actStart, record.timezone),
                Utils.getLocalTime(record.shift.sirenum__Actual_Start_Time__c, record.timezone),
                Utils.getLocalTime(record.shift.sirenum__Actual_End_Time__c, record.timezone),
                record.shift.sirenum__Billable_Shift_Length_Decimal__c,

                record.shift.sirenum__Rota__r?.Name,
                record.shift.sirenum__Location__r?.Name,

                record.isApproved
            ];
        });

        if (lines && lines.length) {
            for (let line of lines) {
                console.log("" + JSON.parse(JSON.stringify(line)));
                this.linesInFile += line.join(",") + "\n";
            }
        }

        this.exportFile = this.linesInFile;
        if (this.exportFile.length > 0) {
            this.exportFile = this.exportFile;
            let downloadElement = document.createElement("a");
            downloadElement.href = `data:text/csv;charset=utf-8,${encodeURI(this.exportFileHeaders + "\n" + this.exportFile)}`;
            downloadElement.target = "_self";
            downloadElement.download = `${new Date().toLocaleDateString() + "-shifts"}.csv`;
            document.body.appendChild(downloadElement);
            downloadElement.click();
            showToast(this, "You shifts have been exported in CSV format.", "success");
            document.body.removeChild(downloadElement);
        }
    }

    /* handleImport(event) {
        if (this.isCommunityUser) {
            var url = "/s/importshiftpage"; // get from processing apex response
            window.open(url, "_blank");
        } else {
            var url = "/lightning/n/Shift_Import";
            window.open(url, "_blank");
        }
    } */

    handleImport(event) {
        this[NavigationMixin.GenerateUrl]({
            type: "standard__component",
            attributes: {
                componentName: "c__bulkShiftUploadLink"
            }
        }).then(url => { window.open(url); });

    }

    handleManualTimeGeneration(event) {
        this[NavigationMixin.GenerateUrl]({
            type: "standard__component",
            attributes: {
                componentName: "c__manualTimesheetGenerationLink"
            }
        }).then(url => { window.open(url); });

    }

    handleOpenQuery(event) {
        console.log(`query:: ${event.currentTarget.dataset.query}`);
        this.template.querySelector("c-query-modal").openModal(event.currentTarget.dataset.query);
    }
    /**
     * Workers selection handler
     */
    @track filterContacts = [];
    handleContactsSelect(event) {
        this.filterContacts = event.detail;
        debug("handleContactsSelect", this.filterContacts);
    }

    /**
     * Site selection handler
     */
    @track filterSites = [];
    handleSitesSelect(event) {
        this.filterSites = event.detail;
        debug("handleSiteSelect", this.filterSites);
    }

    /**
     * Site selection handler
     */
    @track filterPlanCodes = [];
    handlePlanCodeSelect(event) {
        this.filterPlanCodes = event.detail;
        debug("handlePlanCodeSelect", this.filterPlanCodes);
    }

    /**
     * Placement selection handler
     */
    @track filterPlacements = [];
    handlePlacementSelect(event) {
        this.filterPlacements = event.detail;
        debug("handlePlacementSelect", this.filterPlacements);
    }

    @track filterRoles = [];
    handleRoleSelect(event) {
        this.filterRoles = event.detail;
        debug("handleRoleSelect", this.filterRoles);
    }

    /**
     * Payroll cycle selection handler
     */
    @track filterPayrollCycles = [];
    handlePayrollCycleSelect(event) {
        this.filterPayrollCycles = event.detail;
        debug("handlePayrollCycleSelect", this.filterPayrollCycles);
    }

    /**
     * handles obtaining results from filtering records
     *
     * @param {*} event
     */
    @track shiftsSOQLfilter = null;
    @track filterBreadcrumbs = null;
    handleFilterChangeEvent(event) {
        debug("handleFilterChangeEvent", event.detail);
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
        localStorage.setItem(
            this._LOCAL_STARTDATE,
            this.startDate !== undefined && this.startDate !== null && this.startDate !== "" ? this.startDate : null
        );
        localStorage.setItem(
            this._LOCAL_ENDDATE,
            this.endDate !== undefined && this.endDate !== null && this.endDate !== "" ? this.endDate : null
        );
        localStorage.setItem(
            this._LOCAL_FILTER,
            this.shiftsSOQLfilter && this.shiftsSOQLfilter.length > 0 ? this.shiftsSOQLfilter : null
        );
        localStorage.setItem(
            this._LOCAL_FILTER_BREADCRUMBS,
            this.filterBreadcrumbs ? JSON.stringify(this.filterBreadcrumbs) : null
        );
    }

    // @track showFiltersModal = false;
    filterToggle(state) {
        if (state !== undefined && typeof variable === "boolean") {
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
            };
        }
        this.filterComponentValue = compValue;
        debug("this.filterComponentValue", this.filterComponentValue);
    }

    /** Get SOQL Filter **/
    applyFilter() {
        this.template.querySelector("c-filter-component").getFilter();
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

        let panel = this.template.querySelector(".slds-panel");
        if (this.showingFilters == true) {
            panel.classList.add("slds-is-open");
        } else {
            panel.classList.remove("slds-is-open");
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
            };
        }
        this.filterComponentValue = compValue;
    }

    currentPage = 1;
    itemsPerPage = 25;
    handlePaginationChange(event) {
        this.resetState();

        this.currentPage = event.detail.currentPage;
        this.itemsPerPage = event.detail.itemsPerPage;
        this._updatingPagination = true;
        this.records = [];

        this.updatePagination(event.detail.currentPage, event.detail.itemsPerPage, this.fullRecords)
            .then((subsetRecords) => {
                this.records = [...subsetRecords];
            })
            .catch((err) => {
                handleException(this, err, true);
            })
            .finally(() => {
                this._updatingPagination = false;
                this.hasRecords = this.records?.length > 0;
            });
    }

    updatePagination(currentPage = 1, itemsPerPage = 25, records = []) {
        this._updatingPagination = true;
        return new Promise((resolve, reject) => {
            try {
                if (records && records.length > 0) {
                    for (let record of records) {
                        if (record.hasOwnProperty("isChanged")) {
                            delete record.isChanged;
                        }
                    }
                    let maxIndex = currentPage * itemsPerPage;
                    let minIndex = maxIndex - itemsPerPage;
                    let subsetRecords = records.slice(minIndex, maxIndex);
                    // resolve(subsetRecords);
                    setTimeout(() => {
                        resolve(JSON.parse(JSON.stringify(subsetRecords)));
                    }, 10);
                }

                // resolve([]);
                setTimeout(() => {
                    resolve([]);
                }, 10);
            } catch (err) {
                reject(err.message);
            } finally {
                this._updatingPagination = false;
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

    // @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: TIME_TYPE_FIELD })
    // timeTypeOptionsWire({ data, error }) {
    //     if (error){
    //         debug(error);
    //     }

    //     if (data) {
    //         this.timeTypeOptions = data.values.map(x => {return {label: x.label, value: x.value}});
    //     }
    // }

    get isLoading() {
        return this._processingPay || this._loadingData || this._updatingPagination || this._filterLoading || this._isExporting;
    }

    /**
     * Refresh function - when called,
     * this will cause a full shift data load with any
     * cached filters
     */
    refresh() {
        if (!this.checkValidity()) {
            return;
        }
        //Remove Genral Error Popover
        this.hasGeneralError = false;
        this.showGeneralError = false;
        this.exportFile = "";


        this.updatePagination();
        this.resetState();

        this.loadData();
    }

    calculateLength(startTime, endTime) {
        // console.log("SPC isRendered = " + this.isRendered);
        // console.log('SPC Raw input startTime:', startTime);
        // console.log('SPC Raw input endTime:', endTime);

        let start = window.moment.utc(startTime);
        let end = window.moment.utc(endTime);

        // console.log('SPC Start Time Moment Valid?', start.isValid());
        // console.log('SPC End Time Moment Valid?', end.isValid());

        if (!start.isValid() || !end.isValid()) {
            console.warn('SPC Invalid start or end time passed to calculateLength:', startTime, endTime);
            return {
                hoursDecimal: 0,
                hours: '0',
                minutes: '0',
                formattedString: 'Invalid duration'
            };
        }

        let duration = window.moment.duration(end.diff(start));
        let decimalHours = duration.asHours();

        let totalMinutes = Math.round(decimalHours * 60);
        let hours = Math.floor(totalMinutes / 60).toString();
        let mins = (totalMinutes % 60).toString();

        console.log('SPC Duration Calculation:', {
            decimalHours: decimalHours,
            hours: hours,
            minutes: mins,
            formattedString: `${hours} hours ${mins} mins`
        });

        return {
            hoursDecimal: decimalHours,
            hours: hours,
            minutes: mins,
            formattedString: `${hours} hours ${mins} mins`
        };
    }

    @track tempUnpaidBreakTotal;
    refreshBreak(event) {
        const shiftId = event.detail.shiftId;
        console.log("refreshBreak called with shiftId:", shiftId);

        getBreaks({ shiftId: shiftId })
            .then(result => {
                console.log('SPC getBreaks result raw:', result);

                let unpaidTotalMinutes = 0;

                this.records = this.records.map(rec => {
                    if (rec.shift.Id === shiftId) {
                        let unpaidTotalMinutesForRecord = 0;

                        const breaksWithMetadata = result.map(shiftBreak => {
                            let lengthData = { formattedString: 'Invalid duration', hoursDecimal: 0 };
                            try {
                                lengthData = this.calculateLength(
                                    shiftBreak.sirenum__Start_Time__c,
                                    shiftBreak.sirenum__End_Time__c
                                );
                            } catch (e) {
                                console.warn('calculateLength failed for', shiftBreak.Id, e);
                            }

                            if (!shiftBreak.sirenum__Paid_Break__c) {
                                unpaidTotalMinutesForRecord += Math.round(lengthData.hoursDecimal * 60);
                            }

                            return {
                                ...shiftBreak,
                                BreakHourMinuteLength: lengthData.formattedString,
                                PaidUnPaid: shiftBreak.sirenum__Paid_Break__c ? '(Paid)' : ''
                            };
                        });

                        rec.tempUnpaidBreakTotal = unpaidTotalMinutesForRecord;
                        unpaidTotalMinutes = unpaidTotalMinutesForRecord;

                        return {
                            ...rec,
                            breaks: breaksWithMetadata,
                            hasBreaks: breaksWithMetadata.length > 0,
                            tempUnpaidBreakTotal: unpaidTotalMinutesForRecord
                        };
                    }
                    return rec;
                });

                this.tempUnpaidBreakTotal = unpaidTotalMinutes;
                this.breaks = result;

                console.log('SPC refreshBreak complete. Unpaid total mins:', unpaidTotalMinutes);

                // Get the shift record and pass unpaid break total to recalculateTotalLength
                const record = this.records.find(r => r.shift.Id === shiftId);
                console.log('SPC found record for shiftId:', shiftId, record);
                // If we have actual pass them else use the Scheduled.
                console.log('THISONE ' + record.shift.sirenum__Billable_Start_Time__c);
                console.log('THISONE ' + record.shift.sirenum__Billable_End_Time__c);
                console.log('THISONE ' + record.shift.sirenum__Actual_Start_Time__c);
                console.log('THISONE ' + record.shift.sirenum__Scheduled_End_Time__c);

                let startTime = 0;
                let endTime = 0;

                if (record.shift.sirenum__Billable_Start_Time__c != null && record.shift.sirenum__Billable_End_Time__c != null) {
                    console.log('THISONE ' + record.shift.sirenum__Billable_Start_Time__c);
                    startTime = record.shift.sirenum__Billable_Start_Time__c;
                    endTime = record.shift.sirenum__Billable_End_Time__c;
                } else {
                    console.log('THISONE ' + record.shift.sirenum__Scheduled_Start_Time__c);
                    startTime = record.shift.sirenum__Scheduled_Start_Time__c;
                    endTime = record.shift.sirenum__Scheduled_End_Time__c;
                }

                console.log('SPC recalculateTotalLength with startTime:', startTime, 'endTime:', endTime);
                if (record && record.shift) {
                    this.recalculateTotalLength(
                        record.Id,
                        startTime,
                        endTime
                    );
                }
            })
            .catch(error => {
                console.error('Error fetching breaks:', error);
            });
    }





    resetState() {
        // this.updatedRecords = new Map();
        // this.updatedRecords = [];
        // this.hasChanges = false;
        this.lastLoadedRecordId = null;
        this.currentPage = 1;
    }

    loadSetup() {
        getSetup({ usrID: USER_ID })
            .then((results) => {
                let response = JSON.parse(results);
                console.log("***getSetup Response", JSON.stringify(response));

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
            })
            .catch((err) => {
                handleException(this, err, true);
            })
            .finally((fin) => {
                this.loadData();
            });
    }

    get sigs() {
        this.signatureLinks = JSON.stringify(this.signatureLinks);
        return Object.values(this.signatureLinks).map((signature) => ({
            Id: signature.Id,
            url: signature.Body ? URL.createObjectURL(signature.Body.inputStream) : ""
        }));
    }

    loadData() {
        this._loadingData = true;
        this.fullRecords = [];
        this.records = [];

        this.fetchRecords()
            .then(() => {
                console.log("we now have records with a magical quanitity of : " + this.records.length);
                this.hasGeneralError = false;
                this.showGeneralError = false;
                //Re-set any previous changes
                // this.updatedRecords = new Map();
                // this.updatedRecords = [];
                // this.hasChanges = false;
                this.showSaveResults = false;
            })
            .catch((err) => {
                handleException(this, err, true);
            })
            .finally(() => {
                console.log("final record count in .finally=" + this.records.length);
                this._loadingData = false;
                this.hasRecords = this.records?.length > 0;
            });
    }

    lastLoadedRecordId = null;

    handleTimesheetDeleted() {
        this.refresh();
    }

    handleTimesheetUpdated() {
        this.refresh();
    }

    fetchRecords() {
        const me = this;

        if (!this.weekStart && !this.weekEnd) {
            let { startOfWeek, endOfWeek } = this.getWeekStartAndEnd(new Date());
            this.weekStart = startOfWeek;
            this.weekEnd = endOfWeek;
            this.startDate = this.convertToDatePickerFormat(startOfWeek);
            this.endDate = this.convertToDatePickerFormat(endOfWeek);
            console.log("this.weekStart: ", this.weekStart);
            console.log("this.weekend: ", this.weekEnd);
        }
        return new Promise((resolve, reject) => {
            this.appliedFilters = {
                soqlFilter: this.shiftsSOQLfilter,
                weekStart: this.weekStart,
                weekEnd: this.weekEnd,
                filterSites: this.filterSites.map(x => x.id),
                filterContacts: this.filterContacts.map(x => x.id),
                filterPlacements: this.filterPlacements,
                resumeFromId: this.lastLoadedRecordId,
                filterPlanCodes: this.filterPlanCodes.map(x => x.id),
                filterRoles: this.filterRoles.map(x => x.id),
                periodId: this.selectedPayrollCycle,
                approvedShiftFilter: this.approvedShiftFilter,
                timesheetGenerationFilter: this.timesheetGenerationFilter
            };

            getData(this.appliedFilters)
                .then((results) => {
                    let response = JSON.parse(results);
                    console.log("***loadData Response", response);

                    if (response.success) {
                        this.siteTimezones = response.responseObject.siteTimezones;
                        this.defaultTimeZone = "";
                        if (response.responseObject.defaultTimeZone)
                            this.defaultTimeZone = response.responseObject.defaultTimeZone;
                        this.CustomExternalIDForShiftRecords = response.responseObject.CustomExternalIDForShiftRecords;
                        console.log(`site time zones: ${this.siteTimezones}`);
                        console.log(`custom field for matching: ${this.CustomExternalIDForShiftRecords}`);

                        this.signatureLinks = response.responseObject.signatureLinks;
                        console.log("about to start call of convert");
                        console.log("record length=" + response.responseObject.records.length);
                        let newRecords = Utils.convertShifts(
                            response.responseObject.records,
                            this.siteTimezones,
                            this.signatureLinks,
                            this.CustomExternalIDForShiftRecords,
                            this.defaultTimeZone
                        );

                        if (!me.includeAdhoc) {
                            newRecords = newRecords.filter(x => x.isAdhoc == false);
                        }

                        console.log("Loaded Batch Records: ", newRecords);
                        console.log("newrecords=" + newRecords.length);
                        Array.prototype.push.apply(this.fullRecords, newRecords);

                        if (this.fullRecords && this.fullRecords.length > 0) {
                            this.lastLoadedRecordId = this.fullRecords[this.fullRecords.length - 1].Id;
                        }

                        if (newRecords.length > 0) {
                            //Recursively load more records
                            setTimeout(() => {
                                return resolve(this.fetchRecords());
                            }, 0);
                        } else {
                            //No more records to load in operation

                            //Sort records by conditions
                            Utils.sortRecords(this.fullRecords);

                            //Apply pagination
                            this.updatePagination(1, this.itemsPerPage, this.fullRecords)
                                .then((subsetRecords) => {
                                    this.records = [...subsetRecords];
                                    console.log("subset code : " + this.records.length);
                                    return resolve();
                                })
                                .catch((err) => {
                                    reject(err);
                                })
                                .finally(() => { });
                        }
                    } else {
                        //Well Managed Error
                        reject(response.message);
                    }
                })
                .catch((err) => {
                    //Un-Managed Error
                    reject(err);
                });
        });
    }

    get showCosts() {
        if (!this._CAN_SEE_CHARGE && !this._CAN_SEE_PAY) return false;

        return true;
    }

    // @track hasChanges = false;
    @track showGeneralError = false;
    @track hasGeneralError = false;
    @track generalErrorMessage;
    saveChanges() {
        this.isSaving = true;
        this.hasGeneralError = false;
        this.showGeneralError = false;

        const fieldsToDelete = ["Name", "attributes"];
        let copyOfRecords = JSON.parse(JSON.stringify(this.records));
        let updatedRecords = copyOfRecords
            .filter((record) => record.isChanged)
            .map((record) => {
                for (let field of fieldsToDelete) {
                    delete record.shift[field];
                }
                for (const fieldName in record.shift) {
                    if (fieldName.indexOf("__r") > 0) {
                        delete record.shift[fieldName];
                    }
                }
                return record.shift;
            });

        debug("Saving...", updatedRecords);
        console.log("SIMON updatedRecords ", JSON.stringify(updatedRecords));
        updateShifts({
            jsonData: JSON.stringify(updatedRecords)
        })
            .then((results) => {
                let response = JSON.parse(results);
                console.log("***updateShifts Response", response);

                if (response.success) {
                    //All shifts saved successfully
                    this.refresh();
                } else {
                    this.processSaveErrors(response.responseObject);
                }
            })
            .catch((err) => {
                handleException(this, err, true);
                this.hasGeneralError = true;
                this.showGeneralError = true;
                this.generalErrorMessage = unmngErr;
            })
            .finally((fin) => {
                this.isSaving = false;
            });
    }

    processSaveErrors(saveResultItems) {
        debug("saveResultItems", saveResultItems);
        let shiftSaveResults = new Map();

        for (let i = 0; i < saveResultItems.length; i++) {
            shiftSaveResults.set(saveResultItems[i].recId, saveResultItems[i]);
        }

        for (let i = 0; i < this.records.length; i++) {
            if (!shiftSaveResults.has(this.records[i].Id)) {
                continue;
            }
            let shiftSaveResult = shiftSaveResults.get(this.records[i].Id);

            this.records[i]["saveSuccess"] = shiftSaveResult.success;
            this.records[i]["saveError"] = !shiftSaveResult.success;
            //Hide popover with results by defualt
            this.records[i]["showPopover"] = false;
            //Populate error messages for the record
            this.records[i]["errorMessages"] = shiftSaveResult.errors;
        }
        //Show Save Results
        this.showSaveResults = true;

        this.hasGeneralError = true;
        this.showGeneralError = true;
        this.generalErrorMessage = "Some shifts failed to save. Please review the errors.";
    }

    handleOpenSignature(event) {
        if (event.currentTarget.dataset.hasSignature) {
            let signatureLink = event.currentTarget.dataset.signatureLink;
            this.template.querySelector("c-signature-modal").openSignature(signatureLink);
        } else {
            this.template.querySelector("c-signature-modal").openSignature();
        }
    }

    updateRecords(shiftId, props) {
        debug("updateRecords function:", this.updatedRecords);
        debug("updateRecords shiftId:", shiftId);
        debug("updateRecords props:", props);
        let hasMatch = false;

        this.records.map((record) => {
            if (record.Id == shiftId) {
                for (let prop of props) {
                    record.shift[prop.name] = prop.value;
                }
                record.isChanged = true;
            }
        });

        // for(let updatedRecord of this.updatedRecords){
        //     if(updatedRecord.Id == shiftId){
        //         for(let prop of props){
        //             updatedRecord[prop.name] = prop.value;
        //         }
        //         hasMatch = true;
        //         break;
        //     }
        // }

        // if(!hasMatch){
        //     let updateRecord = {
        //         Id: shiftId
        //     };
        //     for(let prop of props){
        //         updateRecord[prop.name] = prop.value;
        //     }
        //     this.updatedRecords.push(updateRecord);
        // }

        // //Update records table
        // for(let record of this.records){
        //     if(record.Id == shiftId){
        //         for(let prop of props){
        //             record.shift[prop.name] = prop.value;
        //         }
        //         break;
        //     }
        // }

        // debug('updateRecords AFTER:', this.updatedRecords);
    }

    recalculateTotalLength(shiftId, start, end) {
        this.records.map((record) => {
            if (record.Id == shiftId) {
                if (record.tempUnpaidBreakTotal) {
                    console.log('YES WE HAVE DATA');
                    console.log('start param:', start);
                    console.log('end param:', end);

                    // Ensure we always parse a string
                    let startTime = window.moment.utc(start);
                    let endTime = window.moment.utc(end);

                    console.log('starttime param:', startTime);
                    console.log('end param:', endTime);

                    if (!startTime.isValid() || !endTime.isValid()) {
                        console.error('Invalid start or end datetime', start, end);
                        return;
                    }

                    endTime = endTime.subtract(record.tempUnpaidBreakTotal, 'minutes');

                    console.log('Adjusted endTime after subtracting unpaid break:', endTime);
                    // Subtract unpaid break minutes
                    let duration = window.moment.duration(endTime.diff(startTime));
                    console.log('1');
                    let decimalHours = duration.asHours();
                    console.log('2');
                    let length = window.moment.utc(decimalHours * 36000 * 100).format('HH:mm');
                    console.log('3');
                    let hours = Utils.parseTimeFromString(length, false, 'HH');
                    console.log('4');
                    let mins = Utils.parseTimeFromString(length, false, 'mm');
                    console.log('5');
                    // remove leading 0 if any
                    hours = hours[0] === '0' ? hours.substring(1) : hours;
                    mins = mins[0] === '0' ? mins.substring(1) : mins;

                    this.formattedString = `${hours} hours ${mins} mins`;
                    record.shiftTotalColumn = this.formattedString;
                    console.log('END YES WE HAVE DATA');

                } else {
                    const { hoursDecimal, hours, minutes, formattedString } =
                        Utils.calculateLength(start, end, record);

                    this.formattedString = formattedString;
                    record.shiftTotalColumn = formattedString;
                    record.decimalLength = hoursDecimal;
                    record.Hours = hours;
                    record.Minutes = minutes;
                }
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
        console.log("handletimeschange shiftapprovalmanager");
        let writeToStartFieldName = event.currentTarget.dataset.writeToStart;
        let writeToEndFieldName = event.currentTarget.dataset.writeToEnd;

        let shiftId = event.detail.uId;
        let apiStartValue = event.detail.value.startDT;
        let apiEndValue = event.detail.value.endDT;

        this.updateRecords(shiftId, [
            { name: writeToStartFieldName, value: apiStartValue },
            { name: writeToEndFieldName, value: apiEndValue }
        ]);

        if (
            writeToStartFieldName === "sirenum__Billable_Start_Time__c" &&
            writeToEndFieldName === "sirenum__Billable_End_Time__c"
        ) {
            this.recalculateTotalLength(shiftId, apiStartValue, apiEndValue);
        }
    }

    handleTimeTypeChange(event) {
        console.log("handletimetypechange");
        let writeToFieldName = event.currentTarget.dataset.writeTo;

        let shiftId = event.currentTarget.dataset.recordId;
        let newValue = event.detail.value;

        this.updateRecords(shiftId, [{ name: writeToFieldName, value: newValue }]);

        for (let record of this.records) {
            if (record.Id == shiftId) {
                debug(`Found Record ${record.Id}`, newValue);
                record.portalHoursEntry = newValue == "Hours";
                break;
            }
        }
    }

    handleTextInputChange(event) {
        console.log("handletextinputchange");
        let writeToFieldName = event.currentTarget.dataset.writeTo;

        let shiftId = event.currentTarget.dataset.recordId;
        let newValue = event.detail.value;

        this.updateRecords(shiftId, [{ name: writeToFieldName, value: newValue }]);
    }

    getWeekStartAndEnd(currentDate) {
        // australia counts monday as first day of week js uses sunday so add one to each day
        const startDate = new Date(currentDate);
        if (startDate.getDay() !== 1) {
            startDate.setDate(currentDate.getDate() - currentDate.getDay());
            startDate.setDate(startDate.getDate() + 1);
        }
        const endDate = new Date(startDate);
        endDate.setDate(startDate.getDate() + (7 - startDate.getDay()));

        // get in dd/mm/yyyy format
        let startOfWeek = this.formatDate(startDate);
        let endOfWeek = this.formatDate(endDate);

        return {
            startOfWeek,
            endOfWeek
        };
    }

    convertToDatePickerFormat(dateString) {
        let date = dateString.split("/");
        // yyyy-mm-dd
        return `${date[2]}-${date[0]}-${date[1]}`;
    }

    formatDate(date) {
        let day = date.getDate();
        let month = date.getMonth() + 1;
        let year = date.getFullYear();

        day = day < 10 ? "0" + day : day;
        month = month < 10 ? "0" + month : month;
        return `${month}/${day}/${year}`;
    }

    convertFormat(dateString) {
        let date = dateString.split("-");
        // mm/dd/yyyy
        return `${date[1]}/${date[2]}/${date[0]}`;
    }

    handleCycleChange(event) {
        console.log("dates from child");
        this.weekStart = event.detail.startDate;
        this.weekEnd = event.detail.endDate;

        this.selectedPayrollCycle = event.detail.cycle;
        this.periodLocked = (event.detail.locked  === 'true');

        console.log("Week Start:", this.weekStart);
        console.log("Week End:", this.weekEnd);
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
        console.log("handleBreakEdit");
        let shiftId = event.currentTarget.dataset.shift;
        let breakId = event.currentTarget.dataset.break;
        let isEdit = event.currentTarget.dataset.isEdit;
        let editEndTime = event.currentTarget.dataset.endTime;
        let editStartTime = event.currentTarget.dataset.startTime;
        let isPaid = (event.currentTarget.dataset.isPaid == "true");

        let date;
        let breakTime;

        console.log("handleBreakEdit", shiftId, breakId, isEdit, editEndTime, editStartTime, isPaid);
        if (!isEdit) {
            date = event.currentTarget.dataset.date;
            breakTime = this.convertToLWCDateTimeFormat(date, 14);
        }
        let startTime = editStartTime !== undefined ? editStartTime : breakTime;
        let endTime = editEndTime !== undefined ? editEndTime : breakTime;
        this.template.querySelector("c-shift-break-editor").openModal(shiftId, breakId, startTime, endTime, isPaid);
    }

    handleAddExpense(event) {
        let shiftId = event.currentTarget.dataset.shift;
        let contactId = event.currentTarget.dataset.contact;
        let contractId = event.currentTarget.dataset.contract;
        let shiftDate = event.currentTarget.dataset.date;
        let expenseId = null;
        this.template.querySelector('c-expense-editor').openModal(shiftId, contactId, contractId, shiftDate, expenseId);
    }

    handleEditExpense(event) {
        let shiftId = event.currentTarget.dataset.shift;
        let contactId = event.currentTarget.dataset.contact;
        let contractId = event.currentTarget.dataset.contract;
        let shiftDate = event.currentTarget.dataset.date;
        let expenseId = event.currentTarget.dataset.expense;
        this.template.querySelector('c-expense-editor').openModal(shiftId, contactId, contractId, shiftDate, expenseId);
    }

    async handleProcessPay() {
        try {
            this._processingPay = true;
            const contactNames = this.filterContacts.map(x => x.label);
            const siteNames = this.filterSites.map(x => x.label);
            const roleNames = this.filterRoles.map(x => x.label);

            await processPay({
                startDate: this.weekStart,
                endDate: this.weekEnd,
                contactNames: contactNames,
                siteNames: siteNames,
                roleNames: roleNames
            });
            showToast(this, "Timesheet generation queued. You will be notified on completion", "success");
        } catch (error) {
            handleTransactionError("Process Pay Error", error);
        } finally {
            this._processingPay = false;
        }
    }

    handleIncludeAdhocChange(event) {
        this.includeAdhoc = event.detail.checked;
    }

    handleApprovedShiftFilterChange(event) {
        this.approvedShiftFilter = event.detail.value;
    }

    handleTimesheetGenerationFilterChange(event) {
        this.timesheetGenerationFilter = event.detail.value;
    }

    get isFilteringPayrollCycle() {
        return this.selectedPayrollCycle;
    }

    get processPayDisabled() {
        return !this.isFilteringPayrollCycle || this.isSaving || this.periodLocked;
    }

    get manualTimesheetGenerationDisabled() {
        return !this.isFilteringPayrollCycle || this.isSaving || this.hasChanges;
    }

    get totalShifts() {
        return this.fullRecords.length;
    }

    get totalConsultantApprovedShifts() {
        return this.fullRecords.filter(x => x.isConsultantApproved).length;
    }

    get totalConsultantApprovedShiftsPercentage() {
        return this.totalConsultantApprovedShifts / this.totalShifts;
    }

    get totalConsultantApprovedShiftsProgress() {
        return this.totalConsultantApprovedShiftsPercentage * 100;
    }

    get totalPayrolledShifts() {
        return this.fullRecords.filter(x => x.hasTimesheet).length;
    }

    get totalPayrolledShiftsPercentage() {
        return this.totalPayrolledShifts / this.totalShifts;
    }

    get totalPayrolledShiftsProgress() {
        return this.totalPayrolledShiftsPercentage * 100;
    }

    get disableDatePicker() {
        return this.isFilteringPayrollCycle;
    }

    convertToLWCDateTimeFormat(breakDate, hour) {
        let date = breakDate.split("/");
        let day = date[1].length === 2 ? date[1] : `0${date[1]}`;
        let month = date[0].length === 2 ? date[0] : `0${date[0]}`;
        return `${date[2]}-${month}-${day}T${hour}:00:00Z`;
    }

    handleExpenseEdit(event) {
        let shiftId = event.currentTarget.dataset.shift;
        let contactId = event.currentTarget.dataset.contact;
        let contractId = event.currentTarget.dataset.contract;
        let shiftDate = event.currentTarget.dataset.shiftDate;
        let expenseId = event.currentTarget.dataset.expense;
        this.template.querySelector("c-expense-editor").openModal(shiftId, contactId, contractId, shiftDate, expenseId);
    }

    handleRejection(event) {
        if (event.detail.checked) {
            let shiftId = event.currentTarget.dataset.recordId;
            let rejectionReason = event.currentTarget.dataset.rejectionReason;
            let rejectionReasonOther = event.currentTarget.dataset.rejectionReasonOther;
            this.template.querySelector("c-rejection-editor").openModal(shiftId, rejectionReason, rejectionReasonOther);
        } else {
            this.handleCheckboxChange(event);
        }
    }

    updateRejection(event) {
        let shiftId = event.detail.shiftId;
        let rejectionReason = event.detail.rejectionReason;
        let rejectionReasonOther = event.detail.rejectionReasonOther;

        this.updateRecords(shiftId, [
            { name: "Rejected__c", value: true },
            { name: "Rejection_Reason__c", value: rejectionReason },
            { name: "Rejection_Reason_Other__c", value: rejectionReasonOther }
        ]);
    }

    get getExpressionBuilderWrapperClass() {
        return this.showFiltersModal ? "" : "slds-hide";
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

        this.records
            .filter((record) => {
                return record.Id == shiftId;
            })
            .map((record) => {
                record["showPopover"] = true;
            });
    }

    /**
     * This closes the errors popover
     */
    closeErrorPopover() {
        this.records.map((record) => {
            record["showPopover"] = false;
        });
    }

    /**
     * Navigate to Record
     */
    handleNavigateClick(event) {
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
                actionName: "view"
            }
        }).then((url) => {
            window.open(url, "_blank");
        });
    }

    /**
     * Approve all visible shifts
     */
    async approveAll() {
        console.log("Approve all triggered");
        new Promise((resolve) => {
            //Update the record UI
            for (let record of this.records) {
                if (!record.shift.Lock_Approve_Charge__c) {
                    debug(`Marking Record: `, record);
                    if (record.shift.sirenum__Contract__r.Manual_Timesheet_Generation__c) {
                        this.updateRecords(record.Id, [
                            { name: "Approved__c", value: true },
                            { name: "sirenum__Client_Approval_By__c", value: this.userContactId },
                            { name: "Approved_When__c", value: new Date() }
                        ]);
                    } else {
                        this.updateRecords(record.Id, [
                            { name: "sirenum__Allow_charge__c", value: true },
                            { name: "sirenum__Allow_pay__c", value: true },
                            { name: "sirenum__Client_Approval_By__c", value: this.userContactId },
                            { name: "Approved_When__c", value: new Date() }
                        ]);
                    }

                    const timeAndHoursCmp = this.template.querySelector(`c-input-time-and-hours[data-id="${record.Id}"]`);

                    if (timeAndHoursCmp) {
                        timeAndHoursCmp.triggerAutoTimes();
                    }

                    debug("Updated Record: ", record);
                }
            }
            setTimeout(() => resolve(), 10);
        })
            .then(() => { })
            .finally(() => { });
    }

    /**
     * Approve all visible shifts
    */
    async unapproveAll() {
        console.log("UnApprove all triggered");
        new Promise((resolve) => {
            //Update the record UI
            for (let record of this.records) {
                if (!record.shift.Lock_Approve_Charge__c) {
                    debug(`Marking Record: `, record);
                    if (record.shift.sirenum__Contract__r.Manual_Timesheet_Generation__c) {
                        this.updateRecords(record.Id, [
                            { name: "Approved__c", value: false },
                        ]);
                    } else {
                        this.updateRecords(record.Id, [
                            { name: "sirenum__Allow_charge__c", value: false },
                            { name: "sirenum__Allow_pay__c", value: false },
                        ]);
                    }

                    debug("Updated Record: ", record);
                }
            }
            setTimeout(() => resolve(), 10);
        })
            .then(() => { })
            .finally(() => { });
    }

    async approveAllForClients() {
        console.log("approveAllForClients triggered");
        new Promise((resolve) => {
            //Update the record UI
            for (let record of this.records) {
                debug(`Marking Record: `, record);
                this.updateRecords(record.Id, [{ name: "Client_Approved__c", value: true }]);
                debug("Updated Record: ", record);
            }
            setTimeout(() => resolve(), 10);
        })
            .then(() => { })
            .finally(() => { });
    }

    /**
     * When filters are loading, this function is called
     * by the filters component to help us show the user
     * an indication that the system is loading.
     *
     * @param {*} event
     */
    handleFilterLoadingState(event) {
        this._filterLoading = event.detail.isLoading;
    }

    /**
     * This function handles the change in state
     * for checkbox fields (Pay and Charge) and
     * updates the respective shift record with the
     * new value of the change registered
     *
     * @param {*} event
     */
    handleCheckboxChange(event) {
        console.log("handlecheckboxchange");
        let shiftId = event.currentTarget.dataset.recordId;
        let apiName = event.currentTarget.dataset.name;
        let apiNameSecond = event.currentTarget.dataset.nameSecond;
        let apiNameThird = event.currentTarget.dataset.approver;
        let apiValue = event.detail.checked;

        let fieldUpdates = [{ name: apiName, value: apiValue }];
        if (apiNameSecond) {
            fieldUpdates.push({ name: apiNameSecond, value: apiValue });
        }
        if (apiNameThird) {
            fieldUpdates.push({ name: apiNameThird, value: this.userContactId });
        }

        fieldUpdates.push({ name: "Approved_When__c", value: new Date() });
        this.updateRecords(shiftId, fieldUpdates);

        if (apiValue == true) {
            // Select the component that matches the shiftId
            const timeAndHoursCmp = this.template.querySelector(`c-input-time-and-hours[data-id="${shiftId}"]`);

            if (timeAndHoursCmp) {
                timeAndHoursCmp.triggerAutoTimes();
            }
        }
    }

    // get hasRecords() {
    //     return this.records?.length > 0;
    // }

    checkValidity() {
        return this.reportValidity();
    }

    reportValidity() {
        const allInputsAreValid = [...this.template.querySelectorAll("[data-validated-component=true]")].reduce(
            (validSoFar, inputCmp) => {
                //Get Validity
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            },
            true
        );

        return allInputsAreValid;
    }
}