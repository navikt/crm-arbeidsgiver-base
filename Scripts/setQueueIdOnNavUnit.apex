List<String> testDataUnitNames = new List<String>{'NAV Alna'};
List<QueueSobject> queues = [SELECT Queue.Name, Queue.Id FROM QueueSobject WHERE SobjectType = 'EmployerInquiry__c' AND Queue.Name IN :testDataUnitNames];

Map<String, Id> queueNameToIdMap = new Map<String, Id>();
for(QueueSobject q : queues) {
    queueNameToIdMap.put(q.Queue.Name, q.Queue.Id);
}

List<NavUnit__c> navUnitsWithQueueId = new List<NavUnit__c>();

for (NavUnit__c nu : [SELECT Id, Name, CRM_QueueId__c FROM NavUnit__c WHERE Name IN :testDataUnitNames]) {
    nu.CRM_QueueId__c = queueNameToIdMap.get(nu.Name);    
    navUnitsWithQueueId.add(nu);
}

update navUnitsWithQueueId;
