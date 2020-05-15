global class ArenaActivityRoutingHandler extends MyTriggers {

	global override void onBeforeInsert() {

		Map<Integer, ApexSharingRuleWrapper> ruleByByarenaActivityId = RecordOwnerService.getQueuesAndNavUnits( getSobjectWrappers(), 'ArenaActivity__c' );
		Integer i = 0;
		for ( ArenaActivity__c arenaActivity : ( List<ArenaActivity__c> ) records ) {

			ApexSharingRuleWrapper rule = ruleByByarenaActivityId.get( i );

			if ( rule == null ) { continue; }

			arenaActivity.NAV_Kontor__c = rule.navUnitId;
			i++;
		}
	}

	private List<SobjectWrapper> getSobjectWrappers() {

		List<SobjectWrapper> wrappers = new List<SobjectWrapper>();
		Integer recordIndex = 0;

		for ( ArenaActivity__c arenaActivity : ( List<ArenaActivity__c> ) records ) {
			wrappers.add( new SobjectWrapper( recordIndex, arenaActivity.Account__r.INT_MunicipalityNumber__c ) );
			recordIndex++;
		}

		return wrappers;
	}
}