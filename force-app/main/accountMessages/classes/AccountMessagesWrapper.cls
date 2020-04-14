public with sharing class AccountMessagesWrapper {
	@AuraEnabled public Boolean isBankrupt {get; set;}
	@AuraEnabled public Boolean isInLiquidation {get; set;}

	public AccountMessagesWrapper( Boolean isBankrupt, Boolean isInLiquidation ) {
		this.isBankrupt = isBankrupt;
		this.isInLiquidation = isInLiquidation;
	}
}
