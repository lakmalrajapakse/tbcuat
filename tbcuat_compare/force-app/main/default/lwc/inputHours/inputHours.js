import { LightningElement, track, api } from 'lwc';
import { debug } from 'c/debug';

export default class InputHours extends LightningElement {
    _MAX_HRS = 24;
    _MIN_HRS = 0;

    //The supported input parsing formats
    _PARSE_TIME_FORMATS = ['H:m', 'HH:mm', 'hmm', 'Hmm'];
    //The output parsed time format
    _DISPLAY_TIME_FORMAT = 'HH:mm';

    //Unique ID (e.g. Record ID)
    @api uId;
    
    //Disable input 
	@api disabled = false;
    
    //Make this component required
    @api required = false;

    @api siteTimezone;

    shiftLength = null;

    @api startTimeTemplate;
    @api endTimeTemplate;
    //If set to true, on click of component, we will populate times
    //from tempalte times
    @api populateOnBlur = false;
    @api displayAsDecimal = false;

    /**
     * This is the template start Date/Time
     */
    @api
    get startTimeValue() {
        return this._startTimeValue;
    }
    set startTimeValue(value) {
        this.setAttribute('startTimeValue', value);
        this._startTimeValue = value;
        this.setHours();
    }

    /**
     * This is the template end Date/Time
     */
    @api
    get endTimeValue() {
        return this._endTimeValue;
    }
    set endTimeValue(value) {
        this.setAttribute('endTimeValue', value);
        this._endTimeValue = value;
        this.setHours();
    }

    @track componentRendered = false;
    connectedCallback(){
        this.componentRendered = true;
        
        if(this.startTimeValue && this.endTimeValue){
            this.setHours();
        }     
	}

    @track shiftDate;
    @track startTime;
    @track endTime;
    setHours(){
        if(!this.componentRendered){
            return;
        }

        if(this.disabled){
            //If the input is disabled, show a print of the times
            if (this.startTimeValue && this.endTimeValue) {
                let startTime = moment(this.startTimeValue);
                let endTime = moment(this.endTimeValue);
                if (this.displayAsDecimal) {
                    let duration = moment.duration(endTime.diff(startTime));
                    let decimalHours = duration.asHours();
                    this.shiftLength = decimalHours;
                    this.shiftLength = (Math.round(this.shiftLength * 100) / 100).toFixed(2);
                }
            }
            if(this.startTimeValue){
                this.shiftDate = moment.utc(this.startTimeValue).format('YYYY/MM/DD');
                this.startTime = moment.utc(this.startTimeValue).format('HH:mm');
            }else{
                this.shiftDate = 'N/A';
                this.startTime = 'N/A';
            }  
            if(this.endTimeValue){
                this.endTime = moment.utc(this.endTimeValue).format('HH:mm');
            }else{
                this.endTime = 'N/A';
            }    
        }else{
            let startTime = moment(this.startTimeValue);
            let endTime = moment(this.endTimeValue);


            let duration = moment.duration(endTime.diff(startTime));
            let decimalHours = duration.asHours();
            this.shiftLength = this.displayAsDecimal ? decimalHours.toFixed(2) : moment.utc(decimalHours*3600*1000).format('HH:mm');
        }   

    }

    @api
    setAutoHours(){
        if(!this.componentRendered){
            return;
        }
        let startTime = moment(this.startTimeTemplate);
        let endTime = moment(this.endTimeTemplate);


        let duration = moment.duration(endTime.diff(startTime));
        let decimalHours = duration.asHours();
        debug('decimalHours (auto)', decimalHours);
        this.shiftLength = this.displayAsDecimal ? decimalHours.toFixed(2) : moment.utc(decimalHours*3600*1000).format('HH:mm');
        //this.validateTimeFields();
    }

    /**
     * Gets the input value and wirtes it to the 
     * corresponding tracking varaible
     * 
     * @param {*} event - this is on change event
     */
    handleFieldChange(event){
        let apiFieldValue = event.detail.value;
        let fieldType = event.target.dataset.fieldtype; 
        
        debug('apiFieldValue', apiFieldValue);
        debug('fieldType', fieldType);
        if(fieldType == 'hours'){
            this.shiftLength = apiFieldValue;
        }
    }

    /**
     * Validates the component fields
     */
    @track hasError = false;
    @track errorMessage = '';
    validateTimeFields(){
        this.hasError = false;
        this.errorMessage = '';
        
        this.shiftLength = this.displayAsDecimal ? ((Math.round(this.shiftLength * 100) / 100) || 0).toFixed(2) : this.parseHoursFromString(this.shiftLength);

        if(this.required && this.shiftLength == null){
            this.hasError = true;
            this.errorMessage = 'This field is required';
            //Do not report back as this is a required field
            return false;
        }

        //If the field is emptied, report to parent
        //to null the start/end time fields
        if(this.shiftLength == null){
            this.reportToParent(null, null);
            return false;
        }        

        if(this.shiftLength === '00:00' || this.shiftLength === '0.00'){
            this.shiftLength = null;
            this.hasError = true;
            this.errorMessage = 'Hours cannot be zero or over 24';
            return false;
        }

        return true;
    }

    parseHoursFromString(strTime){
        debug('Validating 1', strTime);
        let parsedTime;
        if((!strTime || strTime == '' || strTime == null || strTime == undefined)){
            return null;
        }

        //Attempt to parse TIME only from String
        parsedTime =  moment(strTime, this._PARSE_TIME_FORMATS);
        if(parsedTime.isValid()){
            return parsedTime.format(this._DISPLAY_TIME_FORMAT);
        }

        return null;
    }

    _FIRST_CLICK= true;
    handleOnClick(){
        if(this.populateOnBlur && this._FIRST_CLICK && !this.shiftLength){
            this.setAutoHours();
        }
        this._FIRST_CLICK = false;
    }

    /**
     * Handles Field Blur Event
     * - Validates fields. On error, prints error
     */
    @api
    handleBlur() {
        try{
            let isComponentValid = this.validateTimeFields();
            
            if(isComponentValid){
                this.reportToParent();
            }
        }catch(err){
            this.hasError = true;
            this.errorMessage = err;
            console.log('Error Validationg', err);
        }
    }

    reportToParent(){
        //We have good hours, now convert to decimal
        let decimalShiftLength = this.displayAsDecimal ? this.shiftLength : moment.duration(this.shiftLength).asHours();
        debug('reportToParent (hours)', this.shiftLength);
        debug('reportToParent (decimal)', decimalShiftLength);

        //If the value times are populated, use them as a tempalte, otherwise use the template times
        let startTime = this.startTimeValue ?  this.startTimeValue : this.startTimeTemplate;

        let endTime = moment(startTime).add(decimalShiftLength, 'hours').utc().format();    
        startTime = moment(startTime).utc().format();
        let results = {
                uId: this.uId,
                value: {
                    startDT: startTime,
                    endDT: endTime
                    }
                };

        console.log('Hours have changed', results);

		const changeEvent = new CustomEvent('fieldchange',
            {
                detail: results
            });
        this.dispatchEvent(changeEvent);
	}

    /**
     * Sets error class if bad field value
     */
    get getFormControlClass(){
        return this.hasError ? 'slds-form-element__control slds-has-error' : 'slds-form-element__control';
    }
}