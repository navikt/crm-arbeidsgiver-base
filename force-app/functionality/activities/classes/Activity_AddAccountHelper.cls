public with sharing class Activity_AddAccountHelper {
  public static List<SObject> getActivityWithChangedWhatId(Map<Id, SObject> triggerOldMap, List<SObject> newRecords) {
    List<SObject> sObjectsToAddAccount = new List<SObject>();
    Set<Id> recordTypes = getRecordTypeIds();

    for (SObject sObj : newRecords) {
      Id recordType = (Id) sObj.get('RecordTypeId');

      if (recordTypes.contains(recordType) && (sObj.get('WhatId') != triggerOldMap.get(sObj.Id).get('WhatId'))) {
        sObjectsToAddAccount.add(sObj);
      }
    }

    return sObjectsToAddAccount;
  }

  public static List<SObject> addAccount(List<SObject> activities, Boolean isInsert) {
    if (!userHasPermissionArbeidsgiver()) {
      return null;
    }
    if (!userHaveAccess()) {
      return null;
    }

    activities = keepActivitiesWithWhatId(activities);
    if (activities.size() == 0) {
      return null;
    }

    Map<String, String> activityAccountMapping = getActivityAccountMapping();
    Map<String, Set<Id>> whatIdMap = getWhatIdMap(activities);
    Map<String, String> mapOfSObjectPrefix = getMapOfSObjectPrefix(whatIdMap);
    Map<String, Set<Id>> idsSeparatedBysObject = getIdsSeparatedBySObject(whatIdMap, mapOfSObjectPrefix);
    Map<String, List<SObject>> sObjectsSeparatedBySObject = getSObjectsSeparatedBySObjectType(
      idsSeparatedBysObject,
      activityAccountMapping
    );
    Map<Id, Id> mapOfActivityAndAccount = getMapOfActivityAndAccount(
      activities,
      sObjectsSeparatedBySObject,
      activityAccountMapping,
      mapOfSObjectPrefix
    );

    activities = addAccountToActivity(activities, mapOfActivityAndAccount, isInsert, mapOfSObjectPrefix);

    return activities;
  }

  public static Boolean userHasPermissionArbeidsgiver() {
    return FeatureManagement.checkPermission('Arbeidsgiver');
  }

  public static List<SObject> keepActivitiesWithWhatId(List<SObject> activities) {
    List<SObject> sObjectsToKeep = new List<SObject>();

    for (SObject sObj : activities) {
      if ((Id) sObj.get('WhatId') != null) {
        sObjectsToKeep.add(sObj);
      }
    }

    return sObjectsToKeep;
  }

  public static Boolean userHaveAccess() {
    if (!fieldIsCreateable('RelatedToAccount__c')) {
      return false;
    }
    if (!fieldIsAccessible('WhatId')) {
      return false;
    }

    if (!AccessControlValidator.sObjectIsAccessible('Activity_Account_Map__mdt')) {
      return false;
    }
    if (!AccessControlValidator.fieldIsAccessible('Activity_Account_Map__mdt', 'SObject_API_Field_Name__c')) {
      return false;
    }
    if (!AccessControlValidator.fieldIsAccessible('Activity_Account_Map__mdt', 'SObject_API_Name__c')) {
      return false;
    }
    Map<String, String> activityAccountMapping = getActivityAccountMapping();

    // see if all parent WhatIds' Account field can be queried
    for (String key : activityAccountMapping.keySet()) {
      if (!AccessControlValidator.fieldIsAccessible(key, activityAccountMapping.get(key))) {
        return false;
      }
    }

    return true;
  }

  public static Boolean fieldIsCreateable(String sObjectFieldStr) {
    if (!AccessControlValidator.fieldIsCreateable('Task', sObjectFieldStr)) {
      return false;
    }
    if (!AccessControlValidator.fieldIsCreateable('Event', sObjectFieldStr)) {
      return false;
    }

    return true;
  }

  public static Boolean fieldIsAccessible(String sObjectFieldStr) {
    if (!AccessControlValidator.fieldIsAccessible('Task', sObjectFieldStr)) {
      return false;
    }
    if (!AccessControlValidator.fieldIsAccessible('Event', sObjectFieldStr)) {
      return false;
    }

    return true;
  }

  public static Map<String, Set<Id>> getWhatIdMap(List<SObject> activities) {
    Map<String, Set<Id>> whatIdMap = new Map<String, Set<Id>>();

    for (SObject activity : activities) {
      Id whatId = (Id) activity.get('WhatId');
      String sObjPrefix = ((String) whatId).substring(0, 3);

      if (whatIdMap.containsKey(sObjPrefix)) {
        whatIdMap.get(sObjPrefix).add(whatId);
      } else {
        Set<Id> whatIds = new Set<Id>();
        whatIds.add(whatId);
        whatIdMap.put(sObjPrefix, whatIds);
      }
    }

    return whatIdMap;
  }

  public static Map<String, String> getMapOfSObjectPrefix(Map<String, Set<Id>> whatIdMap) {
    Map<String, String> mapOfSObjectPrefix = new Map<String, String>();

    for (String sObjPrefix : whatIdMap.keyset()) {
      Set<Id> whatIds = whatIdMap.get(sObjPrefix);
      Id firstWhatId;
      for (Id i : whatIds) {
        firstWhatId = i;
        break;
      }

      String parentSObjectType = getSOjectTypeFromRecordId(firstWhatId);
      mapOfSObjectPrefix.put(sObjPrefix, parentSObjectType);
    }

    return mapOfSObjectPrefix;
  }

  public static String getSOjectTypeFromRecordId(String recordId) {
    Id i = (Id) recordId;

    return String.valueOf(i.getSobjectType());
  }

  public static Map<String, Set<Id>> getIdsSeparatedBySObject(
    Map<String, Set<Id>> whatIdMap,
    Map<String, String> mapOfSObjectPrefix
  ) {
    Map<String, Set<Id>> idsSeparatedBysObject = new Map<String, Set<Id>>();

    for (String sObjPrefix : whatIdMap.keyset()) {
      Set<Id> whatIds = whatIdMap.get(sObjPrefix);
      String firstWhatId;
      for (Id i : whatIds) {
        firstWhatId = ((String) i).substring(0, 3);
        break;
      }

      String parentSObjectType = mapOfSObjectPrefix.get(firstWhatId);
      idsSeparatedBysObject.put(parentSObjectType, whatIds);
    }

    return idsSeparatedBysObject;
  }

  public static Map<String, List<SObject>> getSObjectsSeparatedBySObjectType(
    Map<String, Set<Id>> idsSeparatedBysObject,
    Map<String, String> activityAccountMapping
  ) {
    Map<String, List<SObject>> sObjectsSeparatedBySObject = new Map<String, List<SObject>>();
    List<String> queries = new List<String>();

    for (String sObjectName : idsSeparatedBysObject.keySet()) {
      String sObjectFieldName = activityAccountMapping.get(sObjectName.toLowerCase());
      if (sObjectFieldName == null) {
        continue;
      } // skip iteration

      String ids = '(\'' + String.join((Iterable<String>) idsSeparatedBysObject.get(sObjectName), '\', \'') + '\')';
      String query = 'SELECT ' + sObjectFieldName + ' FROM ' + sObjectName + ' WHERE Id IN ' + ids;
      List<SObject> sObjects = Database.query(query);
      sObjectsSeparatedBySObject.put(sObjectName.toLowerCase(), sObjects);
    }

    return sObjectsSeparatedBySObject;
  }

  public static Map<Id, Id> getMapOfActivityAndAccount(
    List<SObject> activities,
    Map<String, List<SObject>> sObjectsSeparatedBySObject,
    Map<String, String> activityAccountMapping,
    Map<String, String> mapOfSObjectPrefix
  ) {
    Map<Id, Id> mapOfActivityAndAccount = new Map<Id, Id>();

    for (SObject activity : activities) {
      String whatIdPrefix = ((String) activity.get('WhatId')).substring(0, 3);
      String parentSObjectType = mapOfSObjectPrefix.get(whatIdPrefix).toLowerCase();

      if (sObjectsSeparatedBySObject.containsKey(parentSObjectType)) {
        Map<Id, SObject> parentSObjects = new Map<Id, SObject>(sObjectsSeparatedBySObject.get(parentSObjectType));
        Id whatId = (Id) activity.get('WhatId');

        if (parentSObjects.containsKey(whatId)) {
          SObject parentSObj = parentSObjects.get(whatId);
          String apiFieldName = activityAccountMapping.get(parentSObjectType);
          Id accountId = (Id) parentSObj.get(apiFieldName);
          mapOfActivityAndAccount.put(activity.Id, accountId);
        }
      }
    }

    return mapOfActivityAndAccount;
  }

  public static List<SObject> addAccountToActivity(
    List<SObject> originalActivities,
    Map<Id, Id> mapOfActivityAndAccount,
    Boolean isInsert,
    Map<String, String> mapOfSObjectPrefix
  ) {
    List<SObject> sObjectsToUpdate = new List<SObject>();

    String type = getSOjectTypeFromRecordId(originalActivities[0].Id);
    Set<Id> recordTypes = getRecordTypeIds();

    if (type == 'Task') {
      for (Task t : (List<Task>) originalActivities) {
        if (!recordTypes.contains(t.RecordTypeId)) {
          continue;
        } else if (isInsert) {
          Task newTask = new Task(Id = t.Id, RelatedToAccount__c = mapOfActivityAndAccount.get(t.Id));
          sObjectsToUpdate.add(newTask);
        } else {
          t.RelatedToAccount__c = mapOfActivityAndAccount.get(t.Id);
        }
      }
    } else if (type == 'Event') {
      for (Event e : (List<Event>) originalActivities) {
        if (!recordTypes.contains(e.RecordTypeId)) {
          continue;
        } else if (isInsert) {
          Event newEvent = new Event(Id = e.Id, RelatedToAccount__c = mapOfActivityAndAccount.get(e.Id));
          sObjectsToUpdate.add(newEvent);
        } else {
          e.RelatedToAccount__c = mapOfActivityAndAccount.get(e.Id);
        }
      }
    }

    if (isInsert) {
      return sObjectsToUpdate;
    } else {
      return originalActivities;
    }
  }

  public static Map<String, String> getActivityAccountMapping() {
    List<Activity_Account_Map__mdt> activityAccountMapping = [
      SELECT Id, SObject_API_Field_Name__c, SObject_API_Name__c
      FROM Activity_Account_Map__mdt
    ];
    Map<String, String> activityAccountMap = new Map<String, String>();
    for (Activity_Account_Map__mdt mdt : activityAccountMapping) {
      activityAccountMap.put(mdt.SObject_API_Name__c.toLowerCase(), mdt.SObject_API_Field_Name__c);
    }

    return activityAccountMap;
  }

  private static Set<Id> getRecordTypeIds() {
    Set<Id> recordTypeIds = new Set<Id>();

    recordTypeIds.add(
      Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('ArbeidsgiverEvent').getRecordTypeId()
    );
    recordTypeIds.add(
      Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('ArbeidsgiverTask').getRecordTypeId()
    );

    return recordTypeIds;
  }
}
