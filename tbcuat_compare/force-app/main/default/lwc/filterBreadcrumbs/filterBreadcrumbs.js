/**
 * @description       : 
 * @author            : James Ridge
 * @group             : 
 * @last modified on  : 01-29-2021
 * @last modified by  : James Ridge
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   11-03-2020   James Ridge   Initial Version
**/
import { LightningElement, api, track } from 'lwc';
import { debug } from 'c/debug';

export default class FilterBreadcrumbs extends LightningElement {
    _value;
    @api
    set value(val){
        this._value = val;
        this.updateFilter();
    }
    get value(){
        return this._value;
    }
    @api hideDeleteAction = false;

    @track filterBreadcrumbs = null;
    _labels = {
        NO_FILTER: 'No Filter Applied'
    }

    connectedCallback(){    

    }

    /**
     * Called on change of api var
     */
    updateFilter(){
        /**
         * Handle filter as JSON string or JS Object
         */
        if (typeof this.value === 'string') {
            //Value is JSON string
            try{    
                debug('Value is String, trying to parse', this.value);
                this.filterBreadcrumbs = JSON.parse(this.value); 
            }catch(err){
                this.filterComponentValue = null;
                debug('Error Parsing filter JSON string', err.message);
            }
        }else{
            //Value is an object
            this.filterBreadcrumbs = this.value;
        }
    }

    /**
     * Check if we have an applied filter
     * 
     * - We need to verify that there are filter groups and filter conditions
     */
    get hasFilter(){
        if(!this.filterBreadcrumbs || !this.filterBreadcrumbs.groups) 
            return false;

        
        let hasFilterConditions = false;
        for(let i = 0; i < this.filterBreadcrumbs.groups.length; i++){
            //Check if the current group has conditions, if we do, then 
            if(this.filterBreadcrumbs.groups[i].conditions && this.filterBreadcrumbs.groups[i].conditions.length > 0){
                hasFilterConditions = true;
                break;
            }
        }
        
        return hasFilterConditions;
    }

    deleteCondition(event){
        let groupIndex = event.currentTarget.dataset.groupIndex;
        let conditionIndex = event.currentTarget.dataset.groupConditionIndex;
        this.reportConditionDeleteToParent(groupIndex, conditionIndex);
    }

    reportConditionDeleteToParent(groupIndex, conditionIndex){
        const deleteEvent = new CustomEvent('conditiondelete',
            {
                detail: {
                    groupIndex: groupIndex,
                    conditionIndex: conditionIndex
                }
            });
            
        this.dispatchEvent(deleteEvent);
    }
}