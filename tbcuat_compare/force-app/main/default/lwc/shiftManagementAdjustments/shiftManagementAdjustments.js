import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { handleTransactionError, showSuccessToast } from "c/utils";
import LightningConfirm from "lightning/confirm";
import getTimesheets from "@salesforce/apex/SMAdjustmentsController.getTimesheets";
import reverse from "@salesforce/apex/SMAdjustmentsController.reverse";
import ShiftManagementAdjustmentSelectorModal from "c/shiftManagementAdjustmentSelectorModal";
import ShiftManagementReversalProgressModal from "c/shiftManagementReversalProgressModal"

export default class ShiftManagementAdjustments extends NavigationMixin(LightningElement) {
    _isLoadingTimesheets = false;
    _isQueueingReversals;
    _filters = {};
    _selectedRows = [];

    data = [];

    @api get filters() {
        return this._filters;
    }
    set filters(value) {
        this._filters = value;
        this.reload();
    }

    @api parentLoading;

    get hasData() {
        return this.data.length > 0;
    }

    get isLoading() {
        return this.parentLoading || this._isLoadingTimesheets || this._isQueueingReversals;
    }

    get buttonsDisabled() {
        return this._selectedRows.length < 1;
    }

    get invoiceDisabled() {
        return this.data.length < 1;
    }

    get columns() {
        const columns = [];

        columns.push(
            { label: "Period Date", fieldName: "PeriodDate", type: "date" },
            {
                label: "Timesheet",
                fieldName: "Url",
                type: "url",
                typeAttributes: { label: { fieldName: "Name" }, target: "_blank" }
            },
            { label: "Site Name", fieldName: "SiteName", type: "text" },
            { label: "Worker Name", fieldName: "WorkerName", type: "text" },
            { label: "PO Number", fieldName: "PONumber", type: "text" },
            { label: "Total Hours", fieldName: "TotalHours", type: "number" },
            { label: "Total Pay", fieldName: "Pay", type: "currency" },
            { label: "Total Charge", fieldName: "Charge", type: "currency" },
            { label: "InTime Invoice", fieldName: "InTimeInvoiceNo", type: "text" },
            { label: "Type", fieldName: "Type", type: "text" }
            // REVERSAL REF???
        );

        return columns;
    }

    async reload() {
        try {
            this._isLoadingTimesheets = true;
            const data = JSON.parse(await getTimesheets({ requestJson: JSON.stringify(this.filters) }));

            await this.regenerateTimesheetData(data.Summaries);
        } catch (error) {
            handleTransactionError("Timesheet load error", error);
        } finally {
            this._isLoadingTimesheets = false;
        }
    }

    async regenerateTimesheetData(records) {
        if (!records) {
            return;
        }

        const allSummaries = records.map((x) => {
            return {
                Id: x.Id,
                Name: x.Name,
                Pay: x.Pay,
                Charge: x.Charge,
                Url: x.Url,
                PONumber: x.PONumber,
                WorkerName: x.WorkerName,
                JobRole: x.JobRole,
                Type: x.Type,
                PeriodDate: x.PeriodDate,
                SiteName: x.SiteName,
                TotalHours: x.TotalHours,
                InTimeInvoiceNo: x.InTimeInvoiceNo
            };
        });

        for (let summary of allSummaries) {
            summary.Url = await this.generateUrlForRecordId(summary.Id);
        }

        this.data = allSummaries;
    }

    async generateUrlForRecordId(recordId) {
        return await this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: { recordId: recordId, actionName: "view" }
        });
    }

    handleRowSelection(event) {
        this._selectedRows = [...event.detail.selectedRows];
    }

    async handleReversalAdjustmentClick() {
        const result = await LightningConfirm.open({
            message: "This will reverse the selected timecards, do you wish to continue?",
            theme: "info",
            variant: "header",
            label: "Confirm reversal",
            theme: "warning"
        });

        if (!result) {
            return;
        }

        try {
            this._isQueueingReversals = true;
            const jobId = await reverse({
                requestJson: JSON.stringify(
                    this._selectedRows.map((x) => {
                        return {
                            timesheet: {
                                timesheetId: x.Id,
                                lines: []
                            }
                        };
                    })
                )
            });

            showSuccessToast("Success", "Reversal job queued successfully");

            const result = await ShiftManagementReversalProgressModal.open({
                jobId: jobId,
                size: "small",
                description: "Modal window to show reversal progress"
            });
        } catch (error) {
            handleTransactionError("Reversal job queue error", error);
        } finally {
            this._isQueueingReversals = false;
        }
    }
    async handleAdjustmentClick() {
        const result = await ShiftManagementAdjustmentSelectorModal.open({
            recordIds: this._selectedRows.map((x) => x.Id),
            step: 1,
            size: "medium",
            description: "Modal window to adjust timesheets"
        });
    }

    async handleInvoiceAdjustmentClick() {
        const result = await ShiftManagementAdjustmentSelectorModal.open({
            recordIds: this.data.map((x) => x.Id),
            step: 0,
            size: "medium",
            description: "Modal window to adjust timesheets"
        });
    }
}