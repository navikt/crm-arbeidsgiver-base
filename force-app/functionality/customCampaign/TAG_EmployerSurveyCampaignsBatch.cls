/**
 * @description Batch class to create CustomCampaign__c records for each active local NavUnit__c. Once a year Nav surveys to employers.
 * The responses from the employers are handled in Salesforce Arbeidsgiver.  
 *
 * @author Andre Colle <andre.colle@nav.no>
 * @since 2025-12-11 Created.
 *
 * @see [License](https://github.com/navikt/crm-arbeidsgiver-integration/blob/main/LICENSE)
 * @see [Github](https://github.com/navikt/crm-arbeidsgiver-integration)
 * @see TAG_EmployerSurveyCampaignsScheduler
 * @see TAG_EmployerSurveyCampaignsTest
 *
 * @group TAG Employer Survey Campaigns
 */


public with sharing class TAG_EmployerSurveyCampaignsBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Name FROM NavUnit__c WHERE INT_UnitType__c = \'LOKAL\' AND isActiveUnit__c = true'
        );
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<CustomCampaign__c> toInsert = new List<CustomCampaign__c>();
        Integer yearToApply = Date.today().year();

        for (SObject s : scope) {
            NavUnit__c nav = (NavUnit__c)s;
            String originalName = (nav.Name == null) ? '' : nav.Name.trim();
            String composedName = 'BU ' + String.valueOf(yearToApply) + ' ' + originalName;

            toInsert.add(new CustomCampaign__c(
                Name = composedName
            ));
        }

        if (!toInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(toInsert, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error e : results[i].getErrors()) {
                        System.debug(LoggingLevel.ERROR,
                            'Failed to insert CustomCampaign__c for NavUnit__c "' +
                            ((NavUnit__c)scope[i]).Name + '": ' + e.getMessage());
                    }
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) { }
}

