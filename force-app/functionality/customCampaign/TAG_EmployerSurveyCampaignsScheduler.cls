/**
 * @description Scheduler class to run TAG_EmployerSurveyCampaignsBatch once a year to create CustomCampaign__c records.  
 *
 * @author Andre Colle <andre.colle@nav.no>
 * @since 2025-12-11 Created.
 *
 * @see [License](https://github.com/navikt/crm-arbeidsgiver-integration/blob/main/LICENSE)
 * @see [Github](https://github.com/navikt/crm-arbeidsgiver-integration)
 * @see TAG_EmployerSurveyCampaignsBatch
 * @see TAG_EmployerSurveyCampaignsTest
 *
 * @group TAG Employer Survey Campaigns
 */

public class TAG_EmployerSurveyCampaignsScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new TAG_EmployerSurveyCampaignsBatch(), 200);
    }
}
