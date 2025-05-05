import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class RelatedRecordsCardList extends NavigationMixin(LightningElement) {
    @api records = [];
    @api columnsConfig = [];
    
    get processedRecords() {
        console.log('records :', JSON.stringify(this.records, null, 2));
        console.log('columnsConfig :', JSON.stringify(this.columnsConfig, null, 2));
        return this.records.map(record => {
            const fields = this.columnsConfig.map(col => ({
                label: col.label,
                value: record[col.fieldName],
                type: col.type
            }));
            return {
                id: record.Id,
                name: record.Name,
                fields
            };
        });
    }

    
    @track actions = [
        { label: 'Edit', value: 'edit', iconName: 'utility:edit' },
        { label: 'Delete', value: 'delete', iconName: 'utility:delete' },
    ];

    handleAction(event) {
        // Get the value of the selected action
        const tileAction = event.detail.action.value;
    }
}
