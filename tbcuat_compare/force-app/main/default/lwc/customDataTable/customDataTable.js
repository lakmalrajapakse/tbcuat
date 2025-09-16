import LightningDatatable from "lightning/datatable";
import picklist from "./picklistTemplate.html";
import picklistEdit from "./picklistTemplateEdit.html";

export default class CustomDataTable extends LightningDatatable {
    static customTypes = {
        picklist: {
            editTemplate: picklistEdit,
            template: picklist,
            standardCellLayout: true,
            typeAttributes: ["value", "options"]
        }
    };
}