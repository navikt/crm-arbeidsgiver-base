import { LightningElement, api } from 'lwc';

export default class RelatedRecordsCardList extends LightningElement {
    @api records;

    get recordListAsTiles() {
        if (this.records && this.records.length > 0) {
            try {
                // Create a new list by mapping over the original records
                const newRecordsList = this.records.map((record) => {
                    // console.log('RECORD:', JSON.stringify(record));

                    // Ensure fields array exists and has at least one element
                    if (record.fields && record.fields.length > 0) {
                        const fieldsCopy = [...record.fields];
                        const field = fieldsCopy.shift(); // Remove the first field
                        // console.log('Removed field:', field);

                        return {
                            ...record,
                            title: field.value,
                            fields: fieldsCopy // Keep the remaining fields intact
                        };
                    }

                    // Return the record as-is if fields are empty or undefined
                    return { ...record, fields: [] };
                });

                //  console.log('New record list:', JSON.stringify(newRecordsList));
                return newRecordsList;
            } catch (error) {
                this.handleError('Error creating recordListTiles', error);
                return [];
            }
        }
        return [];
    }
    /* HELPERS */
    handleError(message, error) {
        console.error(`${message}:`, JSON.stringify(error));
    }

    /* 
    <lightning-tile
                    label={record.title}
                    href={record.recordUrl}
                    actions={actions}
                    onactiontriggered={handleAction}
                >
                @track actions = []; //= [{ label: 'Edit', value: 'edit', iconName: 'utility:edit' }];

    handleAction(event) {
        // Get the value of the selected action
        const tileAction = event.detail.action.value;
    }
                */
}
