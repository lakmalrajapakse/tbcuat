import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import getTimesheets from '@salesforce/apex/DatatableController.getDatatable';
import saveRecords from '@salesforce/apex/DatatableController.saveRecords';

export default class ApproveTimesheets extends LightningElement {

    // PRIVATE ATTRIBUTES 
    _timesheetsList;
    _timesheetsToDisplay;
    _dataList;
    _columnsList;
    _currentPage;
    _selectedEntry;
    _totalNumberOfRecords;
    _showSave;
    _selectedRecordIds;
    @track _planCodesList;
    _selectedPlanCodes;
    _selectedBranches;
    _selectedAccounts;
    _selectedContacts;
    _selectedWeeks;
    _selectedTimesheetIds;


    /**
    * @description Constructor
    **/
    constructor() {
        super();
        this._timesheetsList = new Array();
        this._timesheetsToDisplay = new Array();
        this._selectedRecordIds = new Array();
        this._selectedTimesheetIds = new Array();
        this._dataList = new Array();
        this._columnsList = new Array();
        this._currentPage = 1;
        this._selectedEntry = 25;
        this._selectedPlanCodes = '';
        this._selectedBranches = '';
        this._selectedAccounts = '';
        this._selectedContacts = '';
        this._selectedWeeks = '';
    }

    /**
    * @description Connected Callback Method
    **/
    connectedCallback() {
       this.getTimesheets();
    }

    /**
    * @description RenderedCallbackMethod
    **/
    renderedCallback() {
        this.rerenderPaginator();
    }

    /**
    * @description Method to fetch the kit allocation items
    **/
    getTimesheets() {
        if (this.template.querySelector('lightning-spinner')) {
            this.template.querySelector('lightning-spinner').classList.remove('slds-hide');
        }
        this._planCodesList = new Array();
        getTimesheets({
            'dataTableParams' : {
                'className' : 'DatatableController.TimesheetApprovalController',
                'filters' : {
                    'plancodes' : this._selectedPlanCodes,
                    'branches' : this._selectedBranches,
                    'accounts' : this._selectedAccounts,
                    'contacts' : this._selectedContacts,
                    'weeks' : this._selectedWeeks,
                }
            }
        }).then(result => {
            if (result) {
                if (result.hasOwnProperty('columns')) {
                    this._columnsList = result.columns;
                }
                if (result.hasOwnProperty('data')) {
                    this._dataList = result.data;
                    this._timesheetsList = result.data;
                }
                if (result.hasOwnProperty('planCodes')) {
                    result.planCodes.forEach(item => {
                        this._planCodesList.push({
                            'label' : item,
                            'value' : item
                        });
                    });
                }
                this.setTimesheetsToDisplay();
            }
            this.template.querySelector('lightning-spinner').classList.add('slds-hide');
        }).catch(error => {
            console.log(error);
            this.error = error;
            this.template.querySelector('lightning-spinner').classList.add('slds-hide');
        });
    }

    /**
    * @description Method to handle entry change event
    **/
    setTimesheetsToDisplay() {
        let recordsList = this._timesheetsList;
        let startIndex = ((this._currentPage - 1) * this._selectedEntry);
        let endIndex = (this._currentPage * this._selectedEntry) >= recordsList.length ? recordsList.length : this._currentPage * this._selectedEntry;
        this._totalNumberOfRecords = recordsList.length;

        if (startIndex !== undefined && endIndex !== undefined) {
            this._timesheetsToDisplay = new Array();
            for(let i=startIndex;i<endIndex;i++){
                this._timesheetsToDisplay.push(recordsList[i]);
            } 
        }

        if (this._timesheetsToDisplay.length == 0 && this.recordsList.length > 0) {
            this._currentPage = (this._currentPage - 1);
            let startIndex = ((this._currentPage - 1) * this._selectedEntry);
            let endIndex = (this._currentPage * this._selectedEntry) >= recordsList.length ? recordsList.length : this._currentPage * this._selectedEntry;
            if (startIndex !== undefined && endIndex !== undefined) {
                this._timesheetsToDisplay = new Array();
                for(let i=startIndex;i<endIndex;i++){
                    this._timesheetsToDisplay.push(recordsList[i]);
                }
            }
        }
        this.rerenderPaginator();
    }

