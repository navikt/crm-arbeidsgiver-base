import { LightningElement, api } from 'lwc';

export default class RelatedRecordsTable extends LightningElement {
    @api records;
    @api columnsConfig;
}
