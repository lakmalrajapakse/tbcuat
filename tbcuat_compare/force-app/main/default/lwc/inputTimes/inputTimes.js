import { LightningElement, api, track } from 'lwc';
import { debug } from 'c/debug';

export default class InputTimes extends LightningElement {
    //The supported input parsing formats
    _PARSE_TIME_FORMATS = ['h:m a', 'H:m', 'HH:mm', 'hmm', 'Hmm'];
    //The output parsed time format
    _DISPLAY_TIME_FORMAT = 'HH:mm';
    _TZ_DATE_FORMAT = 'DD-MM-YYYY';
    _TZ_24_HR_TIME_FORMAT = 'HH:mm';
    _TZ_12_HR_TIME_FORMAT = 'hh:mm a'
    

    /**
     * User inputted start/end time values
     */
    @track startTime;
    @track endTime;
    @track shiftDate = 'N/A';

    @api startTimeTemplate;
    @api endTimeTemplate;
    @api siteTimezone;
    tzStartTime;
    tzEndTime;

    //Unique ID (e.g. Record ID)
    @api uId;
    
    //Disable input for start time
    @api startDisabled = false;
    
    //Disable input for end time
    @api endDisabled = false;

    @track isReadOnly = false;
    checkDisabledState(){
        this.isReadOnly =  (this.startDisabled == true && this.endDisabled == true);
    }
    
    //Make this component required
    @api required = false;
    
    //Start time cannot be the same as end time
    @api blockSameTimes = false;

    //If set to true, on click of component, we will populate times
    //from tempalte times
    @api populateOnBlur = false;

    /**
     * This is the template start Date/Time
     */
    @track _startTimeValue;
    @api
    get startTimeValue() {
        return this._startTimeValue;
    }
    set startTimeValue(value) {
        this.setAttribute('startTimeValue', value);
        this._startTimeValue = value;
        this.setTimes('start');
    }

    /**
     * This is the template end Date/Time
     */
        
    @track _endTimeValue;
    @api
    get endTimeValue() {
        return this._endTimeValue;
    }
    set endTimeValue(value) {
        this.setAttribute('endTimeValue', value);
        this._endTimeValue = value;
        this.setTimes('end');
    }

    @track componentRendered = false;
    connectedCallback(){
        this.componentRendered = true;
        this.checkDisabledState();
        console.log('this.startTimeValue: ',this.startTimeValue);
        console.log('this.endTimeValue: ',this.endTimeValue);
        
        if(this.startTimeValue || this.endTimeValue){
            this.setTimes();
        }

        //If we do not have "Populate on Blur" option set to true, 
        //auto-populate fields when rendered
        if(!this.populateOnBlur && (!this.startTimeValue || !this.endTimeValue)){
            debug('No Times');
        }        
    }

    

    /**
     * When called, this function will set the
     * times in the fields. If timeType is empty, 
     * we will set both fields, otherwise, we will set 
     * the field according to the parameter in time type
     * 
     * TODO: Issue With Read Only Hous - non UTC
     * @param {*} timeType - can be start/end or empty
     */
    setTimes(timeType){
        if(!this.componentRendered){
            return;
        }
        this.checkDisabledState();

        if(this.isReadOnly){
            //If the input is disabled, show a print of the times
            if(this.startTimeValue){
            this.tzStartTime = moment.tz(this.startTimeValue, this.siteTimezone);
            this.shiftDate = this.tzStartTime.format(this._TZ_DATE_FORMAT);
            this.startTime = this.tzStartTime.format(this._TZ_12_HR_TIME_FORMAT);
            }else{
                this.shiftDate = 'N/A';
                this.startTime = 'N/A';
            }  
            if(this.endTimeValue){
                //this.endTime = moment.utc(this.endTimeValue).format('HH:mm');
                this.tzEndTime = moment.tz(this.endTimeValue, this.siteTimezone);
                this.endTime = this.tzEndTime.format(this._TZ_12_HR_TIME_FORMAT);
            }else{
                this.endTime = 'N/A';
            }    
        }else{
            //Else, if time is not disabled, calculate appropriately
            if(this.startTimeValue && (!timeType || timeType == 'start') )
                this.startTime = this.parseTimeFromString(this.startTimeValue, true);
            if(this.endTimeValue && (!timeType || timeType == 'end'))
                this.endTime = this.parseTimeFromString(this.endTimeValue, true);
        }        
        
        this.validateTimeFields();
    }

