import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import getHolidays from '@salesforce/apex/DatatableController.getDatatable';
import saveRecords from '@salesforce/apex/DatatableController.saveRecords';

export default class ApproveHolidays extends LightningElement {

    // PRIVATE ATTRIBUTES 
    _holidaysList;
    _holidaysToDisplay;
    _dataList;
    _columnsList;
    _currentPage;
    _selectedEntry;
    _totalNumberOfRecords;
    _showSave;
    _selectedRecordIds;
    _selectedHolidayIds;
    _selectedContacts;
    @track _planCodesList;
    _selectedPlanCodes;
    _selectedBranches;
    _startDate;
    _endDate;

     /**
    * @description Constructor
    **/
    constructor() {
        super();
        this._holidaysList = new Array();
        this._holidaysToDisplay = new Array();
        this._selectedRecordIds = new Array();
        this._selectedHolidayIds = new Array();
        this._dataList = new Array();
        this._columnsList = new Array();
        this._currentPage = 1;
        this._selectedEntry = 25;
        this._selectedContacts = '';
        this._selectedPlanCodes = '';
        this._selectedBranches = '';
    }

    /**
    * @description Connected Callback Method
    **/
    connectedCallback() {
       this.getHolidays();
    }

    /**
    * @description RenderedCallbackMethod
    **/
    renderedCallback() {
        this.rerenderPaginator();
    }

    /**
    * @description Method to fetch the timesheets
    **/
    getHolidays() {
        if (this.template.querySelector('lightning-spinner')) {
            this.template.querySelector('lightning-spinner').classList.remove('slds-hide');
        }
        this._planCodesList = new Array();
        getHolidays({
            'dataTableParams' : {
                'className' : 'DatatableController.HolidayApprovalController',
                'filters' : {
                    'plancodes' : this._selectedPlanCodes,
                    'branches' : this._selectedBranches,
                    'contacts' : this._selectedContacts,
                    'startDate' : this._startDate,
                    'endDate' : this._endDate
                }
            }
        }).then(result => {
            if (result) {
                if (result.hasOwnProperty('columns')) {
                    this._columnsList = result.columns;
                }
                if (result.hasOwnProperty('data')) {
                    this._dataList = result.data;
                    this._holidaysList = result.data;
                }
                if (result.hasOwnProperty('planCodes')) {
                    result.planCodes.forEach(item => {
                        this._planCodesList.push({
                            'label' : item,
                            'value' : item
                        });
                    });
                }
                this.setHolidaysToDisplay();
            }
            if (this.template.querySelector('lightning-spinner')) {
                this.template.querySelector('lightning-spinner').classList.add('slds-hide');
            }
        }).catch(error => {
            console.log(error);
            this.error = error;
            if (this.template.querySelector('lightning-spinner')) {
                this.template.querySelector('lightning-spinner').classList.add('slds-hide');
            }
        });
    }

    /**
    * @description Method to handle entry change event
    **/
    setHolidaysToDisplay() {
        let recordsList = this._holidaysList;
        let startIndex = ((this._currentPage - 1) * this._selectedEntry);
        let endIndex = (this._currentPage * this._selectedEntry) >= recordsList.length ? recordsList.length : this._currentPage * this._selectedEntry;
        this._totalNumberOfRecords = recordsList.length;

        if (startIndex !== undefined && endIndex !== undefined) {
            this._holidaysToDisplay = new Array();
            for(let i=startIndex;i<endIndex;i++){
                this._holidaysToDisplay.push(recordsList[i]);
            } 
        }

        if (this._holidaysToDisplay.length == 0 && this.recordsList.length > 0) {
            this._currentPage = (this._currentPage - 1);
            let startIndex = ((this._currentPage - 1) * this._selectedEntry);
            let endIndex = (this._currentPage * this._selectedEntry) >= recordsList.length ? recordsList.length : this._currentPage * this._selectedEntry;
            if (startIndex !== undefined && endIndex !== undefined) {
                this._holidaysToDisplay = new Array();
                for(let i=startIndex;i<endIndex;i++){
                    this._holidaysToDisplay.push(recordsList[i]);
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
        return this._holidaysToDisplay.length > 0;
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
        return this._holidaysList.length > this._selectedEntry;
    }

    /**
    * @description Method to handle page change event
    **/
    handlePageChange(event) {
        this.template.querySelector('lightning-spinner').classList.remove('slds-hide');
        if (event && event.detail) {
            this._currentPage = event.detail;
            this.setHolidaysToDisplay();
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
                'className' : 'DatatableController.HolidayApprovalController',
                'employeeRequestIds' : JSON.stringify(this._selectedRecordIds)
            }
        }).then(result => {
            // show success message
            this.dispatchEvent(
                new ShowToastEvent({
                    "message" : "Holidays has/have been approved  successfully",
                    "variant" : 'success'
                }),
            );
            this.getHolidays();
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
    * @description Method to check if a record exists to display in a table
    **/
    get hasHolidaysToDisplay() {
        return this._holidaysToDisplay.length > 0;
    }

    /**
    * @description Method to handle select all
    **/
    handleSelectAll (event) {
        this._selectedRecordIds = new Array();
        this._holidaysList.forEach(item => {
            this._selectedRecordIds.push(item.Id);
        });
        this._selectedHolidayIds = [...this._selectedRecordIds];
    }

    /**
    * @description Method to handle on contact selection change
    **/
    handleOnContactSelectionChange(event) {
        this._selectedContacts = event.detail;
    }

    /**
    * @description Method to handle refresh
    **/
    handleRefresh() {
        this.getHolidays();
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
    * @description Method to handle on start date change
    **/
    handleOnStartDateChange(event) {
        this._startDate = event.target.value;
    }

    /**
    * @description Method to handle on end date change
    **/
    handleOnEndDateChange(event) {
        this._endDate = event.target.value;
    }
}