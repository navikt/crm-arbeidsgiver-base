public without sharing class ReportRelocation_Scheduler implements Schedulable {
  public void execute(SchedulableContext sc) {
    Map<Id, Id> archiveFolderMap = new Map<Id, Id>();

    for (ReportRelocationMap__mdt folder : getFolderRelocationMdt()) {
      archiveFolderMap.putAll(
        ReportFolderHirearchy.getInstance()
          .relatedFoldersRelocationMap(folder.TopLevelReportFolder__c, folder.RelocationFolder__c)
      );
    }

    Database.executeBatch(new RelocateReports_Batch(archiveFolderMap), 100);
  }

  private List<ReportRelocationMap__mdt> getFolderRelocationMdt() {
    List<ReportRelocationMap__mdt> metadata = new List<ReportRelocationMap__mdt>();
    metadata = [SELECT Id, TopLevelReportFolder__c, RelocationFolder__c FROM ReportRelocationMap__mdt];

    return metadata;
  }
}