    @api
    setAutoTimes(timeType){
        console.log('set autotimes inputtimes');
        //If we have the actual times, do not pre-populate
        //from template times, but use the actual times instead.
        if(this.startTimeValue && this.endTimeValue){
            return;
        }

        if(this.startTimeTemplate && (!timeType || timeType == 'start') )
            this.startTime = this.parseTimeFromString(this.startTimeTemplate, true);
        if(this.endTimeTemplate && (!timeType || timeType == 'end'))
            this.endTime = this.parseTimeFromString(this.endTimeTemplate, true);
        
        this.validateTimeFields();
    }

    /**
     * Gets the input value and wirtes it to the 
     * corresponding tracking varaible
     * 
     * @param {*} event - this is on change event
     */
    handleFieldChange(event){
        console.log('handle field change inputtimes');
        let apiFieldValue = event.detail.value;
        let fieldType = event.target.dataset.fieldtype; 
        
        if(fieldType == 'start'){
            this.startTime = apiFieldValue;
        }else{
            this.endTime = apiFieldValue;			
        }
    }


    /**
     * 1. Converts SF DT Field Value YYYY-MM-DDTHH:MM:SS.000+TZ
     * to String (using _DISPLAY_FORMAT as template) HH:mm if the 
     * isDT param == true
     * 
     * 2. Converts time input text (from list of _PARSE_TIME_FORMATS)
     * to String (using _DISPLAY_FORMAT as template) if isDT param == false
     * 
     * If parsing fails, returns empty string
     * 
     * @param {*} strTime   - String to be converted into Time
     * @param {*} isDT      - Boolean to mark if we convert SF DateTime string
     */
    parseTimeFromString(strTime, isDT, customFormat){
        let parsedTime;
        if(!strTime || strTime === undefined || strTime == null)
            return '';

        let isSuccess = false;
        if(isDT){
            //Attempt to parse Salesforce DT Format
            parsedTime = moment.tz(strTime, this.siteTimezone);
            if(parsedTime.isValid()){
                isSuccess = true;
            }
        }else{
            //Attempt to parse TIME only from String
            parsedTime =  moment(strTime, this._PARSE_TIME_FORMATS);
            if(parsedTime.isValid()){
                isSuccess = true;
            }
            
        }

        //Couldn't Parse - return empty string
        if(!isSuccess){
            return '';
        }

        //Custom format defined
        if(customFormat)
            return parsedTime.format(customFormat);

        return parsedTime.format(this._TZ_12_HR_TIME_FORMAT);
    }

    _FIRST_CLICK = true;
    handleOnClick(){
        console.log('handle onclick inputtimes');
        if(this.populateOnBlur && this._FIRST_CLICK){
            this.setAutoTimes();
        }
        this._FIRST_CLICK = false;
    }

