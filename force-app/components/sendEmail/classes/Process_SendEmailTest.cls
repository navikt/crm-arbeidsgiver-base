@isTest
private without sharing class Process_SendEmailTest {

	@testSetup
	private static void setup() {
		EmailTemplate et = new EmailTemplate( DeveloperName = 'tempLayoffReceiptSubsidiary', Name = 'tempLayoffReceiptSubsidiary', IsActive = true, FolderId = UserInfo.getOrganizationId(), UiType = 'sfx', TemplateType = 'custom', Subject = 'New message', HtmlValue = '<html><head></head><body><p>Hi {{{TemporaryLayoff__c.ContactName__c}}}. This is regarding {{{TemporaryLayoff__c.Type__c}}}.</p></body></html>' );
		Database.insert( et, false );

		Profile profile = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = 'Standard Platform User' OR Name = 'Standard plattformbruker' LIMIT 1];
		User user = new User(
			FirstName = 'test',
			LastName = 'user',
			Email = 'test@nav.apextest',
			Username = 'test@nav.apextest',
			Alias = 'testuser',
			LanguageLocaleKey = 'no',
			LocaleSidKey = 'no_NO',
			TimeZoneSidKey = 'Europe/Paris',
			EmailEncodingKey = 'UTF-8',
			ProfileId = profile.Id,
			Department = '1'
			);
		insert user;
	}

	@isTest
	private static void testSendEmail() {
		System.runAs( getTestUser() )
		{

			Contact con = new Contact( TAG_Informed__c = true, LastName = 'testetternavn', FirstName = 'test', Email = 'tore.toresen@example.com' );
			insert con;

			TemporaryLayoff__c tl = new TemporaryLayoff__c( KafkaId__c = 'test', Contact__c = con.Id, Type__c = 'PERMITTERING_UTEN_LØNN', ContactEmail__c = 'tore.toresen@example.com' );

			List<EmailMessage> emails = [SELECT HtmlBody, ToAddress FROM EmailMessage];
			System.assertEquals( 0, emails.size(), 'No emails sent before' );

			Test.StartTest();
			insert tl;
			Test.StopTest();

			emails = [SELECT HtmlBody, ToAddress FROM EmailMessage];

			System.assertEquals( 1, emails.size(), 'Only one email sent, only one EmailMessage created' );
			System.assert ( emails[0].HtmlBody.replaceAll( '\n', '' ).contains( '<html> <head></head> <body>  <p>Hi test testetternavn. This is regarding Permittering uten lønn.</p>' ), 'The new html body should have converted all variables ( {{{ var }}} )' );
			System.assertEquals( 'tore.toresen@example.com', emails[0].ToAddress, 'Sent to contact email' );
		}
	}

	@isTest
	private static void testSendEmail_wrongEmail() {
		System.runAs( getTestUser() )
		{

			Contact con = new Contact( TAG_Informed__c = true, LastName = 'test', FirstName = 'test', InvalidEmail__c = 'tore.toresen@example.com' );
			insert con;

			TemporaryLayoff__c tl = new TemporaryLayoff__c( KafkaId__c = 'test', Contact__c = con.Id, Type__c = 'PERMITTERING_UTEN_LØNN', ContactEmail__c = '' );

			List<EmailMessage> emails = [SELECT HtmlBody, ToAddress FROM EmailMessage];
			System.assertEquals( 0, emails.size(), 'No emails sent before' );

			Test.StartTest();
			insert tl;
			Test.StopTest();

			emails = [SELECT HtmlBody, ToAddress FROM EmailMessage];
			System.assertEquals( 0, emails.size(), 'No email after, due to wrong email' );
		}
	}

	@isTest
	private static void testGetMapOfEmailTemplates() {

		Process_SendEmail.Request req = new Process_SendEmail.Request();
		req.emailTemplateName = 'tempLayoffReceiptSubsidiary';

		Test.StartTest();
		Map<String, Id> templateMap = Process_SendEmailHelper.getMapOfEmailTemplates( new List<Process_SendEmail.Request> { req } );
		Test.StopTest();

		Id expected = [SELECT Id, Name FROM EmailTemplate WHERE Name = 'tempLayoffReceiptSubsidiary' LIMIT 1].Id;

		System.assertEquals( 1, templateMap.size(), 'Only one template with name "tempLayoffReceiptSubsidiary"' );
		System.assert (templateMap.containsKey( 'tempLayoffReceiptSubsidiary' ), 'key "tempLayoffReceiptSubsidiary" should exist in map');
		System.assertEquals( expected, templateMap.values()[0], 'Fetch the EmailTemplate id' );
	}


	private static User getTestUser() {
		return [SELECT Id FROM User WHERE UserName = 'test@nav.apextest'];
	}
}
