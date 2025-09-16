import { LightningElement, api } from "lwc";
import ComplianceAddRating from "c/complianceAddRating";
import getRatings from "@salesforce/apex/ComplianceRatingsController.getRatings";

export default class ComplianceRatings extends LightningElement {
    _loadingRatings = false;
    ratings = [];

    @api
    contactId;

    get isLoading() {
        return this._loadingRatings;
    }

    columns = [
        {
            label: "Rated By",
            fieldName: "raterName",
            type: "text"
        },
        {
            label: "Customer",
            fieldName: "customerName",
            type: "text"
        },
        {
            label: "Rating Date",
            fieldName: "ratingDate",
            type: "date",
            typeAttributes: {
                year: "numeric",
                month: "numeric",
                day: "numeric"
            }
        },
        {
            label: "Rating",
            fieldName: "rating",
            type: "text"
        }
    ];

    connectedCallback() {
        this.reloadRatings();
    }

    get hasData() {
        return this.ratings.length > 0;
    }

    get data() {
        return this.ratings;
    }

    async handleAddClick() {
        const result = await ComplianceAddRating.open({
            size: "small",
            description: "Modal window to add a new rating",
            contactId: this.contactId
        });

        if (result == "success") {
            this.reloadRatings();
        }
    }

    async reloadRatings() {
        try {
            this._loadingRatings = true;

            this.ratings = await getRatings({
                contactId: this.contactId
            });
        } catch (ex) {
            handleTransactionError("Load error", ex);
        } finally {
            this._loadingRatings = false;
        }
    }
}