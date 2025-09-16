import { LightningElement, api } from 'lwc';

export default class EmbeddedRateCardVfPage extends LightningElement {
    @api
    rateCardId;

    @api
    height = 400;

    get sourceUrl() {
        return `/apex/sirenum__RateCard?id=${this.rateCardId}`;
    }

    get styles() {
        return `height: ${this.height}px;`;
    }
}