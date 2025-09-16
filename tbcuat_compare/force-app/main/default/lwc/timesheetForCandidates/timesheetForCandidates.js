import { LightningElement, api, wire, track } from 'lwc';
import currentUserId from '@salesforce/user/Id';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getShifts from '@salesforce/apex/CandidateTimesheetController.getShifts';
import updateShifts from '@salesforce/apex/CandidateTimesheetController.updateShifts';

export default class TimesheetForCandidates extends LightningElement {
    @api recordId;
    @api objectApiName;

    _selectedDate;
    _datesList;
    _shiftsList;
    _dateToLookFor;
    _weekName;
    _weekDateFormat;
    _formFactor;
    _dateOptions;
    _selectedDateFromOption;
    _selectedShiftDateFromOption;
    _selectedShiftsList;
    _dataLoaded;

    isLoading = false;
    /**
    * @description Constructor
    **/
    constructor() {
        super();
        this._hasIntimeId = false;
        this._shiftsList = new Array();
        this._dateOptions = new Array();
        this._dataLoaded = false;
        this._selectedDate = new Date().toISOString().split('T')[0];
    }

    /**
    * @description Connected Callback Method
    **/
    connectedCallback() {
        if (this.objectApiName === 'User') {
            this.recordId = currentUserId;
        }
        this._formFactor = FORM_FACTOR;
        
        this.loadShifts();    
    }

    /**
    * @description get shifts
    **/     
    loadShifts() { 
        this.isLoading = true;
        console.log('selectedDate', this._selectedDate);
        console.log(this.recordId);


        getShifts({ recordId : this.recordId, dateToLookFor : this._selectedDate}).then((data) => {
            if (data) {
                console.log('data', data);
                this._shiftsList = new Array();
                this._dateOptions = new Array();
                if (data.hasOwnProperty('datesList')){
                    this._datesList = data.datesList;
                    this._datesList.forEach(item => {
                        this._dateOptions.push({
                            label: item.dateOptionLabel,
                            value: item.dateOptionValue
                        });
                    });
                    this._selectedDateFromOption = this._dateOptions[0].value;
                    this._selectedShiftDateFromOption = this._datesList[0];
                    let datesList = JSON.parse(JSON.stringify(this._datesList));
                    datesList[0].class +=  ' selectedShift';
                    this._datesList = datesList;
                }
                if (data.hasOwnProperty('shifts')){
                    this._shiftsList = data.shifts;
                }
                if (data.hasOwnProperty('weekName')){
                    this._weekName = data.weekName;
                }
                if (data.hasOwnProperty('weekDateFormat')){
                    this._weekDateFormat = data.weekDateFormat;
                }
            }            
        })
        .catch(error => {
            console.log(error);
            this.error = error;            
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    /**
    * @description Method to handle on selected date change
    **/ 
    handleSelectedDateChange(event) {        
        this._selectedDate = event.target.value;
        this.loadShifts();
    }

    /**
    * @description Method to handle next week
    **/ 
    handleNextWeek(event) {        
        let selectedDate = new Date(Date.parse(this._selectedDate));
        selectedDate.setDate(selectedDate.getDate() + 7);
        this._selectedDate = selectedDate.toISOString().split('T')[0];
        this.loadShifts();
    }

    /**
    * @description Method to handle previous week
    **/ 
    handlePreviousWeek(event) {        
        let selectedDate = new Date(Date.parse(this._selectedDate));
        selectedDate.setDate(selectedDate.getDate() - 7);
        this._selectedDate = selectedDate.toISOString().split('T')[0];
        this.loadShifts();
    }

    /**
    * @description Method to handle on date change
    **/ 
    handleOnDateChange(event) {
        this._selectedDateFromOption = event.currentTarget.dataset.id;
        let hasShift = this._datesList.find(item => item.dateOptionValue == event.currentTarget.dataset.id).hasShift;
        if (hasShift) {
            this.isLoading = true;
            this._selectedShiftDateFromOption = this._datesList.find(item => item.dateOptionValue == event.currentTarget.dataset.id);
            let datesList = JSON.parse(JSON.stringify(this._datesList));
            datesList.forEach(item => {
                item.class = 'shiftData '+(item.hasShift ? ' shiftDataMobile' : ' disabledBlock')+(item.dateOptionValue == event.currentTarget.dataset.id ? ' selectedShift':'');
            });
            this._datesList = datesList;
            if (this.template.querySelector('c-time-entry')) {
                this.template.querySelectorAll('c-time-entry').forEach((item) => {
                    item.refresh(this._selectedShiftDateFromOption);
                });
            }
            this.isLoading = false;
        }
    }

    /**
    * @description Method to handle on shift change
    **/ 
    handleOnShiftChange(event) {
        if (event && event.detail && event.detail.shift) {
            let shiftsList = JSON.parse(JSON.stringify(this._shiftsList));
            shiftsList.forEach(item => {
                item.shiftsList.forEach((shift, index) => {
                    if (shift.Id == event.detail.shift.Id) {
                        item.shiftsList[index] = event.detail.shift;
                    }
                });
            });
            this._shiftsList = shiftsList;
        }
    }

    /**
    * @description Method to save shifts
    **/
    handleSubmitTimesheet() {
        this.isLoading = true;
        let shiftsList = new Array();
        this._shiftsList.forEach(item => {
            item.shiftsList.forEach((shift, index) => {
                shiftsList.push(shift);
            });
        });
        updateShifts({
            shiftJSON : JSON.stringify(shiftsList)
        }).then(result => {
            // show success message
            this.dispatchEvent(
                new ShowToastEvent({
                    "message" : 'Timesheet has been updated successfully',
                    "variant" : 'success'
                }),
            );            
        })
        .catch(error => {
            console.log(error);
            this.error = error;            
        })
        .finally(() => {
            this.isLoading = false;
        });
            
    }

    /**
    * @description Method to check if shits exists
    **/ 
    get hasShiftExists() {
        return this._shiftsList.length > 0;
    }

    /**
    * @description Method to check if shits exists
    **/ 
    get isDesktop() {
        return this._formFactor == 'Large';
    }

    /**
    * @description Method to check if shits exists
    **/ 
    get isMediumOrSmallDevice() {
        return (this._formFactor == 'Medium' || this._formFactor == 'Small');
    }

}