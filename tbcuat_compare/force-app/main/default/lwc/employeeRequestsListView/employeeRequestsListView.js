import { LightningElement, api } from "lwc";
import { handleTransactionError } from "c/utils";
import LightningConfirm from "lightning/confirm";
import { deleteRecord } from "lightning/uiRecordApi";
import getEmployeeRequests from "@salesforce/apex/EmployeeRequestsListViewController.getEmployeeRequests";
import EmployeeRequestsListViewNew from "c/employeeRequestsListViewNew";

export default class EmployeeRequestsListView extends LightningElement {
    _recordId;
    _gettingEmployeeRequests = false;
    _deletingRecord = false;

    _data = [];
    _columns = [
        { label: "Name", fieldName: "name" },
        { label: "Type", fieldName: "type" },
        {
            label: "Start Date",
            fieldName: "startDate",
            type: "date",
            typeAttributes: {
                year: "numeric",
                month: "numeric",
                day: "numeric",
                hour: "2-digit",
                minute: "2-digit"
            }
        },
        {
            label: "End Date",
            fieldName: "endDate",
            type: "date",
            typeAttributes: {
                year: "numeric",
                month: "numeric",
                day: "numeric",
                hour: "2-digit",
                minute: "2-digit"
            }
        },
        { label: "Approved", fieldName: "approved", type: "boolean" },
        { label: "Rejected", fieldName: "rejected", type: "boolean" }
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
        return this._gettingEmployeeRequests || this._deletingRecord;
    }

    constructor() {
        super();
        this._columns = [...this._columns, { type: "action", typeAttributes: { rowActions: this.getRowActions } }];
    }

    getRowActions(row, doneCallback) {
        const actions = [];
        const isAvailabilityRow = row.type === "Available" || row.type === "Unavailable";
        const isAbsenceRow = row.type === "Holiday" || row.type === "Sick Leave";
        const isApproved = row.approved === true;
        const isInPast = row.startDate < new Date();
        const isModificationDisabled = (isAvailabilityRow && isInPast) || (isAbsenceRow && isApproved);

        actions.push({
            label: "Edit",
            iconName: "utility:edit",
            name: "edit",
            disabled: isModificationDisabled
        });

        actions.push({
            label: "Delete",
            iconName: "utility:delete",
            name: "delete",
            disabled: isModificationDisabled
        });
        doneCallback(actions);
    }

    async handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case "edit":
                await this.openEditWindow(row.id);
                break;
            case "delete":
                await this.handleDelete(row.id);
                break;
            default:
                break;
        }
    }

    async reload() {
        try {
            if (!this.recordId) return;

            this._gettingEmployeeRequests = true;
            this._data = await getEmployeeRequests({
                contactId: this.recordId
            });
        } catch (ex) {
            handleTransactionError("Load error", ex);
        } finally {
            this._gettingEmployeeRequests = false;
        }
    }

    async handleRefreshClick() {
        await this.reload();
    }

    async handleNewClick() {
        await this.openEditWindow();
    }

    async handleDelete(recordId) {
        const result = await LightningConfirm.open({
            message: "Are you sure you wish to delete this record?",
            variant: "headerless",
            label: "Are you sure you wish to delete this record?"
        });

        if (!result) {
            return;
        }

        try {
            this._deletingRecord = true;
            await deleteRecord(recordId);
            await this.reload();
        } finally {
            this._deletingRecord = false;
        }
    }

    async openEditWindow(recordId) {
        const result = await EmployeeRequestsListViewNew.open({
            size: "small",
            recordId: recordId,
            contactId: this.recordId
        });

        if (result) {
            await this.reload();
        }
    }
}