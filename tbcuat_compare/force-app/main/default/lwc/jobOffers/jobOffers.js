import { LightningElement, api } from "lwc";
import { handleTransactionError } from "c/utils";
import getJobOffers from "@salesforce/apex/JobOffersController.getJobOffers";
import accept from "@salesforce/apex/JobOffersController.accept";
import decline from "@salesforce/apex/JobOffersController.decline";

export default class JobOffers extends LightningElement {
    _recordId;
    _gettingJobOffers = false;
    _accepting = false;
    _declining = false;
    _data = [];

    _columns = [
        { label: "Site", fieldName: "name" },
        {
            label: "Start Time",
            fieldName: "startTime",
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
            label: "End Time",
            fieldName: "endTime",
            type: "date",
            typeAttributes: {
                year: "numeric",
                month: "numeric",
                day: "numeric",
                hour: "2-digit",
                minute: "2-digit"
            }
        },
        { label: "Forecast Pay", fieldName: "forecastPay", type: "currency" },
        {
            label: "Actions",
            label: "Actions",
            type: "jobOffersActions",
            typeAttributes: {
                recordId: { fieldName: "id" }
            },
            fixedWidth: 200
        }
    ];

    @api
    set recordId(value) {
        this._recordId = value;
        this.reload();
    }
    get recordId() {
        return this._recordId;
    }

    async reload() {
        try {
            if (!this.recordId) return;

            this._gettingJobOffers = true;
            this._data = await getJobOffers({
                contactId: this.recordId
            });
        } catch (ex) {
            handleTransactionError("Load error", ex);
        } finally {
            this._gettingJobOffers = false;
        }
    }

    get isLoading() {
        return this._gettingJobOffers == true || this._accepting == true || this._declining == true;
    }

    get hasData() {
        return this._data.length > 0;
    }

    async handleAcceptClick(event) {
        const recordId = event.detail.recordId;

        try {
            if (!recordId) return;

            this._accepting = true;
            await accept({
                offerId: recordId
            });

            await this.reload();
        } catch (ex) {
            handleTransactionError("Accept error", ex);
        } finally {
            this._accepting = false;
        }
    }

    async handleDeclineClick(event) {
        const recordId = event.detail.recordId;

        try {
            if (!recordId) return;

            this._declining = true;
            await decline({
                offerId: recordId
            });

            await this.reload();
        } catch (ex) {
            handleTransactionError("Decline error", ex);
        } finally {
            this._declining = false;
        }
    }
}