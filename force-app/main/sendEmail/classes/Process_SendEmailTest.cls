@isTest
private without sharing class Process_SendEmailTest {

	@testSetup
	private static void setup() {
		insert new EmailTemplate( DeveloperName = 'testEmailTemplate', Name = 'testEmailTemplate', IsActive = true, FolderId = UserInfo.getOrganizationId(), TemplateType = 'custom', Subject = 'New message', HtmlValue = '<html><p>Hi {!TemporaryLayoff__c.ContactName__c}. This is regarding {!TemporaryLayoff__c.Type__c}.</p></html>' );
	}

	@isTest
	private static void testSendEmail() {

		Contact con = new Contact( TAG_Informed__c = true, LastName = 'test', FirstName = 'test', Email = 'tore.toresen@example.com' );
		insert con;

		TemporaryLayoff__c tl = new TemporaryLayoff__c( KafkaId__c = 'test', Contact__c = con.Id, Type__c = 'PERMITTERING_UTEN_LØNN', ContactEmail__c = 'tore.toresen@example.com' );
		insert tl;

		Process_SendEmail.Request req = new Process_SendEmail.Request();
		req.recipientContactId = con.Id;
		req.relatedTo = tl.Id;
		req.emailTemplateName = 'testEmailTemplate';

		Test.StartTest();
		Process_SendEmail.sendEmail( new List<Process_SendEmail.Request> { req } );
		Test.StopTest();

		List<EmailMessage> emails = [SELECT HtmlBody, ToAddress FROM EmailMessage];

		System.assertEquals( 1, emails.size(), 'Only one email sent, only one EmailMessage created' );
		System.assertEquals( '<html><p>Hi test test. This is regarding Permittering uten lønn.</p></html>', emails[0].HtmlBody, 'The new html body should have converted all variables ( {{{ var }}} )' );
		System.assertEquals( 'tore.toresen@example.com', emails[0].ToAddress, 'Sent to contact email' );
	}

	@isTest
	private static void testGetMapOfEmailTemplates() {

		Process_SendEmail.Request req = new Process_SendEmail.Request();
		req.emailTemplateName = 'testEmailTemplate';

		Test.StartTest();
		Map<String, Id> templateMap = Process_SendEmailHelper.getMapOfEmailTemplates( new List<Process_SendEmail.Request> { req } );
		Test.StopTest();

		Id expected = [SELECT Id, Name FROM EmailTemplate WHERE Name = 'testEmailTemplate' LIMIT 1].Id;

		System.assertEquals( 1, templateMap.size(), 'Only one template with name "testEmailTemplate"' );
		System.assert (templateMap.containsKey( 'testEmailTemplate' ), 'key "testEmailTemplate" should exist in map');
		System.assertEquals( expected, templateMap.values()[0], 'Fetch the EmailTemplate id' );
	}
}
