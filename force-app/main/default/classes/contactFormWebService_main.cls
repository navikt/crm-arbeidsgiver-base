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
		Id contactId = fetchOrCreateContact( rw, accountId );

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

	public static Id fetchOrCreateContact( RequestWrapper rw, Id accountId ) {

		List<Contact> con = [SELECT Id FROM Contact WHERE AccountId = : accountId AND Email = : rw.email LIMIT 1];

		if ( con.size() == 0 ) {
			con.add( new Contact( FirstName = rw.firstName, LastName = rw.lastName, Email = rw.email, MobilePhone = rw.phoneNo, AccountId = accountId ) );
			insert con[0];
		}

		return con[0].Id;
	}
}