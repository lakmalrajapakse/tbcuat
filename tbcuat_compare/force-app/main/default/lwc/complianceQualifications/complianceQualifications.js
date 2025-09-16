import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { handleTransactionError } from "c/utils";
import ComplianceAddQualification from "c/complianceAddQualification";
import getQualifications from "@salesforce/apex/ComplianceQualificationsController.getQualifications";

export default class ComplianceQualifications extends NavigationMixin(LightningElement) {
    _loadingQualifications = false;
    _qualifications = [];

    @api
    contactId;

    @api
    categories = [];

    columns = [
        {
            label: "Competency",
            fieldName: "url",
            type: "url",
            typeAttributes: { label: { fieldName: "competencyName" } },
            cellAttributes: { iconName: { fieldName: "icon" } }
        },
        {
            label: "Valid From",
            fieldName: "validFrom",
            type: "date",
            typeAttributes: {
                year: "numeric",
                month: "numeric",
                day: "numeric"
            }
        },
        {
            label: "Valid To",
            fieldName: "validTo",
            type: "date",
            typeAttributes: {
                year: "numeric",
                month: "numeric",
                day: "numeric"
            }
        },
        {
            label: "Attachments",
            fieldName: "attachments",
            type: "text"
        }
    ];

    connectedCallback() {
        this.reloadQualifications();
    }

    get isLoading() {
        return this._loadingQualifications;
    }

    get hasData() {
        return this._qualifications.length > 0;
    }

    get data() {
        return this._qualifications;
    }

    async reloadQualifications() {
        try {
            this._loadingQualifications = true;

            let results = await getQualifications({
                contactId: this.contactId,
                categories: this.categories.map((x) => x.value)
            });

            results = results.map((x) => {
                return {
                    ...x,
                    attachments: `${x.attachments.length} attachment(s)`,
                    icon: x.valid ? "action:approval" : "action:close"
                };
            });

            for (let qualification of results) {
                qualification.url = await this.generateUrlForRecordId(qualification.id);
            }

            this._qualifications = results;
        } catch (ex) {
            handleTransactionError("Load error", ex);
        } finally {
            this._loadingQualifications = false;
        }
    }

    async handleAddClick() {
        const result = await ComplianceAddQualification.open({
            size: "small",
            description: "Modal window to add a new qualification",
            contactId: this.contactId,
            categories: this.categories
        });

        if (result == "success") {
            this.reloadQualifications();
        }
    }

    async generateUrlForRecordId(recordId) {
        return await this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: recordId,
                actionName: "view"
            }
        });
    }
}