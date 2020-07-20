public with sharing class SharedFunctions_Helper {

	public class ContactWrapper {
		public String firstName;
		public String lastName;
		public String phone;
		public String email;
		public String companyNumber;
		public String source;

	}


	// will check both Email and InvalidEmail__c in case the email is Salesforce invalid (but not invalid for Norwegians, e.g., ÆØÅ)
	public static List<Contact> getExistingContacts( List<ContactWrapper> wrapperList ) {

		List<String> emails = new List<String>();
		for ( ContactWrapper cw : wrapperList ) {
			emails.add( cw.email );
		}

		List<Contact> existingContacts = [SELECT Id, Email, Account.INT_OrganizationNumber__c, InvalidEmail__c
		                                  FROM Contact
		                                  WHERE
		                                      ( Email IN : emails AND Email != null ) OR
		                                      ( InvalidEmail__c IN : emails AND InvalidEmail__c != null )];

		return existingContacts;
	}

	// create AccountContactRelation for unmapped contacts (e.g., when a contact is found originally but not mapped to the new account they're inquiring from)
	public static void mapUnmappedContacts( List<ContactWrapper> wrapperList, List<Contact> existingContacts, Map<String, Account> accountMap ) {

		Map<String, List<ContactWrapper> > contactWrapperMap = createMapOfContactWrapper( wrapperList );
		List<AccountContactRelation> relationships = new List<AccountContactRelation>();

		Map<Id, Id> contactAndAccountToMap = new Map<Id, Id>();
		for ( Contact con : existingContacts ) {

			String email = '';
			if ( con.Email != null ) {
				email = con.Email;
			} else if ( con.InvalidEmail__c != null ) {
				email = con.InvalidEmail__c;
			}

			if ( contactWrapperMap.containsKey( email.toLowerCase() ) ) {

				List<ContactWrapper> wrapper = contactWrapperMap.get( email.toLowerCase() );
				for ( ContactWrapper cw : wrapper ) {

					if ( email == cw.email ) {

						String postedCompanyNumber = cw.companyNumber;
						String currentCompanyNumber = con.Account.INT_OrganizationNumber__c;

						if ( postedCompanyNumber != currentCompanyNumber && accountMap.containsKey( postedCompanyNumber ) ) {
							Id accId = accountMap.get( postedCompanyNumber ).Id;
							relationships.add( new AccountContactRelation( AccountId = accId, ContactId = con.Id ) );
						}
					}
				}
			}
		}

		Database.insert( relationships, false ); // insert all, and ignore errors on duplicates
	}

	/* Check for valid emails
	   -----------------------------

	   Not allowed:
	   - ÆØÅ
	   - Spaces
	   - Double period (..)
	   - More than one at (@)
	   - Signs except the A-Z, 0-9 and !#$%&*+-/=?^_`{|}~.
	 */

	public static Boolean checkIfValidEmail( String email ) {
		String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; // source: <a href="http://www.regular-expressions.info/email.html" target="_blank" rel="nofollow">http://www.regular-expressions.info/email.html</a>
		Pattern MyPattern = Pattern.compile( emailRegex );
		Matcher MyMatcher = MyPattern.matcher( email );

		return MyMatcher.matches();
	}

	public static Map<String, List<ContactWrapper> > createMapOfContactWrapper( List<ContactWrapper> wrapperList ) {
		Map<String, List<ContactWrapper> > contactWrapperMap = new Map<String, List<ContactWrapper> >();
		for ( ContactWrapper cw : wrapperList ) {
			if ( contactWrapperMap.containsKey( cw.email.toLowerCase() ) ) {
				contactWrapperMap.get( cw.email.toLowerCase() ).add( cw );
			} else {
				contactWrapperMap.put( cw.email.toLowerCase(), new List<ContactWrapper> { cw } );
			}
		}

		return contactWrapperMap;
	}

	public static Map<String, Contact> createContactMapWithEmailAsKey( List<Contact> existingContacts ) {

		Map<String, Contact> contactMap = new Map<String, Contact>();

		for ( Contact con : existingContacts ) {
			if ( con.Email != null ) {
				contactMap.put( con.Email.toLowerCase(), con );
			} else if ( con.InvalidEmail__c != null ) {
				contactMap.put( con.InvalidEmail__c.toLowerCase(), con );
			}
		}

		return contactMap;
	}

	public static void createRemainingContacts( List<SharedFunctions_Helper.ContactWrapper> wrapperList, Map<String, Account> accountMap, Map<String, Contact> contactMap ) {

		List<Contact> newContacts = new List<Contact>();
		for ( SharedFunctions_Helper.ContactWrapper cw : wrapperList ) {

			if ( !contactMap.containsKey( cw.email.toLowerCase() ) ) {

				Id accountId = accountMap.containsKey( cw.companyNumber ) ? accountMap.get( cw.companyNumber ).Id : null;
				Contact con = new Contact( FirstName = cw.firstName, LastName = cw.lastName, MobilePhone = cw.phone, AccountId = accountId, Source__c = cw.source );

				// if cw.email is a valid email, add the email
				if ( SharedFunctions_Helper.checkIfValidEmail( cw.email ) ) {
					con.Email = cw.email;
				}
				// if invalid, add it only to the invalid email field (to be later fixed by an employee)
				else {
					con.InvalidEmail__c = cw.email;
				}

				contactMap.put( cw.email.toLowerCase(), con );
				newContacts.add( con );
			}
		}

		insert newContacts;
	}
}
