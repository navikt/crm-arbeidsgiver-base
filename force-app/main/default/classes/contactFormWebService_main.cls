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

		Id accountId = fetchAccount( rw.organisationNumber );
		Id contactId = fetchOrCreateContact( accountId, rw.firstName, rw.lastName, rw.email, rw.phoneNo );

		InclusionOpportunity__c io = new InclusionOpportunity__c( Account__c = accountId, Contact__c = contactId, IsFromContactForm__c = true, InquiryCategory__c = rw.type );
		insert io;

		// InclusionContactPerson__c icp = new InclusionContactPerson__c( InclusionOpportunity__c = io.Id, Contact__c = contact );
		// insert icp;
	}


	public static Id fetchAccount( String organisationNumber ) {
		List<Account> acc = [SELECT Id FROM Account WHERE INT_OrganizationNumber__c = : organisationNumber LIMIT 1];
		if ( acc.size() > 0 ) { return acc[0].Id; }
		else { return null; }
	}

	public static Id fetchOrCreateContact( Id accountId, String firstName, String lastName, String email, String phoneNo ) {

		List<Contact> con = [SELECT Id FROM Contact WHERE AccountId = : accountId AND Email = : email LIMIT 1];

		if ( con.size() == 0 ) {
			con.add( new Contact( FirstName = firstName, LastName = lastName, Email = email, MobilePhone = phoneNo, AccountId = accountId ) );
			insert con[0];
		}

		return con[0].Id;
	}
}