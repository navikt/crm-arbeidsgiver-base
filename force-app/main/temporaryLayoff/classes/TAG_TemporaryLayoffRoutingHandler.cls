global class TAG_TemporaryLayoffRoutingHandler extends MyTriggers {

	global override void onBeforeInsert() {
		Map<Integer, ApexSharingRuleWrapper> ruleByByLayoffId = RecordOwnerService.getQueuesAndNavUnits( getSobjectWrappers(), 'TemporaryLayoff__c' );
		Integer i = 0;
		for ( TemporaryLayoff__c layoff : (List<TemporaryLayoff__c>) records ) {
			ApexSharingRuleWrapper rule = ruleByByLayoffId.get( i );
			if ( rule == null ) continue;
			layoff.OwnerId = rule.queueId;
			layoff.Nav_Unit__c = rule.navUnitId;
			i++;
		}
	}

	private List<SobjectWrapper> getSobjectWrappers() {
		Map<Id, SobjectWrapper> accountInfoMap = getMunicipalityAndPostalCodeForAccounts();
		List<SobjectWrapper> wrappers = new List<SobjectWrapper>();
		Integer recordIndex = 0;
		for ( TemporaryLayoff__c layoff : (List<TemporaryLayoff__c>) records ) {
			SobjectWrapper accountInfo = accountInfoMap.get( layoff.Account__c );
			String municipality = null;
			String postalCode = null;
			if ( accountInfo != null ) {
				municipality = accountInfo.Municipality;
				postalCode = accountInfo.PostalCode;
			}
			wrappers.add( new SobjectWrapper( recordIndex, municipality, null, postalCode ) );
			recordIndex++;
		}

		return wrappers;
	}

	private Map<Id, SobjectWrapper> getMunicipalityAndPostalCodeForAccounts() {
		Set<Id> accountIds = new Set<Id>();
		for ( TemporaryLayoff__c layoff : (List<TemporaryLayoff__c>) records ) {
			accountIds.add( layoff.Account__c );
		}
		Map<Id, SobjectWrapper> wrapperByAccountId = new Map<Id, SobjectWrapper>();
		for ( Account acc : [SELECT INT_MunicipalityNumber__c, ShippingPostalCode FROM Account WHERE Id in:accountIds] ) {
			SobjectWrapper wrapper = new SobjectWrapper();
			wrapper.Municipality = acc.INT_MunicipalityNumber__c;
			wrapper.PostalCode = acc.ShippingPostalCode;
			wrapperByAccountId.put( acc.Id, wrapper );
		}

		return wrapperByAccountId;
	}
}