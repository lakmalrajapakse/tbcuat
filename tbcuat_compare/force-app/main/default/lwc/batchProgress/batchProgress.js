import { LightningElement, api, track } from "lwc";

import { ProcessingCompleteEvent } from "./events.js";

import getBatchProgress from "@salesforce/apex/BatchProgressController.getBatchProgress";

export default class batchProgress extends LightningElement {
    @api set batchId(value) {
        this._batchId = value;

        if (value) this.refreshBatchDetails(value);
    }
    get batchId() {
        return this._batchId;
    }
    _batchId;

    jobItemsProcessed = 0;
    totalJobItems = 0;
    numberOfErrors = 0;
    status = "Not Started";
    extendedStatus = '';

    message = "";

    async refreshBatchDetails(batchId) {
        const timestamp = Date.now();
        const batchDetail = await getBatchProgress({ batchId, timestamp });

        this.jobItemsProcessed = batchDetail.JobItemsProcessed;
        this.totalJobItems = batchDetail.TotalJobItems;
        this.numberOfErrors = batchDetail.NumberOfErrors;
        this.status = batchDetail.Status;
        this.extendedStatus = batchDetail.ExtendedStatus;

        this.message = `${this.jobItemsProcessed} of ${this.totalJobItems} batches processed.`;

        console.log(batchDetail);

        if (this.finished) this.dispatchEvent(new ProcessingCompleteEvent());
        else {
            setTimeout(() => {
                this.refreshBatchDetails(this.batchId);
            }, 5000);
        }
    }

    get started() {
        return !this.status === "Not Started";
    }

    get finished() {
        return this.totalJobItems != 0 && this.jobItemsProcessed == this.totalJobItems;
    }

    get progress() {
        return this.started ? 0 : (this.jobItemsProcessed / this.totalJobItems || 0) * 100;
    }

    get variant() {
        return this.numberOfErrors ? "warning" : "base-autocomplete";
    }

    get message() {
        return `${this.jobItemsProcessed} of ${this.totalJobItems} batches processed.`;;
    }

    get hasErrors() {
        return this.numberOfErrors > 0;
    }
}