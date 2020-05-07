public with sharing class AccountMessagesWrapper {
	@AuraEnabled public Datetime eventDate {get; set;}
	@AuraEnabled public Integer counter {get; set;}
	@AuraEnabled public String field {get; set;}

	public AccountMessagesWrapper( Datetime eventDate, Integer counter, String field ) {
		this.eventDate = eventDate;
		this.counter = counter;
		this.field = field;
	}
}
