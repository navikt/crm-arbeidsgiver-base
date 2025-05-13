import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class ResponsiveDataTable extends NavigationMixin(LightningElement)  {
    columns = ['Name', 'CreatedDate', 'Email', 'Phone', 'MailingAddress']; // SELECT fields
    relatedObjectApiName = 'Contact';  // from 
    filter = 'CreatedDate < TODAY'; // F.eks. WHERE-klausul eller feltverdier
     // query +=  relationField + ' IN (SELECT ' + parentRelationField + ' FROM ' + parentObjectApiName + ' WHERE Id = \'' + parentId + '\')';
    relationField = 'AccountId'; 
    parentRelationField = 'Id';
    parentObjectApiName = 'Account';
    parentRecordId = '001RR00000bhWZ8YAM';
    isMobile = window.innerWidth <= 768; // Initialize directly
    columnsConfig = [
        { "label": "Navn",  "fieldName": "Name", type: 'customName', typeAttributes:{ recordUrl: { fieldName:"recordUrl"}}},
        { "label": "E-post", "fieldName": "Email",type: 'email'},
        { "label": "Telefon", "fieldName": "Phone", type: 'phone' },
        { "label": "Opprettet", "fieldName": "CreatedDate", type: 'date-local' },
        
        { "label": "Link", "fieldName": "link__c", type: 'customRichText'},
    ];


    records = [
        {
          "Name": "Kari Normann",
          "CreatedDate": "2025-04-29T10:11:32.000Z",
          "Email": "knormann@testepost.no",
          "Phone": "12345678",
          "Id": "003QI00000ReFbsYAF",
          "link__c": "<a href='/lightning/r/a0jRR00000PHCjL/view' target='_self'>IA-avtale</a>", 
          "recordUrl": "/003QI00000ReFbsYAF",

        },
        {
          "Name": "Geir Tønnesen",
          "CreatedDate": "2025-04-29T10:11:32.000Z",
          "User": {
            "Name": "User User",
            "CompanyName": "crm-workflows-base",
            "Id": "005RR00000CSEWlYAP"
          },
          "Email": "gtonnesen@testepost.no",
          "Id": "003QI00000ReFbrYAF"
        },
        {
          "Name": "Ola Larsen",
          "CreatedDate": "2025-04-29T10:11:32.000Z",
          "Email": "olarsen@testepost.no",
          "Id": "003QI00000ReFbqYAF"
        },
        {
          "Name": "Berit Hansen",
          "CreatedDate": "2025-04-29T10:11:32.000Z",
          "Email": "berit.hansen@testepost.no",
          "Id": "003QI00000ReFbpYAF",
          "MailingAddress": {
                "street": "14 Dronning Eufemias gate",
                "city": "Oslo",
                "postalCode": "0191",
                "country": "NO"
            }
        }
      ];

     

      connectedCallback() {
        
      }
    
      iconName = 'standard:account';
      cardTitle = 'Responsive Data Table';

    get relatedRecordsPageUrl() {
        return this.generateRelatedRecordsUrl();
    }
    generateRelatedRecordsUrl() {
        const baseUrl = '/lightning/cmp/c__relatedRecordsPage';
        const params = new URLSearchParams({
            c__configKey: this.relatedObjectApiName,
            c__parentRecordId: this.parentRecordId,
            c__size: 'small'
        });
        return `${baseUrl}?${params.toString()}`;
    }

}
