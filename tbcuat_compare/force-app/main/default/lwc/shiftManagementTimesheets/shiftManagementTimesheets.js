import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import LightningConfirm from "lightning/confirm";
import { deleteRecord } from "lightning/uiRecordApi";
import { handleTransactionError } from "c/utils";
import ShiftManagementTimesheetsUpload from "c/shiftManagementTimesheetsUpload";
import ShiftManagementTimesheetSummaryEditModal from "c/shiftManagementTimesheetSummaryEditModal";
import ShiftManagementTimesheetSummaryBulkEditModal from "c/shiftManagementTimesheetSummaryBulkEditModal";
import generateTimesheetProof from "@salesforce/apex/SIM_TimeApproval.generateTimesheetProof";
import getJobDetails from "@salesforce/apex/SIM_TimeApproval.getJobDetails";
import updateTimesheetProof from "@salesforce/apex/SIM_TimeApproval.updateTimesheetProof";
import getTimesheets from "@salesforce/apex/SMTimesheetsController.getTimesheets";

export default class ShiftManagementTimesheets extends NavigationMixin(LightningElement) {
    _records = [];
    _selectedRows = [];
    _selectedSummaries = [];
    _selectedLines = [];
    _isDeleting = false;
    _isLoadingTimesheets = false;
    _filters = {};
    data = [];
    totalChargeSum = 0;
    _proofGenerationSubmitted;
    _apexJobId;
    executedPercentage;
    executedIndicator;

    @api isCommunity;

    @api parentLoading;

    @api get filters() {
        return this._filters;
    }
    set filters(value) {
        this._filters = value;
        this.reload();
    }

    get columns() {
        const columns = [];

        columns.push(
            {
                label: "Timesheet",
                fieldName: "Url",
                type: "url",
                typeAttributes: { label: { fieldName: "Name" }, target: "_blank" }
            },
            {
                label: "Worker Name",
                fieldName: "WorkerName",
                type: "text"
            },
            {
                label: "Job Role",
                fieldName: "JobRole",
                type: "text"
            },
            {
                label: "Weekending / Work Date",
                fieldName: "WeekEndingDate",
                type: "date",
                typeAttributes: {
                    day: "numeric",
                    month: "numeric",
                    year: "numeric"
                }
            },
            {
                label: "Total Hours",
                fieldName: "TotalHours",
                type: "decimal"
            }
        );

        if (!this.isCommunity) {
            columns.push({ label: "Total Pay", fieldName: "Pay", type: "currency" });
        }

        columns.push(
            { label: "Total Charge", fieldName: "Charge", type: "currency" },
            { label: "PO Number", fieldName: "PONumber", type: "text" },
            { type: "action", typeAttributes: { rowActions: this.getRowActions } }
        );

        return columns;
    }

    get hasData() {
        return this.data.length > 0;
    }

    get deleteDisabled() {
        return this._selectedRows.length < 1;
    }

    get uploadDisabled() {
        return this._selectedSummaries.length < 1;
    }

    get editDisabled() {
        return this._selectedSummaries.length < 1;
    }

    get generateTimesheetProofDisabled() {
        return this._selectedSummaries.length < 1;
    }

    get isLoading() {
        return this._isDeleting || this.parentLoading || this._isLoadingTimesheets;
    }

    getRowActions(row, doneCallback) {
        const isSummary = row.IsSummary;

        const actions = [{ label: "Edit", iconName: "utility:edit", name: "edit", disabled: !isSummary }];

        doneCallback(actions);
    }

