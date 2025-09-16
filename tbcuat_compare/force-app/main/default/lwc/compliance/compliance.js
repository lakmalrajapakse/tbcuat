import { LightningElement, api } from "lwc";
import { handleTransactionError } from "c/utils";
import getCategories from "@salesforce/apex/ComplianceController.getCategories";

export default class Compliance extends LightningElement {
    _max_categories = 5;
    _loadingCategories = false;

    categoryTypes = [];

    @api
    recordId;

    connectedCallback() {
        this.reloadCategories();
    }

    get isLoading() {
        return this._loadingCategories;
    }

    get hasData() {
        return this.categories.length > 0;
    }

    async reloadCategories() {
        try {
            this._loadingCategories = true;

            this.categories = [];

            const categories = await getCategories();

            const individualCategories = categories.splice(0, this._max_categories);
            const remainingCategories = [...categories];

            this.categories = individualCategories.map((x) => {
                return {
                    label: x.label,
                    key: x.value,
                    categoryTypes: [{ value: x.value, label: x.label }]
                };
            });

            this.categories.push({
                label: "No Category",
                key: "No Category",
                categoryTypes: [{ value: null, label: "No Category" }]
            });

            if (remainingCategories.length > 0) {
                const reducedRemainingCategory = remainingCategories.reduce(
                    (acc, item) => {
                        acc.categoryTypes.push({ value: item.value, label: item.label });
                        return acc;
                    },
                    {
                        key: "Other Categories",
                        categoryTypes: []
                    }
                );

                reducedRemainingCategory.label = `+${reducedRemainingCategory.categoryTypes.length} more`;
                this.categories.push(reducedRemainingCategory);
            }
        } catch (ex) {
            handleTransactionError("Load error", ex);
        } finally {
            this._loadingCategories = false;
        }
    }
}