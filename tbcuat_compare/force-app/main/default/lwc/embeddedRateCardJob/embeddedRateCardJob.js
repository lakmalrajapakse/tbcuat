import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import RATE_CARD_FIELD from "@salesforce/schema/TR1__Job__c.s5m__JobRole__r.sirenum__Rate_Card__c";

export default class EmbeddedRateCardJob extends LightningElement {
    @api
    recordId;

    @api
    height = 400;

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [RATE_CARD_FIELD]
    })
    job;

    get rateCardId() {
        return getFieldValue(this.job.data, RATE_CARD_FIELD) || null;
    }
}