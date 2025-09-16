import { LightningElement, api, track } from 'lwc';

export default class IllustrationBase extends LightningElement {
    @api body;
    @api header;

    @track hasHeader = false;
    connectedCallback(){
        if (this.header && this.header.length > 0){
            this.hasHeader = true;
        }else{
            this.hasHeader = false;
        }
    }
}