import { LightningElement, api, wire, track } from 'lwc';

export default class TimeEntry extends LightningElement {
    @api shiftDate;
    @api teamName;
    @api locationName;
    @api shift;
    @api formFactor;

    @track _shifts;
    _showTimeEntry;

    /**
    * @description Connected Callback Method
    **/
    connectedCallback() {
        this._shifts = new Array();
        this.initTimeEntry();
    }

    /**
    * @description Method to refresh
    **/
    @api
    refresh(shiftDate) {
        this.shiftDate = shiftDate;
        this.initTimeEntry();
    }

    /**
    * @description Method to set time entry
    **/
    initTimeEntry() {
        this._showTimeEntry = false;
        let dateParts = this.shiftDate.date.split("/");
        let dateFromShift = new Date(
            parseInt(dateParts[2], 10),
            parseInt(dateParts[1], 10) - 1,
            parseInt(dateParts[0], 10)
        );                

        this.shift.shiftsList.forEach(item => {
            let shift = JSON.parse(JSON.stringify(item));
            
            let actualStartDate = new Date(shift.sirenum__Actual_Start_Time__c.replace('.000+0000',''));
            let scheduledStartDate = new Date(shift.sirenum__Scheduled_Start_Time__c.replace('.000+0000',''));            
            
            if (scheduledStartDate.getDay() == dateFromShift.getDay()) {
                let endDate = new Date(shift.sirenum__Actual_End_Time__c.replace('.000+0000',''));
                
                let scheduledEndDate = new Date(shift.sirenum__Scheduled_End_Time__c.replace('.000+0000',''));                                
                let hasApprovedTime =  (shift.sirenum__Billable_Start_Time__c != null && shift.sirenum__Billable_End_Time__c != null);
                let approvedStartDate = (hasApprovedTime) ? new Date(shift.sirenum__Billable_Start_Time__c.replace('.000+0000','')) : null;
                let approvedEndDate = (hasApprovedTime) ? new Date(shift.sirenum__Billable_End_Time__c.replace('.000+0000','')) : null;                

                this._shifts.push(
                    {
                        shift : shift,
                        startTime: ("0" + actualStartDate.getHours()).slice(-2)   + ":" + ("0" + actualStartDate.getMinutes()).slice(-2),
                        scheduledStartTime: ("0" + scheduledStartDate.getHours()).slice(-2)   + ":" + ("0" + scheduledStartDate.getMinutes()).slice(-2),
                        endTime: ("0" + endDate.getHours()).slice(-2)   + ":" + ("0" + endDate.getMinutes()).slice(-2),
                        scheduledEndTime: ("0" + scheduledEndDate.getHours()).slice(-2)   + ":" + ("0" + scheduledEndDate.getMinutes()).slice(-2),
                        hours: this.calculateHour(shift),
                        hasApprovedTime: hasApprovedTime,
                        approvedStartTime: hasApprovedTime ? ("0" + approvedStartDate.getHours()).slice(-2)   + ":" + ("0" + approvedStartDate.getMinutes()).slice(-2) : null,
                        approvedEndTime: hasApprovedTime ? ("0" + approvedEndDate.getHours()).slice(-2)   + ":" + ("0" + approvedEndDate.getMinutes()).slice(-2) : null,
                        disable:  shift.Client_Approved__c || shift.sirenum__Allow_pay__c || shift.sirenum__Allow_pay__c
                    }
                );
                
                this._showTimeEntry = true;                            
            }  

        });
    }

    getShift(id) {
        let shift = this._shifts.find(item => item.shift.Id == id);
        if (shift) {
            return shift;
        }
        return null;
    }

    setShift(rec) {
        this._shifts = [...this._shifts];
        for (let i = 0; i < this._shifts.length; i++) {
            if (this._shifts[i].shift.Id == rec.shift.Id) {
                this._shifts[i] = rec;
            }
        };
    }

