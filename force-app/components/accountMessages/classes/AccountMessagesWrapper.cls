public with sharing class AccountMessagesWrapper {
	@AuraEnabled public String accountId {get; set;}
	@AuraEnabled public Integer counter {get; set;}
	@AuraEnabled public String field {get; set;}

	public AccountMessagesWrapper( String accountId, Integer counter, String field ) {
		this.accountId = accountId;
		this.counter = counter;
		this.field = field;
	}
}
