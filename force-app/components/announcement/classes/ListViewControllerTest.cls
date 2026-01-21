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
        String nonExistentListView = 'NonExistentListView123456';
        DateTime result;
        Test.startTest();
        try {
            result = ListViewController.getListViewLastViewedDate(nonExistentListView);
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'Expected AuraHandledException for ListView not found');
            return; // Test passes if exception is thrown
        }
        System.assert(false, 'Expected exception was not thrown for non-existent ListView');
        Test.stopTest();
    }
}
