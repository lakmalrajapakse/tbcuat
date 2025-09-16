import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { handleTransactionError } from "c/utils";
import getTimesheets from "@salesforce/apex/SMAdjustmentSelectorController.getTimesheets";
import getPayElementOptions from "@salesforce/apex/SMAdjustmentSelectorController.getPayElementOptions";

export default class ShiftManagementAdjustmentSelector extends NavigationMixin(LightningElement) {
    _isLoadingTimesheets = false;
    _filters = {};
    _selectedRows = [];
    _selectedSummaries = [];
    _selectedLines = [];
    _pageSize = "25";
    _pageNumber = 1;
    selectedAttribute;
    bulkPoNumber;
    bulkChargeRate;
    bulkPayRate;
    bulkPayElement;
    inTimePayElementOptions = [];
    data = [];
    _filteredData;

    @api adjustmentType;

    @api get filters() {
        return this._filters;
    }
    set filters(value) {
        this._filters = value;
        this._filteredData = new Array();
        this.reload();
    }

    get columns() {
        const columns = [
            {
                label: "Timesheet",
                fieldName: "Name",
                type: "text"
            },
            {
                label: "Line",
                fieldName: "LineName",
                type: "text"
            },
            { label: "Worker Name", fieldName: "WorkerName", type: "text" },
            { label: "PO Number", fieldName: "PONumber", type: "text", editable: { fieldName: "canEditPoNumber" } },
            {
                label: "Pay Element",
                fieldName: "InTimePayElement",
                type: "picklist",
                editable: { fieldName: "canEditPayElement" },
                typeAttributes: {
                    options: this.inTimePayElementOptions
                }
            },
            { label: "Total Hours", fieldName: "TotalHours", type: "number" },
            {
                label: "Charge Rate",
                fieldName: "ChargeRate",
                type: "currency",
                editable: { fieldName: "canEditChargeRate" }
            },
            { label: "Pay Rate", fieldName: "PayRate", type: "currency", editable: { fieldName: "canEditPayRate" } },
            { label: "Total Charge", fieldName: "Charge", type: "currency" },
            { label: "Total Pay", fieldName: "Pay", type: "currency" }
        ];

        // I can envisage us needing to conditionally change column behaviour here soon, so leaving as a getter.

        return columns;
    }

    get attributeOptions() {
        const options = [
            { label: "PO Number", value: "poNumber" },
            { label: "Pay Element", value: "payElement" }
        ];

        if (this.canEditChargeRate) {
            options.push({ label: "Charge Rate", value: "chargeRate" });
        }
        if (this.canEditPayRate) {
            options.push({ label: "Pay Rate", value: "payRate" });
        }

        return options;
    }

    get pageSizeOptions() {
        return [
            { label: "10", value: "10" },
            { label: "25", value: "25" },
            { label: "50", value: "50" },
            { label: "75", value: "75" },
            { label: "100", value: "100" },
            { label: "150", value: "150" },
            { label: "200", value: "200" }
        ];
    }

    get canEditPayRate() {
        return this.adjustmentType == "pay" || this.adjustmentType == "payCharge";
    }

    get canEditChargeRate() {
        return this.adjustmentType == "charge" || this.adjustmentType == "payCharge";
    }

    get isPoNumberAttribute() {
        return this.selectedAttribute == "poNumber";
    }

    get isChargeRateAttribute() {
        return this.selectedAttribute == "chargeRate";
    }

    get isPayRateAttribute() {
        return this.selectedAttribute == "payRate";
    }

    get isPayElementAttribute() {
        return this.selectedAttribute == "payElement";
    }

    get hasData() {
        return this.data.length > 0;
    }

    get isLoading() {
        return this._isLoadingTimesheets;
    }

    get pageSize() {
        return this._pageSize;
    }

    get pageNumber() {
        return this._pageNumber;
    }

    get pageCount() {
        const pageSize = +this.pageSize;

        return Math.ceil(this.data.length / pageSize);
    }

