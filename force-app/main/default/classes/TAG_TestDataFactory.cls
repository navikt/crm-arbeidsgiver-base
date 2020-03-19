public without sharing class TAG_TestDataFactory {

	public static Id getOwnerForAccounts() {
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' OR Name = 'Systemadministrator' LIMIT 1];
		User testUser = [SELECT Id FROM User WHERE ProfileId = : p.Id AND IsActive = true LIMIT 1];
		User u = new user();
		System.RunAs( testUser )
		{
			// UserRole ur = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1];
			u.LastName = 'Test Code';
			u.Email = 'this_is_a_fake_email@test.com';
			String d = String.valueOf( DateTime.now().millisecond() ) + String.valueOf( DateTime.now().second() ) + String.valueOf( DateTime.now().minute() );
			u.Alias = 'Tcode';
			u.Username = d + 'testddsasd@test.com';
			// u.UserRoleId = ur.id;
			u.CommunityNickname = d + 'st12';
			u.LocaleSidKey = 'en_US';
			u.TimeZoneSidKey = 'GMT';
			u.ProfileID = p.Id;
			u.LanguageLocaleKey = 'en_US';
			u.EmailEncodingKey = 'UTF-8';
			insert u;
		}

		return u.Id;
	}

	public static List<Account> createAccounts( Integer amount ) {
		List<Account> accounts = new List<Account>();
		for ( Integer i = 0; i < amount; i++ ) {
			Account acc = new Account();
			acc.Name = 'test';

			accounts.add( acc );
		}

		insert accounts;

		return accounts;
	}

	public static User createStandardUser() {

		User user = new User();
		String d = String.valueOf( DateTime.now().millisecond() ) + String.valueOf( DateTime.now().second() ) + String.valueOf( DateTime.now().minute() );
		user.Username = d + 'test@nav.no';
		user.Email = d + 'test@nav.no';
		user.Alias = 'tsamp';
		user.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1].Id;
		user.isActive = true;
		user.FirstName = 'First';
		user.LastName = 'Last';
		user.TimeZoneSidKey = 'Europe/Paris';
		user.LocaleSidKey = 'no_NO';
		user.EmailEncodingKey = 'UTF-8';
		user.LanguageLocaleKey = 'no';
		user.CommunityNickname = 'testUser' + d;
		insert user;

		return user;
	}

	public static List<CustomOpportunity__c> getCustomOpportunities(Integer numberOfOpportunities, Boolean doInsert) {
		List<CustomOpportunity__c> customOpportunities = new List<CustomOpportunity__c>();

		for (Integer i = 0; i < numberOfOpportunities; i++) {
			customOpportunities.add(new CustomOpportunity__c(
					INT_MunicipalityNumber__c = '0101'
			));
		}

		if(doInsert) insert customOpportunities;
		return customOpportunities;
	}
}
