@RestResource(urlMapping = '/ContactForm/*')
global with sharing class TAG_ContactFormWebService_main {

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

		CustomOpportunity__c co = new CustomOpportunity__c( Account__c = accountId, Contact__c = contactId, IsFromContactForm__c = true, InquiryCategory__c = getType( rw.type ), SenderEmail__c = rw.email, MunicipalityNumber__c = rw.municipalityCode );
		insert co;

		return [SELECT Name FROM CustomOpportunity__c WHERE Id = : co.Id].Name;
	}


	public static Id fetchAccount( String organisationNumber ) {
		List<Account> acc = [SELECT Id FROM Account WHERE INT_Ident__c = : organisationNumber LIMIT 1];
		if ( acc.size() > 0 ) { return acc[0].Id; }
		else { return null; }
	}

	public static Id fetchOrCreateContact( RequestWrapper rw, Id accountId ) {

		List<Contact> existingContact = [SELECT Id FROM Contact WHERE Email = : rw.email LIMIT 1];

		if ( existingContact.size() == 0 ) {

			Contact con = new Contact( FirstName = rw.firstName, LastName = rw.lastName, Email = rw.email, MobilePhone = rw.phoneNo, AccountId = accountId );

			insert con;

			return con.Id;
		} else {
			return existingContact[0].Id;
		}
	}

	public static String getType( String val ) {
		if ( val == 'REKRUTTERING' ) {
			return 'Rekruttering';
		} else if ( val == 'REKRUTTERING_MED_TILRETTELEGGING' ) {
			return 'Rekruttering med tilrettelegging';
		} else if ( val == 'ARBEIDSTRENING' ) {
			return 'Arbeidstrening';
		} else if ( val == 'FOREBYGGE_SYKEFRAVÆR' ) {
			return 'Forebygge sykefravær';
		} else {
			return null;
		}
	}
}