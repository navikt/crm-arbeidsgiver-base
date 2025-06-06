import { LightningElement, api } from 'lwc';

export default class RelatedRecordsCardList extends LightningElement {
    @api records;
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
