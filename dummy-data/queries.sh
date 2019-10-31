sfdx force:data:tree:export --query "SELECT id, name, RecordType.DeveloperName, Bedriftsnummer__c, Naeringsgruppe__c, Naeringskode__c, Organisasjonsnummer__c, NumberOfEmployees, Phone, ShippingCity, ShippingCountry, ShippingPostalCode, ShippingState, ShippingStreet, ParentId, (SELECT Id, CRM_RolleHosVirksomhet__c, Email, FirstName, LastName, MobilePhone FROM Contacts), (SELECT Id, ActivityDate, ActivityDateTime, DurationInMinutes, EndDateTime, EventSubtype, IsAllDayEvent, ShowAs, Subject FROM Events), (SELECT Id, ActivityDate, CompletedDateTime, IsClosed, IsHighPriority, Priority, Status, Subject, TaskSubtype FROM Tasks) FROM Account" --outputdir dummy-data/ia --plan