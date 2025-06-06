import LightningDatatable from "lightning/datatable";
import customNameTemplate from "./customName.html";
import customRichTextTemplate from "./customRichText.html";

import customTextTemplate from "./customText.html";

export default class RelatedRecordsTable extends LightningDatatable {
    
    static customTypes = {
    customName: {
      template: customNameTemplate,
      standardCellLayout: true,
      typeAttributes: ["recordUrl"]
    },
    customRichText: {
      template: customRichTextTemplate,
      standardCellLayout: true,
    },
    customText: {
      template: customTextTemplate,
      standardCellLayout: true,
    },
    // Other custom types here
  };

    
}