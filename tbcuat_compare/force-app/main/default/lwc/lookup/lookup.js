/**
 * @description       : 
 * @author            : James Ridge
 * @group             : 
 * @last modified on  : 02-17-2022
 * @last modified by  : Mohammad Ramees
**/
import { LightningElement, api, track, wire } from 'lwc'
import { showToast } from 'c/toasts';
import { debug } from 'c/debug';
import { handleException } from 'c/exceptions';

import getOneRecordById from '@salesforce/apex/SIM_LookupAuraService.getOneRecordById'
import getRecent from '@salesforce/apex/SIM_LookupAuraService.getRecent'
import getRecords from '@salesforce/apex/SIM_LookupAuraService.getRecords'

const ARROW_UP = 'ArrowUp'
const ARROW_DOWN = 'ArrowDown'
const ENTER = 'Enter'
const ESCAPE = 'Escape'
const ACTIONABLE_KEYS = [ ARROW_UP, ARROW_DOWN, ENTER, ESCAPE ]

export default class Lookup extends LightningElement {
    @track isLoading = false;
    @track inputValue = '';
    @track records = [];
    @track focused = false;
    @track selected = '';
    @track record;
    @track error;
    @track activeId = '';

    @track _value;
    @api
    get value () { return this._value }
    set value (val) {
        this._value = val
        if (val) {
            this.requestOneById();
        } else {
            // console.log('value set requestRecent');
            //Is it really necessary for us to request recents when the value cahnges?
            //this.requestRecent();
        }
    }


    @track _sobjectName;
    @api
    get sobjectName () { return this._sobjectName }
    set sobjectName (sOname) {
        let hasChanged = this._sobjectName != sOname;

        this._sobjectName = sOname
        this.records = [];

        /**
         * If the object has changed, add a delay before
         * re-querying for recents. This is because we need wait
         * for the title and subtitle params to also get updated, otherwise, 
         * if the object changed, we are potentially going to query based on the 
         * old object's field values
         */
        if(sOname){
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            let delayRecentsRequest = setTimeout(() => {
                if(hasChanged === true && this._sobjectName){
                    this.requestRecent();
                }
            }, 300)
        }        
    }


    @api iconName
    @api name

    @api hideLabel = false;
    @api placeholder = 'Search...';
    @api fieldLabel = 'Search';
    @api title = 'Name';
    @api subtitle = 'Id';
    @api readOnly = false;
    @api required = false;
    @api messageWhenInputError = 'This field is required.';

    @api checkValidity () {
        return !this.required || (this.value && this.value.length > 14)
    }

    @api reportValidity () {
        const isValid = this.checkValidity()
        this.error = isValid ? {} : { message: this.messageWhenInputError }
        return isValid
    }

    connectedCallback() {
        if (this.value) {
            this.requestOneById()
        } else {
            // console.log('connected callback changed requestRecent');
            //maybe not worth it getting recents when the component is insterted?
            //this.requestRecent()
        }
    }

    // get isReadOnly () { return this.readOnly || this.record }
    get isReadOnly () { return this.readOnly }
    get showListbox () { return this.focused && this.records.length > 0 && !this.record }
    get showClear () { return !this.readOnly && (this.record || (!this.record && this.inputValue.length > 0)) }
    get hasError () { return this.error ? this.error.message : '' }
    get recordIds () { return this.records.map(r => r.Id) }

    get containerClasses () {
        const classes = [ 'slds-combobox_container' ]

        if (this.record) {
            classes.push('slds-has-selection')
        }

        return classes.join(' ')
    }

    get inputClasses () {
        const classes = [
        'slds-input',
        'slds-combobox__input' ]

        if (this.record) {
            classes.push('slds-combobox__input-value')
        }

        return classes.join(' ')
    }

    get comboboxClasses () {
        const classes = [
        'slds-combobox',
        'slds-dropdown-trigger',
        'slds-dropdown-trigger_click' ]

        if (this.showListbox) {
            classes.push('slds-is-open')
        }
        if (this.hasError) {
            classes.push('slds-has-error')
        }

        return classes.join(' ')
    }

    onKeyup (event) {
        if (this.readOnly) return
        this.inputValue = event.target.value
        this.error = null

        const keyAction = {
            ArrowUp: () => { this.cycleActive(false) },
            ArrowDown: () => { this.cycleActive(true) },
            Enter: () => { this.selectItem() },
            Escape: () => { this.clearSelection() }
        }

        if (ACTIONABLE_KEYS.includes(event.code)) {
            keyAction[event.code]()

        } else {
            if (this.inputValue.length > 2) {
                this.debounceSearch()
            } else if (this.inputValue.length === 0) {
                this.records = [];
                this.requestRecent();
            } else {
                this.error = {
                    message: 'Minimum 2 characters'
                }
            }
        }
    }

