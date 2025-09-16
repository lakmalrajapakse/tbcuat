/**
 * @description       : 
 * @author            : James Ridge
 * @group             : 
 * @last modified on  : 11-18-2022
 * @last modified by  : James Ridge
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   11-25-2020   James Ridge   Initial Version
**/
import { LightningElement, track, api } from 'lwc';

import getSOQLFilter from '@salesforce/apex/SIM_FilterComponent.getSOQLFilter';

import { showToast } from 'c/toasts';
import { debug } from 'c/debug';
import { handleException } from 'c/exceptions';

export default class FilterComponent extends LightningElement {
    _EVENT_LOADING_STATE_CHANGE = 'sim_loading_state_change';
    _EVENT_FILTER_BUILT = 'event_filter_built';
    //API name of the context object
    //Can never be null
    @api targetObject = null;
    //This is the pre-fill value - usually an object {crossGroupOperator:'', groups:[]}
    //Set to null, we will not pre-fill the component
    @api value = null;
    //Optional parameter that allows us to filter the SIM Filter Conditions 
    //metadata by the matching Group field on the metadata entry
    @api filterGroup = "1";
    
    
    @track groups = [];
    
    /**
     * Cross-Group operators
     */
    @track crossGroupOperators = [{value:'and', label:'All Groups'}, {value:'or', label:'Any Group'}];
    @track crossGroupOperator;

    connectedCallback(){
        debug('FilterComponent value', this.value);
        if(this.value && this.value.crossGroupOperator){
            //Pre-populate available operators 
            //Note - we need to "clone" the value as to avoid setting trap on proxy
            this.crossGroupOperator = JSON.parse(JSON.stringify(this.value.crossGroupOperator));
        }else{
            //Set the first option from available operators
            this.crossGroupOperator = this.crossGroupOperators[0].value;
        }

        this.renderGroups();
    }

    renderGroups(){
        if(this.value && this.value.groups){
            //Pre-populate available groups from value
            this.groups = [];
            //Note - we need to "clone" the value as to avoid setting trap on proxy
            this.groups = JSON.parse(JSON.stringify(this.value.groups));
        }else{
            //Empty groups
            this.groups = [];
        }
        
        debug('Rerender Groups', this.groups);
    }


    /**
     * Global API function allowing the request of 
     * filtered records for this.targetObject with applied filters
     */
    @api getFilter(){
        this.loadSOQLFilter();
    }
    /**
     * Global API finction allowing the deletion of
     * a condition, requested by parent component
     * @param {*} groupIndex 
     * @param {*} conditionIndex 
     */
    @api deleteGroupCondition(groupIndex, conditionIndex){
        this.groups[groupIndex].conditions.splice(conditionIndex, 1);

        this.updateLocalGroups();
        this.reportToParent();
        this.loadSOQLFilter()
    }

    /**
     * Manages setting the loading state for this component
     * and any children components of the type FilterGroup
     * @param {*} loadingState 
     */
    @track isLoading;
    reportLoadingState(loadingState){
        this.isLoading = loadingState;
        //Sets loading state to child filter groups    
        this.template.querySelectorAll('c-filter-group').forEach(element => {  
            element.setLoading(loadingState);
        });
        debug('reportLoadingState ', loadingState);
        /**
         * Report to parent loading state
         */
        const changeEvent = new CustomEvent('loadingstatechange',
            {
                detail: {
                    isLoading: loadingState,
                }
            });
        this.dispatchEvent(changeEvent);

    }

    /**
     * Sends to the server the applied filters and expects
     * a response containing the ids of the records for the targetObject
     */
    loadSOQLFilter(){
        this.reportLoadingState(true);
        debug('this.targetObject', this.targetObject);
        debug('this.crossGroupOperator', this.crossGroupOperator);
        debug('this.groups', this.groups);

        console.log('this.groups j ' + JSON.stringify(this.groups));
        getSOQLFilter({
            targetObject: this.targetObject,
            crossGroupOperator: this.crossGroupOperator,
            groupsJSON: JSON.stringify(this.groups)
        }).then(results => {            
            let response = JSON.parse(results);
            console.log('***getSOQLFilter Response', response);
            
            //Create a global bubbling event to notify parent components that processing has completed
            //Parent component manages results
            this.dispatchEvent(new CustomEvent(this._EVENT_FILTER_BUILT, {bubbles: true, composed: true, detail: {
                soqlFilter: response.message,
                groups: this.groups,
                crossGroupOperator: this.crossGroupOperator
            }}));

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
     * Manages changes to fields
     * 
     * @param {*} event 
     */
    handleFieldChange(event){
        let apiFieldType = event.target.dataset.type;
        let apiFieldValue = event.detail.value;
        debug('apiFieldType', apiFieldType)
        debug('apiFieldValue', apiFieldValue)
        if(apiFieldType == 'select-group-relationship'){
            this.crossGroupOperator = apiFieldValue;
            //Save to local storage
            localStorage.setItem(this._LOCAL_GROUP_REL, apiFieldValue);
        }

        this.reportToParent();
    }

    /**
     * Manages the change of cross-group operators
     *  
     * @param {*} event 
     */
    handleGroupChange(event){
        this.groups[event.detail.index]['crossConditionOperator'] = event.detail.crossConditionOperator;
        this.groups[event.detail.index]['conditions'] = event.detail.conditions;

        this.updateLocalGroups();
        this.reportToParent();
    }

    

    /**
     * Manages the deletion of groups. Saves states
     * locally to client machine
     * 
     * @param {*} event 
     */
    handleDeleteGroup(event){
        this.groups.splice(event.detail.index, 1);

        this.updateLocalGroups();
        this.reportToParent();
    }

    /**
     * Manages the re-ordering of groups
     * 
     * TODO: ISSUE - Groups stopped re-ordering for some reason..?
     * @param {*} event 
     */
    handleReorderGroup(event){
        let toPosition = event.detail.direction == 'up' ? (event.detail.index - 1) : (event.detail.index + 1);
        this.groups.splice(toPosition, 0, this.groups.splice(event.detail.index, 1)[0]);

        this.updateLocalGroups();
        this.renderGroups();
        this.reportToParent();
    }

    /**
     * Reports to parent the filter setup
     */
    reportToParent(){
        const changeEvent = new CustomEvent('filterchange',
            {
                detail: {
                    groups: this.groups,
                    crossGroupOperator: this.crossGroupOperator,
                }
            });
        this.dispatchEvent(changeEvent);
    }
    
    /**
     * Group Controls - adding a new group
     */
    @track groupMaxId = 0;
    addGroup(){
        this.groups.push(
            {
                id: this.groupMaxId,
                crossConditionOperator: null,
                conditions: null,
            }
        );
        this.groupMaxId++;
    }

    

    /**
     * Updates local storage to maintain a stateful
     */
    updateLocalGroups(){
        localStorage.setItem(this._LOCAL_GROUPS, JSON.stringify(this.groups));
    }

     /**
     * Show the relationship selector only if we have 
     * more than one group
     */
    get showRelationshipSelector(){
        return this.groups.length > 1;
    }
}