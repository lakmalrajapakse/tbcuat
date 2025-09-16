/**
 * @description       : 
 * @author            : James Ridge
 * @group             : 
 * @last modified on  : 01-29-2021
 * @last modified by  : James Ridge
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   11-25-2020   James Ridge   Initial Version
**/
import { LightningElement, track, api } from 'lwc';

import getFilterOptions from '@salesforce/apex/SIM_FilterComponent.getFilterOptions';

import { showToast } from 'c/toasts';
import { debug } from 'c/debug';

export default class FilterGroup extends LightningElement {
    _EVENT_LOADING_STATE_CHANGE = 'sim_loading_state_change';
    
    //And/Or operator
    @api crossGroupOperator;
    //And/Or operator
    @api crossConditionOperator;
    //Array of conditions
    @api filterConditions;
    //API name of the context object
    //Can never be null
    @api targetObject = null;
    //Optional parameter that allows us to filter the SIM Filter Conditions 
    //metadata by the matching Group field on the metadata entry
    @api filterGroup = "1";

    //Current index
    @api index;
    //Identify if first/last group in array
    @api isFirst;
    @api isLast;

    //Hard-coded condition actions
    @track crossConditionOperators = [{value:'and', label:'All Conditions Are Met'}, {value:'or', label:'Any Condition Is Met'}];
    @track _crossConditionOperator;

    //Hard-Coded operators
    @track operators = [{value:'equals', label:'Equals'}, {value:'not_equals', label:'Not Equals'}];

    @track conditions = [];
    @track conditionCriteria = [];
    
    connectedCallback(){
        this.loadFilterOptions();
        
        if(this.crossConditionOperator != null){
            //Pre-load selected filter type with passed value
            this._crossConditionOperator = this.crossConditionOperator;
        }else{
            //Set filter type to default option
            this._crossConditionOperator = this.crossConditionOperators[0].value;
        }

        if(this.filterConditions != null){
            //Pre-load filter conditions with passed array
            this.conditions = JSON.parse(JSON.stringify(this.filterConditions));
        }else{
            //Set conditions to an empty array
            this.conditions = [];
        }
    }

    /**
     * Global API funciton to set the component's
     * loading state from parent component(s)
     * 
     * @param {*} loadingState 
     */
    @api setLoading(loadingState){
        this.isLoading = loadingState;
    }

    /**
     * Manages field state changes
     * 
     * @param {*} event 
     */
    handleFieldChange(event) {
        /**
         * Labels are to be used for breadcrubs
         */
        try{
            let elementId = event.target.dataset.elementId;
            let apiFieldType = event.target.dataset.type;
            let apiFieldValue = event.detail.value;

            if(apiFieldType == 'filter-type'){
                this._crossConditionOperator = apiFieldValue;
            }else if(apiFieldType == 'select-operator'){
                
                this.conditions[elementId]['selectedOperator']  = apiFieldValue;
                let conditionCriteria = this.conditions[elementId]['selectedCriteria'];
           
                //Now extract the operator's Label from the selected criteria
                for(let i = 0; i < conditionCriteria.operators.length; i++){
                    if(conditionCriteria.operators[i].value == apiFieldValue){
                        this.conditions[elementId]['selectedOperatorLabel']  = conditionCriteria.operators[i].label;
                    }                    
                }

                if(apiFieldValue == 'is-null' || apiFieldValue == 'not-null'){
                    this.conditions[elementId]['disableTargetValue'] = true;
                }else{
                    this.conditions[elementId]['disableTargetValue'] = false;
                }
            }else if(apiFieldType == 'select-criteria'){
                try{
                    this.conditions[elementId]['selectedCriteria']  = this.getCriteriaByTargetField(apiFieldValue);
                    let selectedCriteria = this.conditions[elementId]['selectedCriteria'];
                    this.conditions[elementId]['targetFieldLabel'] = selectedCriteria.label;
                    this.conditions[elementId]['targetField'] = selectedCriteria.targetField;
                    
                }catch(err){
                    let jsErr;
                    if (err && err.message)
                        jsErr = 'Javascript Error: ' + err.message;
                    else if (err)
                        jsErr = '' + err;
                    else
                        jsErr = 'Unknown Error';

                    debug('err:', jsErr);
                }
            }else{
                this.conditions[elementId]['targetValue'] = apiFieldValue;
                
                if(event.detail.label)
                    this.conditions[elementId]['targetValueLabel'] = event.detail.label;
                else{
                    this.conditions[elementId]['targetValueLabel'] = apiFieldValue;
                }
            }
            
            this.reportToParent();
        }catch(err){
            //error unmanaged - could be a controller exception or javascript exception
            let unmngErr;
            if (err.body) {
                if (err.body.message)
                    unmngErr = 'Apex Error: ' + err.body.message;
                else
                    unmngErr = 'Unknown Error';

                if (err.body.stackTrace)
                    unmngErr += ' Stack:' + err.body.stackTrace;
            } else {
                if (err && err.message)
                    unmngErr = 'Javascript Error: ' + err.message;
                else if (err)
                    unmngErr = '' + err;
                else
                    unmngErr = 'Unknown Error';
            }
            debug('Unmanaged Error', unmngErr);
            showToast(this, unmngErr, 'error');
        }
    }

