import { LightningElement, api } from 'lwc';

export default class DataTablePicklistEditor extends LightningElement {
    _value = null;
    @api
    get value() {
        return this._value;
    }

    set value(val) {
        this._value = val;
    }

    @api
    options;

    @api
    get validity() {
        return (
            this.template.querySelector('lightning-combobox[data-id="combo-input"]').validity
        );
    }

    @api
    showHelpMessageIfInvalid() {
        this.template.querySelector('lightning-combobox[data-id="combo-input"]');
    }

    @api
    focus() {
        this.template.querySelector('lightning-combobox[data-id="combo-input"]').focus();
    }

    handleChange(e) {
        e.stopPropagation();

        this._value = e.detail.value;

        this.dispatchEvent(
            new CustomEvent("change", {
                bubbles: true,
                composed: true,
                detail: {
                    value: this._value
                }
            })
        );
    }
}