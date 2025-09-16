import { LightningElement, api } from 'lwc';

export default class InputTimeAndHours extends LightningElement {
    @api record;
    @api type;
    showTimeInput = true;
    // This is just a wrapper for the other two components so that they share updates

    /**
    * @description Constructor
    **/
    constructor() {
        super();
        this.type = 'billable';
    }

    @api
    triggerAutoTimes() {
        const inputTimesCmp = this.template.querySelector('c-input-times');
        if (inputTimesCmp) {
            inputTimesCmp.setAutoTimes();
            inputTimesCmp.handleBlur();
        } else {
            console.error('inputTimes component not found');
        }

        /*const inputHoursCmp = this.template.querySelector('c-input-hours');
        if (inputHoursCmp) {
            inputHoursCmp.setAutoHours();
            inputHoursCmp.handleBlur();
        } else {
            console.error('inputHours component not found');
        }*/
    }


    handleTimesChange(event){
        console.log('handletimes change inputtimeandhours');
        let writeToStartFieldName = event.currentTarget.dataset.writeToStart;
        let writeToEndFieldName = event.currentTarget.dataset.writeToEnd;

        let shiftId = event.detail.uId;
        let apiStartValue = event.detail.value.startDT;
        let apiEndValue = event.detail.value.endDT;

        let newValues = {};
        newValues[writeToStartFieldName] = apiStartValue;
        newValues[writeToEndFieldName] = apiEndValue;
        this.record = Object.assign({}, this.record, newValues);

        let newEvent = new CustomEvent('fieldchange', {detail:event.detail});
        this.dispatchEvent(newEvent);
    }

    /**
    * @description Method to show billable fields
    **/
    get isBillable() {
        return this.type == 'billable';
    }

    /**
    * @description Method to show billable fields
    **/
    get isActual() {
        return this.type == 'actual';
    }
}