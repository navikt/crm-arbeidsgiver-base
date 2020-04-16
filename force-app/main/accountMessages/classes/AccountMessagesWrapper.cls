public with sharing class AccountMessagesWrapper {
	@AuraEnabled public Boolean isBankrupt {get; set;}
	@AuraEnabled public Boolean isInLiquidation {get; set;}
	@AuraEnabled public Boolean isInForcedSettlementOrResolution {get; set;}
	@AuraEnabled public Datetime eventDate {get; set;}
	@AuraEnabled public Integer counter {get; set;}

	public AccountMessagesWrapper( Boolean isBankrupt, Boolean isInLiquidation, Boolean isInForcedSettlementOrResolution, Datetime eventDate, Integer counter ) {
		this.isBankrupt = isBankrupt;
		this.isInLiquidation = isInLiquidation;
		this.isInForcedSettlementOrResolution = isInForcedSettlementOrResolution;
		this.eventDate = eventDate;
		this.counter = counter;
	}
}
