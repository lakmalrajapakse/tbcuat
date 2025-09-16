export class ProcessingCompleteEvent extends CustomEvent {
    constructor() {
        super("processingcomplete");
    }
}