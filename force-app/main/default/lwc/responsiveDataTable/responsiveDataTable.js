import { LightningElement, track, api, wire } from 'lwc';

export default class ResponsiveDataTable extends LightningElement {
    columns = ['Name', 'CreatedDate', 'Email', 'Phone', 'MailingAddress']; // SELECT fields
    relatedObjectApiName = 'Contact';  // from 
    filter = 'CreatedDate < TODAY'; // F.eks. WHERE-klausul eller feltverdier
     // query +=  relationField + ' IN (SELECT ' + parentRelationField + ' FROM ' + parentObjectApiName + ' WHERE Id = \'' + parentId + '\')';
    relationField = 'AccountId'; 
    parentRelationField = 'Id';
    parentObjectApiName = 'Account';
    parentRecordId = '001QI00000YZE7PYAX';
    isMobile = window.innerWidth <= 768; // Initialize directly
    columnsConfig = [
        { "label": "E-post", "fieldName": "Email",type: 'email'},
        { "label": "Telefon", "fieldName": "Phone", type: 'phone' },
        { "label": "Opprettet", "fieldName": "CreatedDate", type: 'datetime' },
        { "label": "Navn", "fieldName": "Name" },
        { "label": "Adresse", "fieldName": "MailingAddress", type: 'address' }
    ];
    records = [
        {
          "Name": "Kari Normann",
          "CreatedDate": "2025-04-29T10:11:32.000Z",
          "Email": "knormann@testepost.no",
          "Phone": "12345678",
          "Id": "003QI00000ReFbsYAF"
        },
        {
          "Name": "Geir Tønnesen",
          "CreatedDate": "2025-04-29T10:11:32.000Z",
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
        console.log('log something'); // success
        
      }
    

}