    async handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case "edit":
                await this.openSingleEditWindow(row.Id);
                break;
            default:
                break;
        }
    }

    async openSingleEditWindow(recordId) {
        const result = await ShiftManagementTimesheetSummaryEditModal.open({ size: "small", recordId: recordId });

        if (result.success) {
            this.dispatchEvent(new CustomEvent("timesheetupdated"));
        }
    }

    async handleDeleteClick() {
        const result = await LightningConfirm.open({
            message: "This delete all selected timesheet summaries and lines. Continue?",
            variant: "header",
            label: "Confirm Delete",
            theme: "warning"
        });

        if (!result) return;

        try {
            this._isDeleting = true;

            for (let line of this._selectedLines) {
                await deleteRecord(line.Id);
            }
            for (let summary of this._selectedSummaries) {
                await deleteRecord(summary.Id);
            }

            const timesheetDeletedEvent = new CustomEvent("timesheetdeleted", {
                detail: { shiftId: this.shiftId, breakId: this.breakId }
            });
            this.dispatchEvent(timesheetDeletedEvent);
        } catch (error) {
            handleTransactionError("Delete error", error);
        } finally {
            this._isDeleting = false;
        }
    }

    async handleUploadClick() {
        const result = await ShiftManagementTimesheetsUpload.open({
            recordIds: this._selectedSummaries.map((x) => x.Id),
            size: "small",
            description: "Modal window to upload documentation for timesheets"
        });
        if (result.success) {
            updateTimesheetProof({
                timesheetIds: this._selectedSummaries.map((x) => x.Id)
            })
                .then((result) => {
                    // show success message
                    this.dispatchEvent(
                        new ShowToastEvent({
                            message: "Attachments have been uploaded successfully",
                            variant: "success"
                        })
                    );
                })
                .catch((err) => {
                    console.log("err ", err);
                });
        }
    }

    async handleEditClick() {
        const result = await ShiftManagementTimesheetSummaryBulkEditModal.open({
            recordIds: this._selectedSummaries.map((x) => x.Id),
            size: "small",
            description: "Modal window to bulk edit timesheets"
        });

        if (result.success) {
            this.dispatchEvent(new CustomEvent("timesheetupdated"));
        }
    }

    async reload() {
        try {
            this._isLoadingTimesheets = true;
            const data = JSON.parse(await getTimesheets({ requestJson: JSON.stringify(this.filters) }));

            this._records = data.Summaries;
            await this.regenerateTimesheetData();
        } catch (error) {
            handleTransactionError("Timesheet load error", error);
        } finally {
            this._isLoadingTimesheets = false;
        }
    }

    async regenerateTimesheetData() {
        if (!this._records) {
            return;
        }

        const allTimesheets = this._records
            .flatMap((x) => x.Lines)
            .map((x) => {
                return { ...x };
            });

        const allSummaries = this._records.map((x) => {
            return {
                ...x,
                Url: "",
                WorkerName: x.WorkerName + (x.InTimeExternalId ? " (" + x.InTimeExternalId + ")" : ""),
                WeekEndingDate: new Date(x.WeekEndingDate)
            };
        });

        for (let summary of allSummaries) {
            summary.Url = await this.generateUrlForRecordId(summary.Id);
        }

        // Generate URLs for timesheets
        for (let timesheet of allTimesheets) {
            timesheet.Url = await this.generateUrlForRecordId(timesheet.Id);
        }

        const allUniqueSummaryIds = new Set(allTimesheets.map((x) => x.SummaryId));

        let totalChargeSumInt = 0;

        const data = Array.from(allUniqueSummaryIds).map((x) => {
            const timesheets = allTimesheets.filter((t) => t.SummaryId == x);
            const summary = allSummaries.find((s) => s.Id == x);

            totalChargeSumInt += summary.Charge * 100;

            return {
                Id: x,
                Name: summary.Name,
                Pay: summary.Pay,
                Charge: summary.Charge,
                Url: summary.Url,
                IsSummary: true,
                PONumber: summary.PONumber,
                WorkerName: summary.WorkerName,
                JobRole: summary.JobRole,
                Date: summary.Date,
                TotalHours: summary.TotalHours,
                InTimeExternalId: summary.InTimeExternalId,
                WeekEndingDate: new Date(summary.WeekEndingDate),
                _children: timesheets
            };
        });

        this.totalChargeSum = parseFloat((totalChargeSumInt / 100).toFixed(2));

        this.data = data;
    }

    handleRowSelection(event) {
        this._selectedRows = [...event.detail.selectedRows];
        this._selectedSummaries = this._selectedRows.filter((x) => x.level == 1);
        this._selectedLines = this._selectedRows.filter((x) => x.level == 2);
    }

    async generateUrlForRecordId(recordId) {
        return await this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: { recordId: recordId, actionName: "view" }
        });
    }

    handleGenerateTimesheetProof() {
        generateTimesheetProof({
            timesheetIds: this._selectedSummaries.map((x) => x.Id)
        })
            .then((result) => {
                if (result) {
                    this._apexJobId = result;
                    this.getBatchStatus();
                }
            })
            .catch((err) => {
                console.log("err ", err);
            });
    }

    //get the batch status
    getBatchStatus() {
        this.executedPercentage = 0.0;
        this.executedIndicator = 0;
        getJobDetails({ jobId: this._apexJobId })
            .then((res) => {
                console.log("response => ", res);
                if (res[0]) {
                    this.totalBatch = res[0].TotalJobItems;
                    if (res[0].TotalJobItems == res[0].JobItemsProcessed) {
                        this.isBatchCompleted = true;
                    }
                    this.executedPercentage =
                        res[0].TotalJobItems > 0
                            ? ((res[0].JobItemsProcessed / res[0].TotalJobItems) * 100).toFixed(2)
                            : 0.0;
                    let executedNumber = Number(this.executedPercentage);
                    this.executedIndicator = Math.floor(executedNumber);
                    this.refreshBatchOnInterval(); //enable this if you want to refresh on interval
                }
            })
            .catch((err) => {
                console.log("err ", err);
            });
    }

    refreshBatchOnInterval() {
        this._interval = setInterval(() => {
            if (this.isBatchCompleted) {
                this._apexJobId = "";
                clearInterval(this._interval);
            } else {
                this.getBatchStatus();
            }
        }, 1000); //refersh view every time
    }
}