    get paginatedData() {
        const pageSize = +this.pageSize;

        const start = (this.pageNumber - 1) * pageSize;
        const end = start + pageSize;
        const paginated = this._filteredData.slice(start, end);
        return paginated;
    }

    get draftValuesById() {
        return this.template.querySelector("c-custom-data-table").draftValues.reduce((acc, current, index) => {
            acc[current.Id] = current;
            return acc;
        }, {});
    }

    async reload() {
        try {
            this._isLoadingTimesheets = true;
            const data = JSON.parse(
                await getTimesheets({
                    requestJson: JSON.stringify(this.filters)
                })
            );

            this.inTimePayElementOptions = await getPayElementOptions();

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

        const getDraftValues = (recordId) => {
            const draftValues = this.template.querySelector("c-custom-data-table").draftValues;
            const record = draftValues.find((x) => x.Id == recordId);

            return record ? record : {};
        };

        const calculateSumOfLines = (recordId, fieldName) => {
            const childRecords = this.data.filter((x) => !x.isSummary && x.summaryId == recordId);

            return childRecords.reduce((prev, val, index) => {
                const value = val[fieldName];
                return prev + value;
            }, 0);
        };

        const me = this;

        this.data = records.flatMap((x) => {
            const summaryId = x.Id;

            return [
                {
                    ...x,
                    isSummary: true,
                    canEditPoNumber: true,
                    get Charge() {
                        return calculateSumOfLines(summaryId, "Charge");
                    },
                    get Pay() {
                        return calculateSumOfLines(summaryId, "Pay");
                    }
                },
                ...x.Lines.map((x) => {
                    return {
                        ...x,
                        isSummary: false,
                        Name: null,
                        LineName: x.Name,
                        summaryId: summaryId,
                        canEditChargeRate: me.canEditChargeRate,
                        canEditPayRate: me.canEditPayRate,
                        canEditPayElement: true,
                        get Charge() {
                            const draftValues = getDraftValues(x.Id);
                            const chargeRate = +draftValues.ChargeRate || x.ChargeRate;

                            return chargeRate * x.TotalHours;
                        },
                        get Pay() {
                            const draftValues = getDraftValues(x.Id);
                            const payRate = +draftValues?.PayRate || x.PayRate;

                            return payRate * x.TotalHours;
                        }
                    };
                })
            ];
        });
        this._filteredData = this.data;
    }

    handleTimesheetSearch(event) {
        this._filteredData = this.data;
        // WORKER
        if (event && event.detail && event.worker) {
            this._filteredData = this._filteredData.filter(timesheet => timesheet.WorkerName == event.detail.worker);
        } 

        // PO NUMBER
        if (event && event.detail && event.detail.poNumber) {
            this._filteredData = this._filteredData.filter(timesheet => timesheet.PONumber == event.detail.poNumber);
        } 

        // INTIME PAY ELEMENT
        if (event && event.detail && event.detail.payElement) {
            this._filteredData = this._filteredData.filter(timesheet => timesheet.InTimePayElement == event.detail.payElement);
        } 

        // START TOTAL HOURS
        if (event && event.detail && event.detail.startTotal) {
            this._filteredData = this._filteredData.filter(timesheet => timesheet.TotalHours >= event.detail.startTotal);
        } 

        // END TOTAL HOURS
        if (event && event.detail && event.detail.endTotal) {
            this._filteredData = this._filteredData.filter(timesheet => timesheet.TotalHours <= event.detail.endTotal);
        } 
    }

    handleRowSelection(event) {
        this._selectedRows = event.detail.selectedRows.map((x) => {
            return { ...x };
        });
        this._selectedSummaries = this._selectedRows.filter((x) => x.isSummary);
        this._selectedLines = this._selectedRows.filter((x) => !x.isSummary);
    }

    handlePageSizeChange(event) {
        this._pageSize = event.detail.value;
    }

    handlePageNumberChange(event) {
        this._pageNumber = event.detail.value;
    }

    handleAttributeChange(event) {
        this.selectedAttribute = event.detail.value;
    }

    handleBulkPoNumberChange(event) {
        this.bulkPoNumber = event.detail.value;
    }

    handleBulkChargeRateChange(event) {
        this.bulkChargeRate = event.detail.value;
    }

    handleBulkPayRateChange(event) {
        this.bulkPayRate = event.detail.value;
    }

    handleBulkPayElementChange(event) {
        this.bulkPayElement = event.detail.value;
    }

    handleApplyPoNumberClick() {
        const targetIds = this._selectedSummaries.map((r) => r.Id);

        this.applyValuesToDraft(
            targetIds.map((x) => {
                return {
                    Id: x,
                    PONumber: this.bulkPoNumber
                };
            })
        );
    }

    handleApplyChargeRateClick() {
        this.applyValuesToDraft(
            this._selectedLines.map((x) => {
                return {
                    Id: x.Id,
                    ChargeRate: this.bulkChargeRate
                };
            })
        );
    }

    handleApplyPayRateClick() {
        this.applyValuesToDraft(
            this._selectedLines.map((x) => {
                return {
                    Id: x.Id,
                    PayRate: this.bulkPayRate
                };
            })
        );
    }

    handleApplyPayElementClick() {
        this.applyValuesToDraft(
            this._selectedLines.map((x) => {
                return {
                    Id: x.Id,
                    InTimePayElement: this.bulkPayElement
                };
            })
        );
    }

    handlePreviousPageClick() {
        this._pageNumber--;

        if (this._pageNumber < 1) {
            this._pageNumber = 1;
        }
    }

    handleNextPageClick() {
        this._pageNumber++;

        if (this._pageNumber > this.pageCount) {
            this._pageNumber = this.pageCount;
        }
    }

    publishAdjustmentRequests() {
        const draftValues = this.template.querySelector("c-custom-data-table").draftValues;
        const adjustmentRequestsByTimesheetId = {};
        const dataById = this.data.reduce((acc, current) => {
            acc[current.Id] = current;
            return acc;
        }, {});

        for (let draft of draftValues) {
            const unmodifiedRecord = dataById[draft.Id];
            const summaryId = unmodifiedRecord.isSummary ? unmodifiedRecord.Id : unmodifiedRecord.SummaryId;
            const adjustmentRequest = (adjustmentRequestsByTimesheetId[unmodifiedRecord.SummaryId] ||= {
                timesheet: {
                    timesheetId: summaryId,
                    lines: []
                }
            });

            if (unmodifiedRecord.isSummary && draft["PONumber"]) {
                adjustmentRequest.timesheet.poNumber = draft["PONumber"];
            } else {
                const modifiedRecord = {
                    timesheetLineId: draft.Id
                };

                if (draft["ChargeRate"]) {
                    modifiedRecord.chargeRate = draft["ChargeRate"];
                }
                if (draft["PayRate"]) {
                    modifiedRecord.payRate = draft["PayRate"];
                }
                if (draft["InTimePayElement"]) {
                    modifiedRecord.inTimePayElement = draft["InTimePayElement"];
                }

                adjustmentRequest.timesheet.lines.push(modifiedRecord);
            }
        }

        this.dispatchEvent(
            new CustomEvent("adjustmentrequestschange", { detail: Object.values(adjustmentRequestsByTimesheetId) })
        );
    }

    applyValuesToDraft(records) {
        const component = this.template.querySelector("c-custom-data-table");
        const existingDraftValues = component.draftValues;

        function mergeArraysByIdWithMap(originalDraftValues, modifiedDraftValues) {
            const idMap = new Map();

            originalDraftValues.forEach((item) => {
                idMap.set(item.Id, item);
            });

            modifiedDraftValues.forEach((item) => {
                if (idMap.has(item.Id)) {
                    idMap.set(item.Id, { ...idMap.get(item.Id), ...item });
                } else {
                    idMap.set(item.Id, item);
                }
            });

            return Array.from(idMap.values());
        }

        const newDraftValues = mergeArraysByIdWithMap(existingDraftValues, records);

        component.draftValues = newDraftValues;

        this.publishAdjustmentRequests();
    }

    handleCellChange(event) {
        this.publishAdjustmentRequests();
    }
}