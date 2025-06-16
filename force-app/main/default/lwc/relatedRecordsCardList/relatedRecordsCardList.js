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
                            recordUrl: `/lightning/r/${record.id}/view`,
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
    test = [
        {
            fields: [
                {
                    fieldName: 'TAG_Link__c',
                    label: 'Opportunity',
                    type: 'customRichText',
                    typeAttributes: { linkify: true },
                    value: '<a href="/lightning/r/CustomOpportunity__c/a0mQI000001EXWj/view" target="_blank">Se muligheten</a>'
                },
                { fieldName: 'Source__c', label: 'Source', type: 'text', typeAttributes: {}, value: 'Kontaktskjema' },
                {
                    fieldName: 'InclusionStage__c',
                    label: 'Stage',
                    type: 'text',
                    typeAttributes: {},
                    value: 'Ny henvendelse'
                },
                { fieldName: 'OWNER.ALIAS', label: 'OWNER.ALIAS' },
                { fieldName: 'TAG_Age__c', label: 'Age', type: 'number', typeAttributes: {}, value: 4 },
                {
                    fieldName: 'Position_in_Rekrutteringsbistand__c',
                    label: 'Position in Rekrutteringsbistand',
                    type: 'text',
                    typeAttributes: {}
                }
            ],
            icon: 'custom:custom14',
            id: 'a0mQI000001EXWjYAO',
            link: '/a0mQI000001EXWjYAO',
            name: '0012',
            title: '0012',
            recordUrl: '/lightning/r/a0mQI000001EXWjYAO/view'
        },
        {
            fields: [
                {
                    fieldName: 'TAG_Link__c',
                    label: 'Opportunity',
                    type: 'customRichText',
                    typeAttributes: { linkify: true },
                    value: '<a href="/lightning/r/CustomOpportunity__c/a0mQI000001F669/view" target="_blank">Se muligheten</a>'
                },
                { fieldName: 'Source__c', label: 'Source', type: 'text', typeAttributes: {}, value: 'Kontaktskjema' },
                {
                    fieldName: 'InclusionStage__c',
                    label: 'Stage',
                    type: 'text',
                    typeAttributes: {},
                    value: 'Ny henvendelse'
                },
                { fieldName: 'OWNER.ALIAS', label: 'OWNER.ALIAS' },
                { fieldName: 'TAG_Age__c', label: 'Age', type: 'number', typeAttributes: {}, value: 1 },
                {
                    fieldName: 'Position_in_Rekrutteringsbistand__c',
                    label: 'Position in Rekrutteringsbistand',
                    type: 'text',
                    typeAttributes: {}
                }
            ],
            icon: 'custom:custom14',
            id: 'a0mQI000001F669YAC',
            link: '/a0mQI000001F669YAC',
            name: '0021',
            title: '0021',
            recordUrl: '/lightning/r/a0mQI000001F669YAC/view'
        }
    ];

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
