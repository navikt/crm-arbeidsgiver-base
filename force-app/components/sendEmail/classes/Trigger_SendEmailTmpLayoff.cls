/*
   Can use either this class in a process or Trigger_SendEmail as a trigger
 */

global class Trigger_SendEmailTmpLayoff extends MyTriggers {
    global override void onAfterInsert() {

        Id emailTmp = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'tempLayoffReceiptSubsidiary' LIMIT 1].Id;

        List<EmailQueue__c> requests = new List<EmailQueue__c>();
        for (TemporaryLayoff__c tl : (List<TemporaryLayoff__c>) records) {
            EmailQueue__c request = new EmailQueue__c();
            request.TemplateId__c = emailTmp;
			request.TargetObjectId__c = tl.Contact__c;
			request.WhatId__c = tl.Id;
			request.SaveAsActivity__c = true;
			requests.add( request );
        }
        insert requests;
    }
}
