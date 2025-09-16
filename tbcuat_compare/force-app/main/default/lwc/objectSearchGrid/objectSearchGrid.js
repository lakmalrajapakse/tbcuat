import { LightningElement, api, wire } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { debounce, handleTransactionError } from "c/utils";
import search from "@salesforce/apex/ObjectSearchGridController.search";

export default class ObjectSearchGrid extends LightningElement {
    @api
    objectName;

    @api
    objectFields;

    @api
    columns;

    @wire(getObjectInfo, { objectApiName: "$objectName" })
    objectInfo;

    searchTerm;
    _searchExecuted = false;
    _searching = false;

    data = [];

    get isLoading() {
        return this._searching;
    }

    get hasData() {
        return this.data.length > 0;
    }

    get object() {
        return (this.objectInfo || {}).data || {};
    }

    get objectFieldsLower() {
        return this.objectFields.map((x) => x.toLowerCase());
    }

    get objectSearchLabel() {
        const label = this.object.label;

        return `Search for ${label}`;
    }

    get objectNoDataLabel() {
        const label = this.object.labelPlural;

        return `Cannot find any ${label} matching the given search term.`
    }

    get fieldMetadata() {
        return Object.fromEntries(Object.entries(this.object.fields || {}).map(([k, v]) => [k.toLowerCase(), v]));
    }

    get objectSearchFieldsLabel() {
        const fields = this.objectFieldsLower
            .filter((x) => this.fieldMetadata[x] != null)
            .map((x) => this.fieldMetadata[x].label);

        return `Search by ${fields.join(", ")}`;
    }

    handleSearchChange(event) {
        this.searchTerm = event.detail.value;
        this._searchExecuted = false;

        this.executeSearch();
    }

    handleSelection(event) {
        const selectedRecordId = event.detail.selectedRows[0].Id;
        this.selectedRecordId = selectedRecordId;

        this.fireRowSelected(selectedRecordId);
    }

    executeSearch = debounce(() => this._executeSearch(), 400);
    async _executeSearch() {
        try {
            this._searching = true;
            if (this.searchTerm && this.searchTerm.length < 2) {
                return;
            }

            const results = await search({
                searchTerm: this.searchTerm,
                objectName: this.objectName,
                searchFields: this.objectFields
            });

            this.data = results;
            this.fireRowSelected(null);
        } catch (e) {
            handleTransactionError("Search error", e);
        } finally {
            this._searching = false;
            this._searchExecuted = true;
        }
    }

    fireRowSelected(id) {
        const rowSelectedEvent = new CustomEvent("rowselected", {
            detail: {
                id: id
            }
        });
        this.dispatchEvent(rowSelectedEvent);
    }
}