import { api } from "lwc";
import LightningModal from "lightning/modal";
import { handleTransactionError } from "c/utils";
import getRatingOptions from "@salesforce/apex/ComplianceAddRatingController.getRatingOptions";
import addRating from "@salesforce/apex/ComplianceAddRatingController.addRating";

export default class ComplianceAddRating extends LightningModal {
    _loadingRatingOptions = false;
    _addingRating = false;

    @api
    contactId;

    raterApiName = "Contact";
    raterApiFields = ["Name", "Email"];
    raterColumns = [
        { label: "Name", fieldName: "Name" },
        { label: "Email", fieldName: "Email" }
    ];

    customerApiName = "Account";
    customerApiFields = ["Name", "Client_Code__c"];
    customerColumns = [
        { label: "Name", fieldName: "Name" },
        { label: "Client Code", fieldName: "Client_Code__c" }
    ];

    selectedRating;
    selectedCustomerId;
    selectedRaterId;

    get isLoading() {
        return this._loadingRatingOptions || this._addingRating;
    }

    connectedCallback() {
        this.reloadRatingOptions();
    }

    handleRatingChange(event) {
        this.selectedRating = event.detail.value;
    }

    handleCancelClick() {
        this.close("cancel");
    }

    handleCustomerSelected(event) {
        this.selectedCustomerId = event.detail.id;
    }

    handleRaterSelected(event) {
        this.selectedRaterId = event.detail.id;
    }

    get addButtonDisabled() {
        return this.selectedCustomerId == null || this.selectedRaterId == null || this.selectedRating == null;
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
            this._addingRating = true;
            await addRating({
                rating: {
                    contactId: this.contactId,
                    raterId: this.selectedRaterId,
                    customerId: this.selectedCustomerId,
                    rating: this.selectedRating
                }
            });

            this.close("success");
        } catch (ex) {
            this._addingRating = false;
            handleTransactionError("Save error", ex);
        }
    }

    async reloadRatingOptions() {
        try {
            this._loadingRatingOptions = true;
            this.ratingOptions = await getRatingOptions();
        } catch (ex) {
            handleTransactionError("Load error", ex);
        } finally {
            this._loadingRatingOptions = false;
        }
    }
}