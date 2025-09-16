import { LightningElement, api } from "lwc";
import getInvoiceEntries from "@salesforce/apex/SMAdjustmentInvoiceController.getInvoiceEntries";

export default class ShiftManagementAdjustmentInvoiceSelector extends LightningElement {
    _isLoadingInvoiceEntries = false;
    _invoiceNoOptions = [];
    _recordIds = [];
    selectedInvoiceNo;

    @api get recordIds() {
        return this._recordIds;
    }
    set recordIds(value) {
        this._recordIds = value;
        this.reload();
    }

    get invoiceNoOptions() {
        return this._invoiceNoOptions;
    }

    get isLoading() {
        return this._isLoadingInvoiceEntries;
    }

    async reload() {
        try {
            this._isLoadingInvoiceEntries = true;
            const data = JSON.parse(
                await getInvoiceEntries({
                    requestJson: JSON.stringify({
                        timesheetIds: this.recordIds
                    })
                })
            );

            this.generateInvoiceNoOptions(data.invoiceEntries);
        } catch (error) {
            handleTransactionError("Timesheet load error", error);
        } finally {
            this._isLoadingInvoiceEntries = false;
        }
    }

    generateInvoiceNoOptions(entries) {
        this._invoiceNoOptions = entries.map(x => {
            return {
                label: x,
                value: x
            }
        })
    }

    handleInvoiceNoChange(event) {
        this.selectedInvoiceNo = event.detail.value;
        this.dispatchEvent(new CustomEvent("selectionchange", { detail: this.selectedInvoiceNo }));
    }
}