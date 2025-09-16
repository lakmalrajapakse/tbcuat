import { LightningElement, api, track, wire } from 'lwc';

export default class ShiftManagementAdjustmentFilters extends LightningElement {
    // PUBLIC ATTRIBUTES
    @api data;

    // PRIVATE ATTRIBUTES  
    _workersList;
    _poNumbersList;
    _payElementsList;

    /**
    * @description Constructor
    **/
    constructor() {
        super();
        this._workersList = new Array();
        this._poNumbersList = new Array();
        this._payElementsList = new Array();
    }

    /**
    * @description Connected Callback Method
    **/
    connectedCallback() {
        this.setWorkersList();
        this.setPONumbersList();
        this.setIntimePayElementsList();
    }

    /**
    * @description Method to set workers list
    **/
    setWorkersList() {
        if (this.data) {
            this._workersList.push({
                    'label' : '-Choose--',
                    'value' : ''
                });
            this.data.forEach(timesheet => {
                if (timesheet.WorkerName) {
                    this._workersList.push({
                        'label' : timesheet.WorkerName,
                        'value' : timesheet.WorkerName
                    });
                }
            });
            this._workersList = [...new Map(this._workersList.map(item => [item.value, item])).values()];
            this._workersList.sort((a, b) => {
                if (a.label < b.label) return -1;
                if (a.label > b.label) return 1;
                return 0;
            });
        }
    }

    /**
    * @description Method to set PO numbers list
    **/
    setPONumbersList() {
        if (this.data) {
            this._poNumbersList.push({
                    'label' : '-Choose--',
                    'value' : ''
                });
            this.data.forEach(timesheet => {
                if (timesheet.PONumber) {
                    this._workersList.push({
                        'label' : timesheet.PONumber,
                        'value' : timesheet.PONumber
                    });
                }
            });
            this._poNumbersList = [...new Map(this._poNumbersList.map(item => [item.value, item])).values()];
            this._poNumbersList.sort((a, b) => {
                if (a.label < b.label) return -1;
                if (a.label > b.label) return 1;
                return 0;
            });
        }
    }

    /**
    * @description Method to set pay elements list
    **/
    setIntimePayElementsList() {
        if (this.data) {
            this._payElementsList.push({
                    'label' : '-Choose--',
                    'value' : ''
                });
            this.data.forEach(timesheet => {
                if (timesheet.InTimePayElement) {
                    this._payElementsList.push({
                        'label' : timesheet.InTimePayElement,
                        'value' : timesheet.InTimePayElement
                    });
                }
            });
            this._payElementsList = [...new Map(this._payElementsList.map(item => [item.value, item])).values()];
            this._payElementsList.sort((a, b) => {
                if (a.label < b.label) return -1;
                if (a.label > b.label) return 1;
                return 0;
            });
        }
    }

     /**
    * @description Method to reset the values
    **/
    handleReset() {
        this.template.querySelector('[data-id="worker"]').value = '';
        this.template.querySelector('[data-id="poNumber"]').value = '';
        this.template.querySelector('[data-id="payElement"]').value = '';
        this.template.querySelector('[data-id="startTotal"]').value = '';
        this.template.querySelector('[data-id="endTotal"]').value = '';
        this.dispatchEvent(new CustomEvent('timesheetsearch',{ 
            detail: {
                'worker' : this.template.querySelector('[data-id="worker"]').value,
                'poNumber' : this.template.querySelector('[data-id="poNumber"]').value,
                'payElement' : this.template.querySelector('[data-id="payElement"]').value,
                'startTotal' : this.template.querySelector('[data-id="startTotal"]').value,
                'endTotal' : this.template.querySelector('[data-id="endTotal"]').value
            }
        }));
    }

    /**
    * @description Method to handle search
    **/
    handleSearch() {
        this.dispatchEvent(new CustomEvent('timesheetsearch',{ 
            detail: {
                'worker' : this.template.querySelector('[data-id="worker"]').value,
                'poNumber' : this.template.querySelector('[data-id="poNumber"]').value,
                'payElement' : this.template.querySelector('[data-id="payElement"]').value,
                'startTotal' : this.template.querySelector('[data-id="startTotal"]').value,
                'endTotal' : this.template.querySelector('[data-id="endTotal"]').value
            }
        }));
    }
}