    /**
    * @description Method to rerender pagniator
    **/
    rerenderPaginator() {
        // call paginator 
        const paginator = this.template.querySelector('c-timesheet-paginator');
        if (paginator) {
            paginator.rerender(this._currentPage,this._selectedEntry,this._totalNumberOfRecords);
        }
    }

    /**
    * @description Method to check if a record exists to display in a table
    **/
    get hasRecordsToDisplay() {
        return this._timesheetsToDisplay.length > 0;
    }

    /**
    * @description Method to check if a record selected
    **/
    get hasRecordsSelected() {
        return this._selectedRecordIds.length == 0;
    }

     /**
    * @description Method to check if there are more than one page 
    **/
     get hasMoreThanOnePage() {
        return this._timesheetsList.length > this._selectedEntry;
    }

    /**
    * @description Method to handle page change event
    **/
    handlePageChange(event) {
        this.template.querySelector('lightning-spinner').classList.remove('slds-hide');
        if (event && event.detail) {
            this._currentPage = event.detail;
            this.setTimesheetsToDisplay();
            this.template.querySelector('lightning-spinner').classList.add('slds-hide');
        }
    }

    /**
    * @description Method to handle on row seletion
    **/
    handleOnRowSelection (event) {
        this._selectedRecordIds = new Array();
        let selectedRows = event.detail.selectedRows;
        selectedRows.forEach(item => {
            this._selectedRecordIds.push(item.Id);
        });
    }

    /**
    * @description Method to handle save 
    **/
    handleSave (event) {
        this.template.querySelector('lightning-spinner').classList.remove('slds-hide');
        saveRecords({
            'dataTableParams' : {
                'className' : 'DatatableController.TimesheetApprovalController',
                'timesheetIds' : JSON.stringify(this._selectedRecordIds)
            }
        }).then(result => {
            // show success message
            this.dispatchEvent(
                new ShowToastEvent({
                    "message" : "Timesheet(s) has been updated successfully",
                    "variant" : 'success'
                }),
            );
            this.getTimesheets();
            this.template.querySelector('lightning-spinner').classList.add('slds-hide');
        }).catch(error => {
            if (error && error.body && error.body.message) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        "message" : error.body.message,
                        "variant" : 'error'
                    }),
                );
            }
            this.template.querySelector('lightning-spinner').classList.add('slds-hide');
            this.error = error;
        });
    }

    /**
    * @description Method to handle on plan code change
    **/
    handleOnPlanCodeChange(event) {
        this._selectedPlanCodes = event.detail.value;
    }

    /**
    * @description Method to handle on branch selection change
    **/
    handleOnBranchSelectionChange(event) {
        this._selectedBranches = event.detail;
    }

    /**
    * @description Method to handle on account selection change
    **/
    handleOnAccountSelectionChange(event) {
        this._selectedAccounts = event.detail;
    }

    /**
    * @description Method to handle on contact selection change
    **/
    handleOnContactSelectionChange(event) {
        this._selectedContacts = event.detail;
    }

    /**
    * @description Method to handle on week selection change
    **/
    handleOnWeekSelectionChange(event) {
        this._selectedWeeks = event.detail;
    }

    /**
    * @description Method to handle on week selection change
    **/
    handleRefresh() {
        this.getTimesheets();
    }

    /**
    * @description Method to check if a record exists to display in a table
    **/
    get hasTimesheetsToDisplay() {
        return this._timesheetsToDisplay.length > 0;
    }

    /**
    * @description Method to handle select all
    **/
    handleSelectAll (event) {
        this._selectedRecordIds = new Array();
        this._timesheetsList.forEach(item => {
            this._selectedRecordIds.push(item.Id);
        });
        this._selectedTimesheetIds = [...this._selectedRecordIds];
    }
}