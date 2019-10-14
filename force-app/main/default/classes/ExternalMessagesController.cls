/**
 * Created by u157416 on 11/10/2019.
 */

public with sharing class ExternalMessagesController {
    @AuraEnabled
    public static List<ExternalMessages__c> getMessages(Id recordId) {
        List<ExternalMessages__c> messages = [SELECT Id, CreatedById, CreatedBy.Name, Text__c, Account__c, Case__c, CreatedDate, Name FROM ExternalMessages__c WHERE Account__c = :recordId ORDER BY CreatedDate ASC];
        return messages;
    }

    @AuraEnabled
    public static ExternalMessages__c createMessage(Id recordId, String newMessage) {
        Account thisAccount = [SELECT Id, Name FROM Account WHERE Id = :recordId];
        String userName = UserInfo.getUserName();

        ExternalMessages__c createdMessage = new ExternalMessages__c(Name = userName, Text__c = newMessage, Account__c = recordId);
        insert createdMessage;
        return createdMessage;
    }

}