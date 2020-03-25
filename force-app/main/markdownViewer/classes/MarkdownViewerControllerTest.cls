@isTest
private without sharing class MarkdownViewerControllerTest {

	@isTest
	private static void testGetData() {

		TemporaryLayoff__c tl = new TemporaryLayoff__c();
		tl.OtherComments__c = '\n### Årsak\nSlett denne\n### Yrker\nkokk\n### Annet\n';
		insert tl;

		Test.StartTest();
		String results = MarkdownViewerController.getData( tl.Id, 'TemporaryLayoff__c', 'OtherComments__c' );
		Test.StopTest();

		System.assertEquals( tl.OtherComments__c, results, 'Should just be the same data' );
	}
}