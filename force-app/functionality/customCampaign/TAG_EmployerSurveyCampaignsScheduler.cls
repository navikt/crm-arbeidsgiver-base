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

    // 0 0 0 15 1 ? * => 00:00 on January 15 every year
    public static final String CRON = '0 30 12 12 12 ? 2025';

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new TAG_EmployerSurveyCampaignsBatch(), 200);
    }

    // Helper to schedule programmatically
    public static void scheduleJob() {
        System.schedule('Annual NavUnit → Campaign', CRON, new TAG_EmployerSurveyCampaignsScheduler());
    }
}
