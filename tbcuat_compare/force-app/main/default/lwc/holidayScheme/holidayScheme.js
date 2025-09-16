import { LightningElement, api, wire, track } from 'lwc';
import currentUserId from '@salesforce/user/Id';
import getHolidayScheme from '@salesforce/apex/InpayController.getHolidayScheme';

export default class HolidayScheme extends LightningElement {
    @api recordId;
    @api objectApiName;

    _holidayBalance;
    _daysAwaitingApproval;

    /**
    * @description Constructor
    **/
    constructor() {
        super();
        this._holidayBalance = 0.00;
        this._daysAwaitingApproval = 0.00;
    }

    /**
    * @description Connected Callback Method
    **/
    connectedCallback() {
        if (this.objectApiName === 'User') {
            this.recordId = currentUserId;
        }
    }

    /**
    * @description Wired method to fetch the user information
    **/ 
    @wire(getHolidayScheme, { recordId : '$recordId'}) 
    contractorPayslipUrl({ error, data }) {
        if (data) {
            let rolledOverDays = 0.00;
            let accuredDays = 0.00;
            let takenDays = 0.00;
            let daysAwaitingApproval = 0.00;
            if (data.hasOwnProperty('holidayScheme') && data.hasOwnProperty('hasIntimeExternalId')) {
                if (data.hasIntimeExternalId) {
                    let holidaySchemeData = JSON.parse(data.holidayScheme);
                    if (!holidaySchemeData.hasOwnProperty('result')) {
                        holidaySchemeData.forEach(item =>{
                            if (item.EndDate == null || new Date() < item.EndDate) {
                                rolledOverDays += item.RolledOverDays;
                                accuredDays += item.AccruedYTD;
                                takenDays += item.TakenYTD;
                            }
                        });
                        this._holidayBalance = ((rolledOverDays + accuredDays) - takenDays);
                    }
                }
            }
            if (data.hasOwnProperty('holidayAwaitingApproval')) {
                let holidaysAwaitingApprovalData = data.holidayAwaitingApproval;
                if (holidaysAwaitingApprovalData) {
                    holidaysAwaitingApprovalData.forEach(item =>{
                        if (item.daysClaimed) {
                            this._daysAwaitingApproval += parseFloat(item.daysClaimed);
                        }
                    });
                }
            }
        } else if (error) {
            this.error = error;
        }
        if (this.template.querySelector('lightning-spinner')) {
            this.template.querySelector('lightning-spinner').classList.add('slds-hide');
        }
    }
}