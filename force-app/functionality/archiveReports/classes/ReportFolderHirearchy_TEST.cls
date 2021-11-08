@isTest
public with sharing class ReportFolderHirearchy_TEST {
  @isTest
  static void noFoldersFound() {
    Map<Id, Id> folders = ReportFolderHirearchy.getInstance().relatedFoldersRelocationMap('TEST', 'TEST_DELETE');

    System.assert(folders.isEmpty(), 'No folders found');
  }

  @isTest(SeeAllData=true)
  static void getRelatedFoldersRelocationMap() {
    Map<Id, Id> folders = ReportFolderHirearchy.getInstance()
      .relatedFoldersRelocationMap('RelocationTestFolder', 'RelocationTestFolder');

    System.assertEquals(3, folders.size(), '3 Related report folders found');
  }
}
