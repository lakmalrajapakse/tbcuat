import { api, LightningElement } from "lwc";
import { FlowAttributeChangeEvent } from "lightning/flowSupport";

export default class ContentDocumentLinkCreator extends LightningElement {
    @api recordId;
    @api contentDocumentIds;
    @api filenames;

    @api get contentDocumentLinks() {
        return this._contentDocumentLinks;
    }
    set contentDocumentLinks(contentDocumentLinks = []) {
        this._contentDocumentLinks = [...contentDocumentLinks];
    }

    _contentDocumentLinks;
    _selectedAccountIds;
    _filenames;

    get filenamesCsv() {
        return this.filenames.join(",");
    }

    handleAccountsSelected(event) {
        this._selectedAccountIds = [...event.detail];

        this._contentDocumentLinks = [];

        for (const selectedAccountId of this._selectedAccountIds) {
            // The file will already be attached to the current Account
            if (selectedAccountId === this.recordId) {
                continue;
            }

            for (const contentDocumentId of this.contentDocumentIds) {
                this._contentDocumentLinks.push({
                    ContentDocumentId: contentDocumentId,
                    LinkedEntityId: selectedAccountId
                });
            }
        }

        this.dispatchEvent(new FlowAttributeChangeEvent("contentDocumentLinks", this._contentDocumentLinks));
    }
}