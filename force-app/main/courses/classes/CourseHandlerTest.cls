@isTest
private with sharing class CourseHandlerTest {
	@isTest
	private static void CourseHandlerTest() {
		List<Course__c> courses = new List<Course__c>();

		for ( Integer i = 0; i < 2; i++ ) {
			Course__c course = new Course__c();
			course.Name = 'Test ' + i;
			course.Description__c = 'Testkurs';
			course.Region__c = 'Oslo';
			course.Active__c = true;
			course.Max_number_of_participants__c = 10;
			courses.add( course );
		}
		insert courses;
		System.assertEquals( 2, courses.size(), '2 courses inserted' );

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/Course';
		req.httpMethod = 'GET';

		RestContext.request = req;
		RestContext.response = res;

		Test.startTest();
		CourseHandler.doGet();
		Test.stopTest();
		String result = res.responseBody.toString();

		System.assertNotEquals( null, result );
		System.assert ( result.contains( 'Test 0' ) );
		System.assert ( result.contains( 'Test 1' ) );
		System.assert ( result.contains( 'Oslo' ) );
		System.assert ( result.contains( 'Testkurs' ) );
		System.assert ( result.contains( '1' ) );

	}
}