    /**
    * @description Method to handle start hour change
    **/
    handleStartTimeChange(event) {
        let startTime = event.target.value;
        let shiftId = event.currentTarget.dataset.shift;             

        let rec = JSON.parse(JSON.stringify(this.getShift(shiftId)));        
        let startDate = (rec.shift.sirenum__Actual_Start_Time__c instanceof Date) ? rec.shift.sirenum__Actual_Start_Time__c : new Date(Date.parse(rec.shift.sirenum__Actual_Start_Time__c.replace('.000+0000','')));
        let start = startTime.split(":");
        startDate.setHours(parseInt(start[0]));
        startDate.setMinutes(parseInt(start[1]));
        rec.shift.sirenum__Actual_Start_Time__c = startDate;
        rec.startTime = startTime;  
        
        rec.hours = this.calculateHour(rec.shift);
        
        this.setShift(rec);
        
        this.fireShiftChangeEvent(rec.shift);        
    }

    /**
    * @description Method to handle start time minute change
    **/
    handleEndTimeChange(event) {
        let endTime = event.target.value;
        let shiftId = event.currentTarget.dataset.shift;                

        let rec = JSON.parse(JSON.stringify(this.getShift(shiftId)));        
            
        let endDate = (rec.shift.sirenum__Actual_End_Time__c instanceof Date) ? rec.shift.sirenum__Actual_End_Time__c : new Date(Date.parse(rec.shift.sirenum__Actual_End_Time__c.replace('.000+0000','')));
        let startDate = (rec.shift.sirenum__Actual_Start_Time__c instanceof Date) ? rec.shift.sirenum__Actual_Start_Time__c : new Date(Date.parse(rec.shift.sirenum__Actual_Start_Time__c.replace('.000+0000','')));
        
        let end = endTime.split(":");
        endDate.setHours(parseInt(end[0]));
        endDate.setMinutes(parseInt(end[1]));        

        if (endDate < startDate) {
            endDate.setDate(endDate.getDate() + 1);            
        }

        rec.shift.sirenum__Actual_End_Time__c = endDate;
        rec.endTime = endTime;
        rec.hours = this.calculateHour(rec.shift);

        this.setShift(rec);

        this.fireShiftChangeEvent(rec.shift);        
    }

    /**
    * @description Method to handle end time minute change
    **/
    handleHourChange(event) {        
        let hours = event.target.value;
        let shiftId = event.currentTarget.dataset.shift;        

        let rec = JSON.parse(JSON.stringify(this.getShift(shiftId)));        

        let startDate = (rec.shift.sirenum__Actual_Start_Time__c instanceof Date) ? rec.shift.sirenum__Actual_Start_Time__c : new Date(Date.parse(rec.shift.sirenum__Actual_Start_Time__c.replace('.000+0000','')));
        
        let hoursTime =  hours * 1000 * 60 * 60; 
        let endTimeEpoch = startDate.getTime() + hoursTime;
        let calculatedEndDate = new Date(endTimeEpoch);

        rec.shift.sirenum__Actual_End_Time__c = calculatedEndDate; 
        rec.endTime = ("0" + calculatedEndDate.getHours()).slice(-2)   + ":" + ("0" + calculatedEndDate.getMinutes()).slice(-2);
        rec.hours = hours;

        this.setShift(rec);
        
        this.fireShiftChangeEvent(rec.shift);
    }

    /**
    * @description Method to calculate hour
    **/
    calculateHour(shift) {           
        let endDate = (shift.sirenum__Actual_End_Time__c instanceof Date) ? shift.sirenum__Actual_End_Time__c : new Date(Date.parse(shift.sirenum__Actual_End_Time__c.replace('.000+0000','')));        
        let startDate = (shift.sirenum__Actual_Start_Time__c instanceof Date) ? shift.sirenum__Actual_Start_Time__c : new Date(Date.parse(shift.sirenum__Actual_Start_Time__c.replace('.000+0000','')));
        
        let diff = endDate.getTime() - startDate.getTime();
        
        return (diff / 1000 / 60 / 60).toFixed(2);        
    }

    /**
    * @description Method to fire shift event
    **/
    fireShiftChangeEvent(shift) {
        this.dispatchEvent(new CustomEvent('shiftchange',{
            'detail': {
                'shift': shift
            }
        }));
    }    

    /**
    * @description Method to check if shits exists
    **/ 
    get isDesktop() {
        return this.formFactor == 'Large';
    }

    /**
    * @description Method to check if shits exists
    **/ 
    get isMediumOrSmallDevice() {
        return (this.formFactor == 'Medium' || this.formFactor == 'Small');
    }
}