    /**
     * Returns criteria by target field. Criteria
     * contain useful metadata information about the 
     * target field
     * 
     * @param {*} targetField 
     */
    getCriteriaByTargetField(targetField){
        for(let i = 0; i < this.conditionCriteria.length; i++){
            if(this.conditionCriteria[i].targetField == targetField){
                return this.conditionCriteria[i];
            }
        }
        return null;
    }


    /**
     * get the conditions criteria
     */
    get getConditionCriteria(){
        let options = [];
        for(let i = 0; i < this.conditionCriteria.length; i++){
            options.push({label: this.conditionCriteria[i].label, value: this.conditionCriteria[i].targetField});
        }
        return options;
    }

    /**
     * Manages loading of condition criteria
     * which contain definitions about filter options, 
     * operators and target fields and their metadata
     */
    loadFilterOptions(){
        this.reportLoadingState(true);

        getFilterOptions({
            targetObject: this.targetObject,
            filterGroup: this.filterGroup
        }).then(results => {            
            let response = JSON.parse(results);
            console.log('***ShiftFilter Response', response);
            if (response.success) {
                this.conditionCriteria = response.responseObject.conditionCriteria;
            } else {
                //error - well managed - other
                debug('Err:', response.message);
                showToast(this, response.message, 'error');
            }

        }).catch(err => {
            //error unmanaged - could be a controller exception or javascript exception
            let unmngErr;
            if (err.body) {
                if (err.body.message)
                    unmngErr = 'Apex Error: ' + err.body.message;
                else
                    unmngErr = 'Unknown Error';

                if (err.body.stackTrace)
                    unmngErr += ' Stack:' + err.body.stackTrace;
            } else {
                if (err && err.message)
                    unmngErr = 'Javascript Error: ' + err.message;
                else if (err)
                    unmngErr = '' + err;
                else
                    unmngErr = 'Unknown Error';
            }
            debug('Unmanaged Error', unmngErr);
            showToast(this, unmngErr, 'error');
        }).finally(fin => {
            this.reportLoadingState(false);
        });
    }

    /**
     * Manages the component's loading state and 
     * notifies parent and grandparent components of 
     * loading state changes
     */
    @track isLoading;
    reportLoadingState(loadingState){
        this.isLoading = loadingState;
        this.dispatchEvent(new CustomEvent(this._EVENT_LOADING_STATE_CHANGE, {bubbles: true, composed: true, detail: { isLoading: loadingState}}));
    }

    /**
     * Adds new condition to a group
     */
    @track conditionMaxId = 0;
    addCondition(){
        let defaultConditionCriteria = this.conditionCriteria[0]
        if(!defaultConditionCriteria){
            showToast(this, 'No pre-defined conditions available', 'warning');
            return;
        }
        
        this.conditions.push(
            {
                id:this.conditionMaxId,
                selectedOperator: defaultConditionCriteria.operators[0].value,
                selectedOperatorLabel: defaultConditionCriteria.operators[0].label,
                selectedCriteria: defaultConditionCriteria,
                targetField: defaultConditionCriteria.targetField,
                targetFieldLabel: defaultConditionCriteria.label,
                targetValue: null,
                targetValueLabel: null
            }
        );
        this.conditionMaxId++;
        this.reportToParent();
    }

    /**
     * Removes a condition from a group
     * @param {*} event 
     */
    removeCondition(event){
        let elementId = event.currentTarget.dataset.elementId;
        this.conditions.splice(elementId, 1);

        this.reportToParent();
    }

    /**
     * Emits an event to the parent to notify of 
     * delete event for the group
     */
    removeGroup(){
        const changeEvent = new CustomEvent('delete',
            {
                detail: {
                    index: this.index,
                }
            });
        this.dispatchEvent(changeEvent);
    }

    /**
     * Emits an event to the parent to notify of
     * reorder event for the group
     * 
     * @param {*} event 
     */
    reorderGroup(event){
        debug('REORDER:' + event.currentTarget.dataset.direction)
        let direction = event.currentTarget.dataset.direction;
        const changeEvent = new CustomEvent('reorder',
            {
                detail: {
                    index: this.index,
                    direction: direction
                }
            });
        this.dispatchEvent(changeEvent);
    }

    /**
     * Emits an event to the parent to notify of
     * field level changes, selections and updates
     */
    reportToParent(){
        const changeEvent = new CustomEvent('groupchange',
            {
                detail: {
                    index: this.index,
                    conditions: this.conditions,
                    crossConditionOperator: this._crossConditionOperator
                }
            });
        this.dispatchEvent(changeEvent);
    }

    /**
     * Visibility Controls
     */
    get hasMultipleGroups(){
        return this.index > 0;
    }
}