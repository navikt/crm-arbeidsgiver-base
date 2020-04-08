@isTest
private without sharing class ArbeidsplassenController_Test {

	@testSetup
	private static void setup() {

	}

	@isTest
	private static void testGetData() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];

		Test.setMock( HttpCalloutMock.class, new ArbeidsplassenController_MockGenerator() );

		Test.StartTest();
		List<ArbeidsplassenViewModel> results = ArbeidsplassenController.getData( acc.Id );
		Test.StopTest();

		System.assertEquals( 2, results.size(), 'Two positions in the mock json' );

		System.assertEquals( Date.newInstance( 2020, 4, 17 ), results[0].applicationDue );
		System.assertEquals( 'Stavanger', results[0].city );
		System.assertEquals( 'Annet', results[0].engagementtype );
		System.assertEquals( 'Heltid', results[0].extent );
		System.assertEquals( 'https://arbeidsplassen.nav.no/stillinger/stilling/3465c1e2-706a-445c-bda9-a4e6c0912dfa', results[0].link );
		System.assertEquals( DateTime.newInstance( 2020, 4, 7, 13, 17, 17 ), results[0].published );
		System.assertEquals( 'Er du utdannet lege uten at du er ansatt i spesialisthelsetjenesten? Intensivavdelingen trenger deg!', results[0].title );


		System.assertEquals( Date.newInstance( 2020, 4, 30 ), results[1].applicationDue );
		System.assertEquals( 'Stavanger', results[1].city );
		System.assertEquals( 'Vikariat', results[1].engagementtype );
		System.assertEquals( 'Heltid', results[1].extent );
		System.assertEquals( 'https://arbeidsplassen.nav.no/stillinger/stilling/20c03c14-2d35-4441-8429-8747ee1f3308', results[1].link );
		System.assertEquals( DateTime.newInstance( 2020, 4, 7, 13, 07, 55 ), results[1].published );
		System.assertEquals( 'Leder - Ruspoliklinikk ung Stavanger', results[1].title );


	}

	@isTest
	private static void testDoCallout() {

		Test.setMock( HttpCalloutMock.class, new ArbeidsplassenController_MockGenerator() );

		Test.StartTest();
		HttpResponse res = ArbeidsplassenController.doCallout( '' );
		Test.StopTest();

		String contentType = res.getHeader( 'Content-Type' );
		System.assert (contentType == 'application/json');
		String actualValue = res.getBody();
		String expectedValue = ArbeidsplassenModel_Test.json;
		System.assertEquals( actualValue, expectedValue );
		System.assertEquals( 200, res.getStatusCode() );
	}
}