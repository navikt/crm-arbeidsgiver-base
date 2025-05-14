import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class RelatedRecordsCardList extends NavigationMixin(LightningElement) {
    @api records;
    
    @track actions = [
        { label: 'Edit', value: 'edit', iconName: 'utility:edit' },
        { label: 'Delete', value: 'delete', iconName: 'utility:delete' },
    ];

    handleAction(event) {
        // Get the value of the selected action
       // const tileAction = event.detail.action.value;
    }
}
