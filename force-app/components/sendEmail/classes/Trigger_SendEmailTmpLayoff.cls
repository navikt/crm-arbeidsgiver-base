/*
   Can use either this class in a process or Trigger_SendEmail as a trigger
 */

global class Trigger_SendEmailTmpLayoff extends MyTriggers {
    global override void onAfterInsert() {

        Map<Id, Id> tmpLayoffWithContacts = new Map<Id, Id>();
        for (TemporaryLayoff__c tl : (List<TemporaryLayoff__c>) records) {
            tmpLayoffWithContacts.put(tl.Id, tl.Contact__c);
        }

        sendEmails( tmpLayoffWithContacts );
    }

    public static void sendEmails(Map<Id, Id> tmpLayoffWithContacts){

        Id emailTmp = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'tempLayoffReceiptSubsidiary' LIMIT 1].Id;

        List<EmailQueue__c> requests = new List<EmailQueue__c>();
        for (Id id : tmpLayoffWithContacts.keyset()) {
            EmailQueue__c request = new EmailQueue__c();
            request.TemplateId__c = emailTmp;
			request.TargetObjectId__c = tmpLayoffWithContacts.get(id);
			request.WhatId__c = id;
            request.Status__c = 'Instant';
			request.SaveAsActivity__c = true;
			requests.add( request );
        }
        insert requests;

    }
}
