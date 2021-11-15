public with sharing class QueueLookupController {
  private final static Integer MAX_RESULTS = 5;

  @AuraEnabled(Cacheable=true)
  public static List<LookupSearchResult> search(String searchTerm, String SObjectType) {
    List<List<SObject>> searchResults = [
      FIND :searchTerm
      IN ALL FIELDS
      RETURNING Group(Id, Name WHERE Type = 'Queue' AND Id IN :getAvailableQueuesForSobject(SObjectType))
      LIMIT :MAX_RESULTS
    ];

    List<LookupSearchResult> results = new List<LookupSearchResult>();

    for (Group queue : (List<Group>) searchResults[0]) {
      results.add(new LookupSearchResult(queue.Id, queue.Name));
    }

    return results;
  }

  private static Set<Id> getAvailableQueuesForSobject(String SObjectType) {
    Set<Id> queueIds = new Set<Id>();

    for (QueueSobject queue : [SELECT Id, QueueId FROM QueueSobject WHERE SobjectType = :SObjectType]) {
      queueIds.add(queue.QueueId);
    }

    return queueIds;
  }

  public class LookupSearchResult {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String title;

    public LookupSearchResult(Id id, String title) {
      this.id = id;
      this.title = title;
    }
  }
}
