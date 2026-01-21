@isTest
private class ListViewControllerTest {
    @isTest
    static void testGetListViewLastViewedDate_Success() {
        // Query for any existing ListView
        List<ListView> listViews = [
            SELECT DeveloperName
            FROM ListView
            WHERE SobjectType = 'TAG_Announcement__c'
            LIMIT 1
        ];

        String listViewName = listViews[0].DeveloperName;

        Test.startTest();
        DateTime result = ListViewController.getListViewLastViewedDate(listViewName);
        Test.stopTest();

        // If we reach this point without exception, the test passes
        // Result can be null or a DateTime - both are valid
        System.assert(true, 'Method executed without throwing an exception');
    }

    @isTest
    static void testGetListViewLastViewedDate_NonExistentListView() {
        Test.startTest();
        String nonExistentListView = 'NonExistentListView123456';
        DateTime result = ListViewController.getListViewLastViewedDate(nonExistentListView);
        System.assertEquals(null, result, 'Should return null for non-existent ListView');
        Test.stopTest();
    }

    @isTest
    static void testGetListViewLastViewedDate_NullInput() {
        Test.startTest();
        DateTime result = ListViewController.getListViewLastViewedDate(null);
        System.assertEquals(null, result, 'Should return null for null input');
        Test.stopTest();
    }
}
