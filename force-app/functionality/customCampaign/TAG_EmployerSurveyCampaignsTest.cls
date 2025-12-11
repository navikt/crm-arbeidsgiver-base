/**
 * @description Test class for TAG_EmployerSurveyCampaignsBatch and TAG_EmployerSurveyCampaignsScheduler. 
 *
 * @author Andre Colle <andre.colle@nav.no>
 * @since 2025-12-11 Created.
 *
 * @see [License](https://github.com/navikt/crm-arbeidsgiver-integration/blob/main/LICENSE)
 * @see [Github](https://github.com/navikt/crm-arbeidsgiver-integration)
 * @see TAG_EmployerSurveyCampaignsBatch
 * @see TAG_EmployerSurveyCampaignsScheduler
 *
 * @group TAG Employer Survey Campaigns
 */

@IsTest
private class TAG_EmployerSurveyCampaignsTest {

    @IsTest
    static void createCustomCampaignsPositiveTest() {
        insert new NavUnit__c(Name = 'NAV Alna',   INT_UnitType__c = 'LOKAL', INT_ShutDownDate__c = null);
        insert new NavUnit__c(Name = 'NAV Bergen', INT_UnitType__c = 'LOKAL', INT_ShutDownDate__c = null);

        insert new NavUnit__c(Name = 'NAV Oslo (inactive)', INT_UnitType__c = 'LOKAL', INT_ShutDownDate__c = Date.today().addDays(-2));
        insert new NavUnit__c(Name = 'NAV Trondheim (other type)', INT_UnitType__c = 'TILTAK', INT_ShutDownDate__c = null);

        String yearStr = String.valueOf(Date.today().year());

        Test.startTest();
        Database.executeBatch(new TAG_EmployerSurveyCampaignsBatch(), 200);
        Test.stopTest();

        List<CustomCampaign__c> createdCampaigns = [
            SELECT Id, Name
            FROM CustomCampaign__c
            WHERE Name LIKE :('BU ' + yearStr + '%')
        ];
        System.assertEquals(2, createdCampaigns.size(), 'Should create campaigns for the 2 matching NavUnit__c records');

        Set<String> expectedNames = new Set<String>{
            'BU ' + yearStr + ' NAV Alna',
            'BU ' + yearStr + ' NAV Bergen'
        };
        for (CustomCampaign__c cc : createdCampaigns) {
            System.assert(expectedNames.contains(cc.Name), 'Unexpected campaign name: ' + cc.Name);
        }
    }

    @IsTest
    static void schedulerCronPositiveTest() {
        Test.startTest();
        String jobId = System.schedule(
            'Annual NavUnit → Campaign (Test)',
            TAG_EmployerSurveyCampaignsScheduler.CRON,
            new TAG_EmployerSurveyCampaignsScheduler()
        );
        Test.stopTest();

        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(TAG_EmployerSurveyCampaignsScheduler.CRON, ct.CronExpression, 'Cron expression should match');
        System.assertEquals(0, ct.TimesTriggered, 'Job should not execute during test context');
    }
}

