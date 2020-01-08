public without sharing class TAG_TestDataFactory {

	public static final Id OWNER_ID = getOwnerForAccounts();

	public static User createUserContactAndAccount() {
		Account acc = new Account( Name = 'account',  OwnerId = OWNER_ID, INT_Ident__c = '123456' );
		insert acc;
		Contact con = new contact( AccountId = acc.Id, lastName = 'Contact' );
		insert con;
		User user = new User();
		String d = String.valueOf( DateTime.now().millisecond() ) + String.valueOf( DateTime.now().second() ) + String.valueOf( DateTime.now().minute() );
		user.Username = d + 'test@nav.no';
		user.Email = d + 'test@nav.no';
		user.Alias = 'tsamp';
		user.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community User Custom' LIMIT 1].Id;
		user.isActive = true;
		user.ContactId = con.Id;
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

	public static Id getOwnerForAccounts() {
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' OR Name = 'Systemadministrator' LIMIT 1];
		User testUser = [SELECT Id FROM User WHERE ProfileId = : p.Id AND IsActive = true LIMIT 1];
		User u = new user();
		System.RunAs( testUser )
		{
			UserRole ur = [SELECT Id FROM UserRole WHERE Name = 'Admin' LIMIT 1];
			u.LastName = 'Test Code';
			u.Email = 'this_is_a_fake_email@test.com';
			String d = String.valueOf( DateTime.now().millisecond() ) + String.valueOf( DateTime.now().second() ) + String.valueOf( DateTime.now().minute() );
			u.Alias = 'Tcode';
			u.Username = d + 'testddsasd@test.com';
			u.UserRoleId = ur.id;
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
			acc.INT_Ident__c = 'ident' + i;
			accounts.add( acc );
		}

		insert accounts;

		return accounts;
	}
}
