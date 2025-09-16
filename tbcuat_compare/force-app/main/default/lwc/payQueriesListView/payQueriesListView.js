import { LightningElement, api } from "lwc";
import { handleTransactionError } from "c/utils";
import getPayQueries from "@salesforce/apex/PayQueriesListViewController.getPayQueries";
import PayQueriesListViewNew from "c/payQueriesListViewNew";

export default class PayQueriesListView extends LightningElement {
    _recordId;
    _gettingPayQueries = false;

    _data = [];
    _columns = [
        { label: "Name", fieldName: "name" , initialWidth: 100},
        { label: "Type", fieldName: "type", initialWidth: 150 },        
        { label: "Status", fieldName: "status", initialWidth: 150 },
        { label: "Payslip Date", fieldName: "paySlipDate", initialWidth: 100},
        { label: "Escalate to Payroll", fieldName: "escalateToPayroll", type: "boolean", initialWidth: 100, cellAttributes: { alignment: 'center' }},
        { label: "Description of your Query", fieldName: "description", wrapText: true },
        { label: "Comments", fieldName: "comments", wrapText: true}
    ];

    @api
    set recordId(value) {
        this._recordId = value;
        this.reload();
    }
    get recordId() {
        return this._recordId;
    }

    get hasData() {
        return this._data.length > 0;
    }

    get isLoading() {
        return this._gettingPayQueries;
    }

    async reload() {
        try {
            if (!this.recordId) return;

            this._gettingPayQueries = true;
            this._data = await getPayQueries({
                contactId: this.recordId
            });
        } catch (ex) {
            handleTransactionError("Load error", ex);
        } finally {
            this._gettingPayQueries = false;
        }
    }

    async handleRefreshClick() {
        await this.reload();
    }

    async handleNewClick() {
        const result = await PayQueriesListViewNew.open({
            size: "small",
            contactId: this.recordId
        });

        if (result) {
            await this.reload();
        }
    }
}