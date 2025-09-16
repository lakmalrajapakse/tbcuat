/**
 * @description       : 
 * @author            : James Ridge
 * @group             : 
 * @last modified on  : 02-10-2021
 * @last modified by  : James Ridge
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   01-29-2021   James Ridge   Initial Version
**/
import { LightningElement, api, track } from 'lwc';
import { debug } from 'c/debug';

export default class BreadCrumbPill extends LightningElement {
    @api value;
    @api isFirst;
    @api crossConditionOperator;

    connectedCallback(){
        
    }

    get targetValue(){
        if(!this.value.selectedCriteria){
            return this.value.targetValueLabel;
        }else if(this.value.selectedCriteria.isBooleanMatch){
            return this.value.targetValueLabel && this.value.targetValueLabel !== '' ? (this.value.targetValueLabel == 'true' ? 'Checked' : 'Unchecked') :   'Unchecked';
        }else if(this.value.selectedCriteria.isDateMatch){
            let jsDate = (this.value.targetValueLabel && this.value.targetValueLabel !== '') ? new Date(this.value.targetValueLabel) : null;
            if(!jsDate){
                return 'Empty';
            }
            
            const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
            const month = monthNames[jsDate.getMonth()];
            const day = String(jsDate.getDate()).padStart(2, '0');
            const year = jsDate.getFullYear();

            return (day + ' ' + month   + ' ' + year);
        }else if(this.value.selectedCriteria.isPicklistMatch){
            return this.value.targetValueLabel && this.value.targetValueLabel !== '' ? this.value.targetValueLabel :   'Empty';
        }else if(this.value.selectedCriteria.isTextMatch){
            return this.value.targetValueLabel ? ('"' + this.value.targetValueLabel + '"') :   '""';
        }else if(this.value.selectedCriteria.isLookupMatch){
            return this.value.targetValueLabel && this.value.targetValueLabel !== '' ? this.value.targetValueLabel :   'Empty';
        }
    }
}