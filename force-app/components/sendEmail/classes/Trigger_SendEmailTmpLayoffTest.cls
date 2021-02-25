@isTest
private without sharing class Trigger_SendEmailTmpLayoffTest {
    @testSetup
    private static void makeData() {
        EmailTemplate et = new EmailTemplate(
            DeveloperName = 'tempLayoffReceiptSubsidiary',
            Name = 'tempLayoffReceiptSubsidiary',
            IsActive = true,
            FolderId = UserInfo.getOrganizationId(),
            UiType = 'sfx',
            TemplateType = 'custom',
            Subject = 'Temp Test',
            HtmlValue = '<html><head></head><body><p>Hei {{{TemporaryLayoff__c.ContactName__c}}}! NAV har mottatt meldingen din om:{{{TemporaryLayoff__c.Type__c}}}.</p></body></html>'
        );
        Database.insert( et, false );

        Contact c = new Contact(LastName = 'test', email = 'ola.nordmann@test.com', TAG_Informed__c = true);
        Database.insert( c, false );

        NavUnit__c nav = new NavUnit__c(Name = 'NAV Test');
        Database.insert( nav, false );
    }
    @isTest
    private static void Trigger_SendEmailTmpLayoffTest() {

        Contact c = [SELECT Id FROM Contact];

        NavUnit__c nav = [SELECT Id FROM NavUnit__c];

        TemporaryLayoff__c t2 = new TemporaryLayoff__c(
            Type__c = 'MASSEOPPSIGELSE',
            NAV_Unit__c = nav.Id
        );
        insert t2;

        List<EmailMessage> emails = [SELECT HtmlBody, ToAddress FROM EmailMessage];
        System.assertEquals(0, emails.size(), 'No emails sent before');

        Test.StartTest();
        TemporaryLayoff__c t1 = new TemporaryLayoff__c(
            Contact__c = c.Id,
            Type__c = 'MASSEOPPSIGELSE',
            NAV_Unit__c = nav.Id
        );
        insert t1;
        Test.StopTest();
        
        List<EmailMessage> emailsAfter = [SELECT Id FROM EmailMessage];
        System.assertEquals(1, emailsAfter.size(), 'should be one email sent after insert');

        
    }
}