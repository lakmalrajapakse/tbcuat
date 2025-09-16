import { api, track } from "lwc";
import { deleteRecord } from 'lightning/uiRecordApi';
import LightningModal from "lightning/modal";
import { handleTransactionError } from "c/utils";
import getCompetencies from "@salesforce/apex/ComplianceAddQualificationController.getCompetencies";
import addQualification from "@salesforce/apex/ComplianceAddQualificationController.addQualification";

export default class ComplianceAddQualification extends LightningModal {
    _loadingCompetencies = false;
    _competencies = [];
    _filteredCompetencies = [];
    _selectedCompetencyId = null;
    _categories = [];

    _addingQualification = false;
    _deletingAttachment = false;

    searchTerm;
    validFrom;
    validTo;
    selectedCategory = null;

    @track
    files = [];

    @api
    contactId;

    @api
    get categories() {
        return this._categories;
    }
    set categories(value) {
        this._categories = value;

        if (this._categories.length > 0) {
            this.selectedCategory = this._categories[0].value;
        }
    }
    categories = [];

    columns = [
        { label: "Name", fieldName: "name" },
        {
            label: "Expires?",
            fieldName: "canExpire",
            type: "boolean"
        },
        {
            label: "Requires Proof?",
            fieldName: "requiresProof",
            type: "boolean"
        }
    ];

    connectedCallback() {
        this.reloadCompetencies();
    }

    get isLoading() {
        return this._loadingCompetencies || this._addingQualification;
    }

    get data() {
        return this._filteredCompetencies;
    }

    get hasData() {
        return this._filteredCompetencies.length > 0;
    }

    get addButtonDisabled() {
        return this.selectedCompetencyId != null;
    }

    get categoryOptions() {
        return this.categories;
    }

    get categoryDisabled() {
        return this.categories.length < 2;
    }

    handleSearchChange(event) {
        this.searchTerm = event.detail.value;
        this.refreshSearchResults();
    }

    handleCompetencySelection(event) {
        const selectedCompetencyId = event.detail.selectedRows[0].id;
        this._selectedCompetencyId = selectedCompetencyId;
    }

    handleValidFromChange(event) {
        this.validFrom = event.detail.value;
    }

    handleValidToChange(event) {
        this.validTo = event.detail.value;
    }

    handleCategoryChange(event) {
        const previousCategory = this.selectedCategory;
        this.selectedCategory = event.detail.value;

        if (this.selectedCategory != previousCategory) {
            this.reloadCompetencies();
        }
    }

    async handleAddClick() {
        const fields = this.template.querySelectorAll("lightning-input");
        let valid = true;

        for (let i = 0; i < fields.length; i++) {
            const field = fields[i];

            const fieldValid = field.reportValidity();

            if (!fieldValid) {
                valid = false;
            }
        }

        if (!valid) return;

        try {
            this._addingQualification = true;
            await addQualification({
                qualification: {
                    contactId: this.contactId,
                    competencyId: this._selectedCompetencyId,
                    validFrom: this.validFrom,
                    validTo: this.validTo,
                    attachmentIds: this.files.map(x => x.id)
                }
            });

            this.close("success");
        } catch (ex) {
            this._addingQualification = false;
            handleTransactionError("Save error", ex);
        }
    }

    handleCancelClick() {
        this.close("cancel");
    }

    handleAttachClick() {
        const element = this.template.querySelector('input[data-id="fileInput"]');
        element.click();
    }

    async handleAttachmentDeleteClick(event) {
        const fileId = event.currentTarget.dataset.attachmentId;

        try {
            this._deletingAttachment = true;
            await deleteRecord(fileId);
            this.files = [...this.files.filter((x) => x.id != fileId)];
        } catch (error) {
            handleTransactionError("Attachment delete error", ex);
        } finally {
            this._deletingAttachment = false;
        }
    }

    async handleAttachmentUpload(event) {
        const uploadedFiles = event.detail.files;

        for (let fileIndex in uploadedFiles) {
            const file = uploadedFiles[fileIndex];
            const fileName = file.name;
            const fileId = file.documentId;

            this.files.push({
                id: fileId,
                name: fileName
            });
        }
    }

    refreshSearchResults() {
        if (!this.searchTerm) {
            this._filteredCompetencies = this._competencies;
            return;
        }

        this._selectedCompetencyId = null;

        this._filteredCompetencies = this._competencies
            .filter((comp) => comp.name.toLowerCase().includes(this.searchTerm.toLowerCase()))
            .slice(0, 50);
    }

    async reloadCompetencies() {
        try {
            this._loadingCompetencies = true;
            this._competencies = await getCompetencies({ categories: [this.selectedCategory] });
            this.refreshSearchResults();
        } catch (ex) {
            handleTransactionError("Load error", ex);
        } finally {
            this._loadingCompetencies = false;
        }
    }
}