    /**
     * Handles Field Blur Event
     * - Validates fields. On error, prints error
     */
    _FIRST_BLUR = true;
    @api
    handleBlur() {
        console.log('handle blur inputtimes');
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

    /**
     * Validates the component fields
     */
    @track hasError = false;
    @track errorMessage = '';
    validateTimeFields() {
        this.hasError = false;
        this.errorMessage = '';
        //Make sure we have parsed the string times
        this.startTime = this.parseTimeFromString(this.startTime, false);
        this.endTime = this.parseTimeFromString(this.endTime, false);

        //Validate Required Fields
        if(this.required && (this.startTime == '' || this.endTime == '')){
            this.hasError = true;
            if(this.startTime == '' && this.endTime == ''){
                this.errorMessage = 'Start and End times are required';
            }else if(this.startTime == ''){
                this.errorMessage = 'Start Time is required';
            }else if(this.endTime == ''){
                this.errorMessage = 'End Time is required';
            }
            return false;
        }

        if((this.startTime == '' && this.endTime != '')){
            this.hasError = true;
            this.errorMessage = 'Please input Start Time';
            return false;
        }
        if((this.startTime != '' && this.endTime == '')){
            this.hasError = true;
            this.errorMessage = 'Please input End Time';
            return false;
        }

        //Check if Start and End Times are the same
        if(this.blockSameTimes && (this.startTime == this.endTime && !this.hasError)){
            this.hasError = true;
            this.errorMessage = 'Start and End time cannot be the same';
            return false;
        }

        if (!this.isValidTime(this.startTime) || !this.isValidTime(this.endTime)) {
            this.hasError = true;
            this.errorMessage = 'Invalid time format, use am/pm';
        }

        return true;
    }

    isValidTime(time) {
        const timeRegex = /^([01]\d|2[0-3]):([0-5]\d)\s*(?:[APMapm]{2})?$/;
        return timeRegex.test(time);
    }

    /**
     * Takes entered start/end times and uses
     * the tempalte date/time values to create new
     * date/time values to be returned to parent component
     */
    convertTimesToDateTimes(){
        debug('st: ', this.startTime);
        debug('et: ', this.endTime);
        /**
         * 00032485 - Added a check to verify
         * if the field value is empty, if so, return 
         * null value. This check wasn't present and as such
         * it was returning by default Today Date at 00:00 for 
         * both start and end times when the front end fields were cleared 
         * 
         * Reported issue: User clicks on fields, then 
         * clears it and still gets a value when it should be null
         */
        if((!this.startTime || this.startTime === "") || (!this.endTime || this.endTime === "")){
            debug('Returning Empty');
            return {
                actualStartDT: null,
                actualEndDT: null,
            }
        }
        let actualStartHour = this.parseTimeFromString(this.startTime, false, 'HH'); 
        let actualStartMinutes = this.parseTimeFromString(this.startTime, false, 'mm'); 
        let actualEndHours = this.parseTimeFromString(this.endTime, false, 'HH'); 
        let actualEndMinutes = this.parseTimeFromString(this.endTime, false, 'mm');  

        //If the value times are populated, use them as a tempalte, otherwise use the template times
        let templateStartTime = this.startTimeValue ?  new Date(this.startTimeValue) : new Date(this.startTimeTemplate);

        const scheduledStart = moment.tz(templateStartTime, this.siteTimezone);

        // Build an actual start on the scheduled start date
        let actualStart = moment.tz(templateStartTime, this.siteTimezone);
        actualStart.hour(actualStartHour);
        actualStart.minute(actualStartMinutes);
        actualStart.second(0);

        // Need to consider the actual start time on several dates (day of shift, day before and
        // day after) and select the one closest to the scheduled start
        const actualStartDayBefore = moment.tz(actualStart, this.siteTimezone).subtract(1, 'days');
        const actualStartDayAfter = moment.tz(actualStart, this.siteTimezone).add(1, 'days');

        // Select the day before when it is closer to the scheduled start
        if (Math.abs(actualStartDayBefore.diff(scheduledStart)) < Math.abs(actualStart.diff(scheduledStart))) {
            actualStart = actualStartDayBefore;
        }

        // Select the day after when it is closer to the scheduled start
        if (Math.abs(actualStartDayAfter.diff(scheduledStart)) < Math.abs(actualStart.diff(scheduledStart))) {
            actualStart = actualStartDayAfter;
        }

        // Create the actual end on the same date of the selected actual start
        const actualEnd = moment.tz(actualStart, this.siteTimezone);
        actualEnd.hour(actualEndHours);
        actualEnd.minute(actualEndMinutes);
        actualEnd.second(0);

        // Move the actual end date to the next day if it is set before the actual start
        if (actualStart.isAfter(actualEnd)) {
            actualEnd.add(1, 'days');
        }
        return {
            actualStartDT: actualStart,
            actualEndDT: actualEnd,
        }
    }

    /**
     * 00032485 - Added validation for null
     * values through moment.isValid().
     * 
     * Reported issue: User clicks on fields, then 
     * clears it and still gets a value when it should be null
     */
    reportToParent(){
        let {actualStartDT, actualEndDT} = this.convertTimesToDateTimes();
        // convert from site timezone to utc so times can be stored in salesforce's db
        let startDt = actualStartDT.clone().utc();
        let endDt = actualEndDT.clone().utc();
        // clone the moment.tz obj so do not lose timezone
        
        let results = {
            uId: this.uId,
            value: {
                startDT: startDt.isValid() ? startDt.format() : null,
                endDT: endDt.isValid() ? endDt.format() : null
            }
        };

        const changeEvent = new CustomEvent('fieldchange',
            {
                detail: results
            });
        this.dispatchEvent(changeEvent);
    }
    
    getLocalTimeZone(){
        return (Intl?.DateTimeFormat()?.resolvedOptions()?.timeZone ? Intl?.DateTimeFormat()?.resolvedOptions()?.timeZone : 'Europe/London');
    }

    getLocalTime(d){
        let dDate = new Date(d);
        return dDate.toLocaleTimeString(navigator.language, {timeZone: this.USER_LOCAL_TIMEZONE, hour: '2-digit', minute:'2-digit'});
    }

    /**
     * Sets error class if bad field value
     */
    get getFormControlClass(){
        return this.hasError ? 'slds-form-element__control slds-has-error' : 'slds-form-element__control';
    }
}