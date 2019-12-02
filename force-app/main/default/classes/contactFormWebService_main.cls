@RestResource(urlMapping = '/ContactForm/*')
global with sharing class contactFormWebService_main {

	public class RequestWrapper {

		public String type;
		public String municipalityCode;
		public String organisationName;
		public String organisationNumber;
		public String firstName;
		public String lastName;
		public String email;
		public String phoneNo;
	}

	@HttpPost
	global static void doPost(  ) {

		String requestString = RestContext.request.requestBody.toString();
		RequestWrapper rw = (RequestWrapper) JSON.deserialize( requestString, RequestWrapper.class );

		InclusionOpportunity__c io = new InclusionOpportunity__c( Account__c = fetchAccount( rw.organisationNumber ) );
		insert io;
	}


	public static Id fetchAccount( String organisationNumber ) {
		return [SELECT Id FROM Account WHERE CompanyNumber__c = : organisationNumber LIMIT 1].Id;
	}
}