import { api } from "lwc";
import LightningModal from "lightning/modal";
import { createRecord } from "lightning/uiRecordApi";
import { handleTransactionError } from "c/utils";

export default class ShiftManagementTimesheetsUpload extends LightningModal {
    MAX_FILE_SIZE = 1048576; //Max file size 1.0 MB 
    @api
    recordIds;

    _attachingToRecords = false;

    get isLoading() {
        return this._attachingToRecords;
    }

    async handleAttachmentUpload(event) {
        const uploadedFiles = event.detail.files;

        try {
            this._attachingToRecords = true;
            for (let file of uploadedFiles) {
                if (file.size > this.MAX_FILE_SIZE) {
                    throw new Error("File size cannot exceed 1.0 MB");
                }
                
                for (let recordId of this.recordIds) {
                    let data = {
                        apiName: "ContentDocumentLink",
                        fields: {
                            ContentDocumentId: file.documentId,
                            LinkedEntityId: recordId,
                            ShareType: "V", // Viewer access
                            Visibility: "AllUsers"
                        }
                    };

                    await createRecord(data);
                }
            }

            this.close({ success: true });
        } catch (ex) {
            handleTransactionError("Upload error", ex);
            this._attachingToRecords = false;
        }
    }

    handleCancelClick() {
        this.close({ success: false });
    }
}