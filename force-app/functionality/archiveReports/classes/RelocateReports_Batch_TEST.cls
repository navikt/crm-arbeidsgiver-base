@isTest
public with sharing class RelocateReports_Batch_TEST {
  @isTest(SeeAllData=true)
  static void relocateSuccess() {
    ReportRelocationMap__mdt metadata = [
      SELECT Id, TopLevelReportFolder__c, RelocationFolder__c
      FROM ReportRelocationMap__mdt
      WHERE DeveloperName = 'TEST'
    ];
    Id folderId = [SELECT Id FROM Folder WHERE Type = 'Report' AND Name = :metadata.TopLevelReportFolder__c]?.Id;

    Map<Id, Id> relocationMap = new Map<Id, Id>{ folderId => getFakeId(Folder.SObjectType) };

    Test.startTest();
    ApiMock.setTestMock('PATCH_MOVE_REPORT', 200, 'OK');
    Database.executeBatch(new RelocateReports_Batch(relocationMap));
    Test.stopTest();

    List<AsyncApexJob> jobsApexBatch = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType, NumberOfErrors
      FROM AsyncApexJob
      WHERE JobType = 'BatchApex' AND Status = 'Completed'
    ];

    System.assertEquals(1, jobsApexBatch.size(), 'Relocated report successfully');
  }

  @isTest
  static void noReportsFound() {
    Map<Id, Id> relocationMap = new Map<Id, Id>{ getFakeId(Folder.SObjectType) => getFakeId(Folder.SObjectType) };

    Test.startTest();
    ApiMock.setTestMock('PATCH_MOVE_REPORT', 200, 'OK');
    Database.executeBatch(new RelocateReports_Batch(relocationMap));
    Test.stopTest();

    List<AsyncApexJob> jobsApexBatch = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType, NumberOfErrors
      FROM AsyncApexJob
      WHERE JobType = 'BatchApex' AND Status = 'Completed'
    ];

    System.assertEquals(1, jobsApexBatch.size(), 'Relocated report successfully');
  }

  @isTest(SeeAllData=true)
  static void relocateWithCalloutException() {
    ReportRelocationMap__mdt metadata = [
      SELECT Id, TopLevelReportFolder__c, RelocationFolder__c
      FROM ReportRelocationMap__mdt
      WHERE DeveloperName = 'TEST'
    ];
    Id folderId = [SELECT Id FROM Folder WHERE Type = 'Report' AND Name = :metadata.TopLevelReportFolder__c]?.Id;

    Map<Id, Id> relocationMap = new Map<Id, Id>{ folderId => getFakeId(Folder.SObjectType) };

    Test.startTest();
    Database.executeBatch(new RelocateReports_Batch(relocationMap));
    Test.stopTest();

    List<AsyncApexJob> jobsApexBatch = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType, NumberOfErrors
      FROM AsyncApexJob
      WHERE JobType = 'BatchApex' AND Status = 'Completed'
    ];

    System.assertEquals(1, jobsApexBatch.size(), 'Job completed successfully');
  }

  private static Integer s_num = 1;

  private static String getFakeId(Schema.SObjectType sot) {
    String result = String.valueOf(s_num++);
    return sot.getDescribe().getKeyPrefix() + '0'.repeat(12 - result.length()) + result;
  }
}
