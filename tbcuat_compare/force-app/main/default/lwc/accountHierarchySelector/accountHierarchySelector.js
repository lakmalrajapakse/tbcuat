import { handleTransactionError } from "c/utils";
import { FlowAttributeChangeEvent } from "lightning/flowSupport";
import { api, LightningElement, wire } from "lwc";

import getAccountWithChildren from "@salesforce/apex/AccountHierarchySelectorController.getAccountWithChildren";

export default class AccountHierarchySelector extends LightningElement {
    @api recordId;
    @api get selectedAccounts() {
        return this._selectedAccounts;
    }
    set selectedAccounts(selectedAccounts = []) {
        this._selectedAccounts = [...selectedAccounts];
    }

    _selectedAccounts;

    accounts;
    gridColumns = [
        {
            label: "Name",
            fieldName: "name",
            type: "text"
        }
    ];
    selectedRows = []; // This empty array is important to avoid a bug (cannot read props of undefined) in the base LWC tree grid
    expandedRows;

    @wire(getAccountWithChildren, { accountId: "$recordId" })
    getAccounts({ data, error }) {
        if (data) {
            const accountDtos = JSON.parse(data);

            this.accounts = this._mapAccountDtosToGridData(accountDtos);

            this.selectedRows = [this.recordId];

            this.expandedRows = this._flattenAccountIds(this.accounts);
        }

        if (error) {
            handleTransactionError("Error getting Accounts", error);
        }
    }

    _mapAccountDtosToGridData(accounts) {
        let mappedAccounts = [];

        if (!accounts || accounts?.length === 0) {
            return mappedAccounts;
        }

        for (let account of accounts) {
            const mappedAccount = { ...account };

            if (account?.children?.length > 0) {
                mappedAccount._children = this._mapAccountDtosToGridData(account.children);

                delete mappedAccount.children;
            }

            mappedAccounts.push(mappedAccount);
        }

        return mappedAccounts;
    }

    _flattenAccountIds(accounts, flattenedAccountIds = []) {
        for (const account of accounts) {
            if (account._children) {
                this._flattenAccountIds(account._children, flattenedAccountIds);
            }

            flattenedAccountIds.push(account.recordId);
        }

        return flattenedAccountIds;
    }

    handleRowSelection(event) {
        this._selectedAccounts = event.detail.selectedRows.map((row) => {
            return {
                Id: row.recordId,
                Name: row.name
            };
        });

        // Notify the Flow of the change in selectedAccounts
        this.dispatchEvent(new FlowAttributeChangeEvent("selectedAccounts", this._selectedAccounts));

        const selectedAccountIds = this._selectedAccounts.map((account) => account.Id);

        // Notify any wrappers of the Ids of the selected Accounts
        this.dispatchEvent(new CustomEvent("accountsselected", { detail: selectedAccountIds }));
    }
}