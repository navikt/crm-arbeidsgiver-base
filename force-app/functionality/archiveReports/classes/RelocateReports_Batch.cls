public without sharing class RelocateReports_Batch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
  private static final String REPORT_QUERY = 'SELECT Id, FolderName, OwnerId FROM Report WHERE OwnerId IN :folderIds AND OwnerId NOT IN :deleteFolderIds';
  private static final String LAST_RUN_FILTER = ' AND LastRunDate < LAST_N_DAYS:180';
  private Map<Id, Id> reportFolderIds;
  private List<Exception> exceptions;

  public RelocateReports_Batch(Map<Id, Id> reportFolderIds) {
    this.reportFolderIds = reportFolderIds;
    this.exceptions = new List<Exception>();
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    Set<Id> folderIds = reportFolderIds.KeySet();
    Set<Id> deleteFolderIds = new Set<Id>();
    deleteFolderIds.addAll(reportFolderIds.values());

    String query = Test.isRunningTest() ? REPORT_QUERY : REPORT_QUERY + LAST_RUN_FILTER;

    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext context, List<Report> reports) {
    ReportCalloutService service = new ReportCalloutService();

    try {
      for (Report r : reports) {
        ReportCalloutService.Response resp = service.moveReport(r.Id, reportFolderIds.get(r.OwnerId));
      }
    } catch (Exception e) {
      exceptions.add(e);
    }
  }

  public void finish(Database.BatchableContext context) {
    if (!exceptions.isEmpty()) {
      LoggerUtility logger = new LoggerUtility();
      logger.error('RelocateReports_Batch exceptions' + exceptions.size(), null);
      logger.publish();
    }
  }
}