    handleSelected (event) {
        this.selected = event.detail
        this.record = this.records.find(record => record.Id === this.selected)
        this.inputValue = this.record[this.title]
        this.fireSelected()
    }

    search() {
        const searcher = this.getSearcher()
        this.error = null
        this.isLoading = true;
        if(!searcher.searchTerm || searcher.searchTerm.length == 0){
            this.records = [];
            return;
        }
        console.log('getRecords callout');
        getRecords({
            searcherJSON: JSON.stringify(searcher)
        }).then(results => {
            let response = JSON.parse(results);
            if (response.success) {
                const newData = response.responseObject;
                this.records = newData.flat().sort((a, b) => this.sortAlpha(a, b));
            } else {
                this.error = {
                    message: response.message
                }
            }
        }).catch(err => {
            handleException(this, err, true);
        }).finally(fin =>{
            this.isLoading = false;
        });
    }

    debounceSearch () {
        window.clearTimeout(this.delaySearch)
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delaySearch = setTimeout(() => {
            this.search()
        }, 300)
    }

    requestOneById() {
        const searcher = this.getSearcher()
        this.error = null;
        this.isLoading = true;
        console.log('getOneRecordById callout');
        getOneRecordById({ 
            recordId: this.value,
            searcherJSON: JSON.stringify(searcher) 
        }).then(results => {
            let response = JSON.parse(results);
            if (response.success) {
                const records = response.responseObject;
                this.records = records
                this.record = records[0]
                this.selected = this.record.Id
                this.inputValue = this.record[this.title]
            } else {
                this.error = {
                    message: response.message
                }
            }
        }).catch(err => {
            handleException(this, err, true);
        }).finally(fin =>{
            this.isLoading = false;
        });
    }

    requestRecent() {
        const searcher = this.getSearcher();
        this.error = null;
        this.records = [];   

        if(!searcher.objectName){
            return;
        }

        this.isLoading = true;
        getRecent({ 
            searcherJSON: JSON.stringify(searcher)
        }).then(results => {
            let response = JSON.parse(results);

            if (response.success) {
                this.records = response.responseObject;
            } else {
                this.error = {
                    message: response.message
                }
            }
        }).catch(err => {
            handleException(this, err, true);
        }).finally(fin =>{
            this.isLoading = false;
        });
    }

    clearSelection () {
        this.selected = ''
        this.record = null
        this.inputValue = ''
        this.error = null

        this.requestRecent()
        this.fireSelected()
    }

    fireSelected () {
        let returnObj = {
            value: this.selected ? this.record.Id : null,
            label: this.selected ? this.record[this.title] : null
        }
        //this.selected
        const selected = new CustomEvent('selected', {
            detail: returnObj
        })
        this.dispatchEvent(selected)
    }

    cycleActive (forwards) {
        const currentIndex = this.recordIds.indexOf(this.activeId)
        if (currentIndex === -1 || currentIndex === this.records.length) {
            this.activeId = this.recordIds[0]
        } else if (!forwards && currentIndex === 0) {
            this.activeId = this.recordIds[this.recordIds.length - 1]
        } else if (forwards) {
            this.activeId = this.recordIds[currentIndex + 1]
        } else {
            this.activeId = this.recordIds[currentIndex - 1]
        }
    }

    selectItem () {
        if (!this.records || this.records.length === 0) return

        const listbox = this.template.querySelector('c-listbox')
        listbox.selectItem()
    }

    setFocus (event) {
        this.focused = event.type === 'focus'
        if (event.type === 'blur') {
            this.reportValidity()
        }
    }

    getSearcher () {
        let fielSet = [];
        fielSet.push('Id');
        if(this.title){
            fielSet.push(this.title);
        }
        if(this.subtitle){
            fielSet.push(this.subtitle);
        }
        return {
            searchTerm: this.inputValue,
            objectName: this.sobjectName,
            fields: fielSet
        }
    }

    sortAlpha (a, b) {
        const aName = a[this.title].toLowerCase()
        const bName = b[this.title].toLowerCase()

        if (aName < bName) return -1
        if (aName > bName) return 1

        return 0
    }
}