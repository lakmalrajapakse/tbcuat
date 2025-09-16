import LightningDatatable from "lightning/datatable";
import jobOffersActionsTemplate from "./jobOffersActionsTemplate.html";

export default class JobOffersDataTable extends LightningDatatable {
    static customTypes = {
        jobOffersActions: {
            template: jobOffersActionsTemplate,
            standardCellLayout: true,
            typeAttributes: ["recordId"]
        }
    };
}