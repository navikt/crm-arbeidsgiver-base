public without sharing class TAG_TestDataFactory {

	public static User createUserContactAndAccount() {
		Account acc = new Account( Name = 'account' );
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
}
