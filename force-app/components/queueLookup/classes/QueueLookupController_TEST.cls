@isTest
public class QueueLookupController_TEST {
  @isTest
  static void searchWithResults() {
    Group queue1 = TestDataFactory.getQueue('NAV Lister', 'queue_1037', 'NavTask__c');
    Group queue2 = TestDataFactory.getQueue('NAV Eidsvoll', 'queue_237', 'NavTask__c');
    List<Id> fixedSearchResults = new List<Id>{ queue1.id, queue2.id };

    Test.setFixedSearchResults(fixedSearchResults);

    List<QueueLookupController.LookupSearchResult> results = QueueLookupController.search('NAV', 'NavTask__c');

    system.assertEquals(2, results.size(), 'Search yielded results');
  }

  @isTest
  static void searchWithResultsFromUnsupportedSObject() {
    Group queue1 = TestDataFactory.getQueue('NAV Lister', 'queue_1037', 'NavTask__c');
    Group queue2 = TestDataFactory.getQueue('NAV Eidsvoll', 'queue_237', 'CustomOpportunity__c');
    List<Id> fixedSearchResults = new List<Id>{ queue1.id, queue2.id };

    Test.setFixedSearchResults(fixedSearchResults);

    List<QueueLookupController.LookupSearchResult> results = QueueLookupController.search('NAV', 'NavTask__c');

    system.assertEquals(1, results.size(), 'Search yielded results');
  }

  @isTest
  static void searchNoResults() {
    List<QueueLookupController.LookupSearchResult> results = QueueLookupController.search(
      'caskdja1131321',
      'NavTask__c'
    );

    system.assertEquals(0, results.size(), 'Search yielded no results.');
  }
}
