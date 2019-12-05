@RestResource(urlMapping = '/ContactForm/*')
global with sharing class ContactFormWebService_main {

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
	global static String doPost(  ) {

		String requestString = RestContext.request.requestBody.toString();
		RequestWrapper rw = (RequestWrapper) JSON.deserialize( requestString, RequestWrapper.class );

		Id accountId = fetchAccount( rw.organisationNumber );
		Id contactId = fetchOrCreateContact( rw, accountId );

		CustomOpportunity__c co = new CustomOpportunity__c( Account__c = accountId, Contact__c = contactId, IsFromContactForm__c = true, InquiryCategory__c = rw.type, senderEmail__c = rw.email );
		insert co;

		return [SELECT Name FROM CustomOpportunity__c WHERE Id = : co.Id].Name;
	}


	public static Id fetchAccount( String organisationNumber ) {
		List<Account> acc = [SELECT Id FROM Account WHERE CompanyNumber__c = : organisationNumber LIMIT 1];
		if ( acc.size() > 0 ) { return acc[0].Id; }
		else { return null; }
	}

	public static Id fetchOrCreateContact( RequestWrapper rw, Id accountId ) {

		List<Contact> existingContact = [SELECT Id FROM Contact WHERE AccountId = : accountId AND Email = : rw.email LIMIT 1];

		if ( existingContact.size() == 0 ) {

			Contact con = new Contact( FirstName = rw.firstName, LastName = rw.lastName, Email = rw.email, MobilePhone = rw.phoneNo, AccountId = accountId );

			Database.DMLOptions dml = new Database.DMLOptions();
			dml.DuplicateRuleHeader.allowSave = true;
			dml.DuplicateRuleHeader.runAsCurrentUser = true;

			Database.SaveResult sr = Database.insert( con, dml );

			return con.Id;
		} else {
			return existingContact[0].Id;
		}

	}
}