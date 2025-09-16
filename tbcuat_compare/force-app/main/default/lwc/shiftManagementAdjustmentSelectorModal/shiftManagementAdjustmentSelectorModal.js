import LightningModal from "lightning/modal";
import { api, wire } from "lwc";

import { handleTransactionError, showSuccessToast } from "c/utils";
import adjust from "@salesforce/apex/SMAdjustmentsController.adjust";

export default class ShiftManagementAdjustmentSelectorModal extends LightningModal {
    @api step = 0;
    _recordIds = [];
    _isQueueingAdjustmentJob = false;
    adjustmentType;
    adjustmentRequests = [];
    adjustmentFilters = {};
    invoice;
    jobId;

    @api get recordIds() {
        return this._recordIds;
    }
    set recordIds(value) {
        this._recordIds = value;
        this.adjustmentFilters.timesheetIds = this._recordIds;
    }

    get isInvoiceSelectionStep() {
        return this.step == 0;
    }

    get isTypeSelectorStep() {
        return this.step == 1;
    }

    get isAdjustmentSelectionStep() {
        return this.step == 2;
    }

    get isAdjustmentProgressStep() {
        return this.step == 3;
    }

    get nextDisabled() {
        if (this.isInvoiceSelectionStep) {
            return this.invoice == null;
        } else if (this.isTypeSelectorStep) {
            return this.adjustmentType == null;
        } else if (this.isAdjustmentSelectionStep) {
            return this.adjustmentRequests.length < 1;
        } else if (this._isQueueingAdjustmentJob) {
            return true;
        }

        return false;
    }

    get nextHidden() {
        return this.isAdjustmentProgressStep;
    }

    get cancelLabel() {
        return this.isAdjustmentProgressStep ? "Close" : "Cancel";
    }

    handleCancelClick() {
        this.close();
    }

    async handleNextClick() {
        if (this.isAdjustmentSelectionStep) {
            this._isQueueingAdjustmentJob = true;
            try {
                const jobId = await adjust({
                    requestJson: JSON.stringify(this.adjustmentRequests)
                });
                
                this.jobId = jobId;

                showSuccessToast("Success", "Adjustment job queued successfully");

                this.step += 1;
            } catch (error) {
                handleTransactionError("Adjustment job queue error", error);
            } finally {
                this._isQueueingAdjustmentJob = false;
            }
        } else {
            this.step += 1;
        }
    }

    handleTypeSelectionChange(event) {
        this.adjustmentType = event.detail;
    }

    handleAdjustmentRequestsChange(event) {
        this.adjustmentRequests = event.detail;
    }

    handleInvoiceSelectionChange(event) {
        this.invoice = event.detail;
        this.adjustmentFilters.invoiceNo = this.invoice;
    }
}