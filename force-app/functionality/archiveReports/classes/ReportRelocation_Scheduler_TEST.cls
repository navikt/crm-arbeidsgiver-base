@isTest
public class ReportRelocation_Scheduler_TEST {
  private static final String CRON_EXP = '0 0 0 15 3 ? 2030';

  @isTest
  static void scheduleExecution() {
    Test.startTest();
    String jobId = System.schedule('ScheduledApexTest', CRON_EXP, new ReportRelocation_Scheduler());
    Test.stopTest();

    List<AsyncApexJob> jobsScheduled = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
      FROM AsyncApexJob
      WHERE JobType = 'ScheduledApex'
    ];
    System.assertEquals(1, jobsScheduled.size(), 'One job scheduled.');
    System.assertEquals('ReportRelocation_Scheduler', jobsScheduled[0].ApexClass.Name, 'Scheduled the job.');
  }

  @isTest
  static void batchSubmission() {
    Test.startTest();
    String jobId = System.schedule('ScheduledApexTest', CRON_EXP, new ReportRelocation_Scheduler());
    Test.stopTest();

    List<AsyncApexJob> jobsApexBatch = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
      FROM AsyncApexJob
      WHERE JobType = 'BatchApex'
    ];
    System.assertEquals(1, jobsApexBatch.size(), 'One job scheduled.');
    System.assertEquals('RelocateReports_Batch', jobsApexBatch[0].ApexClass.Name, 'Batch job submitted.');
  }
}
