import { LightningElement, api } from 'lwc';

export default class DataTablePicklist extends LightningElement {
    _options = [];
    _value = null;

    @api
    get value() {
        return this._value;
    }

    set value(val) {
        this._value = val;
    }
    
    @api
    get options() {
        return this._options;
    }

    set options(val) {
        this._options = [...val];
    }

    get displayValue() {
        if (!this._options) {
            return this.value;
        }

        const option = this._options.find(x => x.value == this.value);
        return option ? option.label : this.value;
    }
}